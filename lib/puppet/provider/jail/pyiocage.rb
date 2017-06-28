require 'tempfile'

Puppet::Type.type(:jail).provide(:pyiocage) do
  desc 'Manage jails using iocage(8)'
  confine    kernel: :freebsd
  defaultfor kernel: :freebsd

  # this is used for further confinement
  commands iocage: '/usr/local/bin/iocage'

  def self.pyiocage(*args)
    cmd = ['/usr/local/bin/iocage', args].flatten.join(' ')
    execute(cmd, override_locale: false)
  end

  mk_resource_methods

  def self.jail_list
    # first, get the fields. We take them from -t, hoping this is less stuff
    fields = pyiocage('list', '-lt').split("\n")[1].downcase.split(%r{\s+|\s+}).reject { |f| f == '|' }
    output  = pyiocage('list', '-Htl').split("\n")
    output += pyiocage('list', '-Hl').split("\n")

    data = []

    output.each do |j|
      jail_data = {}
      values = j.split(%r{\s+})
      values.each_index do |i|
        jail_data[fields[i].to_sym] = values[i]
      end
      data << jail_data
    end

    data
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        resource.provider = prov
      end
    end
  end

  def self.instances
    jail_list.map do |j|
      jensure = j[:type] == 'template' ? :template : :present
      jail_properties = {
        provider: :pyiocage,
        ensure: jensure,
        name: j[:tag],
        state: j[:state],
        boot: j[:boot]
      }

      jail_properties[:jid] = j[:jid] if j[:jid] != '-'

      all_properties = get_jail_properties(j[:tag])

      extra_properties = [
        :ip4_addr,
        :ip6_addr,
        :hostname,
        :jail_zfs,
        :jail_zfs_dataset
      ]

      extra_properties.each do |p|
        jail_properties[p] = all_properties[p.to_s]
      end

      debug jail_properties

      new(jail_properties)
    end
  end

  def initialize(value = {})
    super(value)
    @property_flush = {}
  end

  def self.get_jail_properties(jailname)
    data = {}
    output = pyiocage('get', 'all', jailname)
    output.lines.each do |l|
      key, value = l.split(':', 2)
      data[key] = value.chomp
    end
    data.reject! { |k, v| k.nil? || v.nil? }

    debug data

    data
  end

  def exists?
    @property_hash[:ensure] == :present || @property_hash[:ensure] == :template
  end

  def running?
    @property_hash[:state] == :up
  end

  def create
    @property_flush[:ensure] = resource[:ensure]
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def restart
    iocage(['stop', resource[:name]])
    iocage(['start', resource[:name]])
  end

  def set_property(property, value)
    iocage(['set', "#{property}=#{value}", resource[:name]])
  end

  def state=(value)
    @property_flush[:state] = value
  end

  def boot=(value)
    @property_flush[:boot] = value
  end

  def ip4_addr=(value)
    @property_flush[:ip4_addr] = value
  end

  def ip6_addr=(value)
    @property_flush[:ip6_addr] = value
  end

  def hostname=(value)
    @property_flush[:hostname] = value
  end

  def jail_zfs=(value)
    @property_flush[:jail_zfs] = value
  end

  def jail_zfs_dataset=(value)
    @property_flush[:jail_zfs_dataset] = value
  end

  def pkglist=(value)
    @property_flush[:pkglist] = value
  end

  def wrap_create(jensure = resource[:ensure])
    frel = Facter.value(:os)['release']['full'].gsub(%r{-p\d+$}, '')

    template = resource[:template] ? "--template=#{resource[:template]}" : nil
    release = resource[:release] ? "--release=#{resource[:release]}" : "--release=#{frel}"
    from = template.nil? ? release : template

    create_template = jensure == :template ? 'template=yes' : nil

    unless resource[:pkglist].empty?
      pkgfile = Tempfile.new('puppet-iocage-pkglist.json')
      pkgfile.write({ pkgs: resource[:pkglist] }.to_json)
      pkgfile.close
      pkglist = "--pkglist=#{pkgfile.path}"
    end
    iocage(['create', '--force', from, pkglist, create_template, "tag=#{resource[:name]}"].compact)
  end

  def wrap_destroy
    iocage(['stop', resource[:name]])
    iocage(['destroy', '--force', resource[:name]])
  end

  def update
    wrap_destroy
    wrap_create
  end

  def flush
    if @property_flush
      Puppet.debug "JailPyIocage(#flush): #{@property_flush}"

      pre_start_properties = [
        :boot,
        :ip4_addr,
        :ip6_addr,
        :hostname,
        :jail_zfs,
        :jail_zfs_dataset
      ]

      case resource[:ensure]
      when :absent
        wrap_destroy
      when :present
        wrap_create(:present)
      when :template
        wrap_create(:template)
      end

      if resource[:state] == :up && resource[:ensure] == :present
        pre_start_properties.each do |p|
          set_property(p.to_s, resource[p]) if resource[p]
        end
        iocage(['start', resource[:name]])
        if resource[:user_data]
          tmpfile = Tempfile.new('puppet-iocage')
          tmpfile.write(resource[:user_data])
          tmpfile.close
          execute("/usr/local/bin/iocage exec #{resource[:name]} /bin/sh",
                  stdinfile: tmpfile.path,
                  override_locale: false)
          tmpfile.delete
        end
      end

      need_restart = false
      pre_start_properties.each do |p|
        if @property_flush[p]
          need_restart = true
          set_property(p.to_s, @property_flush[p])
        end
      end

      if @property_flush[:state]
        case resource[:state]
        when :up
          need_restart = false
          iocage(['start', resource[:name]])
        when :down
          need_restart = false
          iocage(['stop', resource[:name]])
        end
      end

      restart if need_restart
    end
    @property_hash = resource.to_hash
  end
end
