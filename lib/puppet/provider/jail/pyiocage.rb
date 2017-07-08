require 'tempfile'

Puppet::Type.type(:jail).provide(:pyiocage) do
  desc 'Manage jails using iocage(8)'
  confine    kernel: :freebsd
  defaultfor kernel: :freebsd

  # this is used for further confinement
  commands pyiocage: '/usr/local/bin/iocage'

  def self.iocage(*args)
    cmd = ['/usr/local/bin/iocage', args].flatten.join(' ')
    execute(cmd, override_locale: false)
  end

  def iocage(*args)
    self.class.iocage(args)
  end

  mk_resource_methods


  def self.jail_list
    fields = %w(jid uuid boot state type release ip4_addr ip6_addr template).freeze
    output  = iocage('list', '-Htl').split("\n")
    output += iocage('list', '-Hl').split("\n")

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
    default_properties = get_jail_properties('default')

    jail_list.map do |j|
      jail_properties = {
        provider: :pyiocage,
        ensure: j[:ensure],
        name: j[:uuid],
        state: j[:state],
        boot: j[:boot],
        type: j[:type],
        release: j[:release],
        ip4_addr: j[:ip4_addr],
        ip6_addr: j[:ip6_addr],
        template: j[:template]
      }

      jail_properties[:jid] = j[:jid] unless j[:jid] == '-'

      all_properties = get_jail_properties(j[:uuid])
      our_props = (all_properties - default_properties).to_h
      jail_properties[:properties] = our_props.empty? ? nil : our_props

      debug jail_properties

      new(jail_properties)
    end
  end

  def initialize(value = {})
    super(value)
    @property_flush = {}
  end

  # returns a frozen Set.
  # that's easier to work with and more performant.
  def self.get_jail_properties(jailname)
    data = {}
    output = iocage('get', 'all', jailname)
    output.lines.each do |l|
      key, value = l.split(':', 2)
      data[key] = value.chomp
    end
    data.reject! { |k, v| k.nil? || v.nil? }

    debug data

    Set.new(data).freeze
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def running?
    @property_hash[:state] == :up
  end

  def create
    @property_flush[:ensure] = :present
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

  def read_only(_value)
    raise PuppetError, 'This property is read-only!'
  end

  alias_method :jid=, :read_only

  def boot=(value)
    @property_flush[:boot] = value
  end

  def state=(value)
    @property_flush[:state] = value
  end

  def type=(value)
    @property_flush[:type] = value
  end

  def release=(value)
    @property_flush[:release] = value
  end

  def ip4_addr=(value)
    @property_flush[:ip4_addr] = value
  end

  def ip6_addr=(value)
    @property_flush[:ip6_addr] = value
  end

  def template=(value)
    @property_flush[:template] = value
  end

  def pkglist=(value)
    @property_flush[:pkglist] = value
  end

  def wrap_destroy
    iocage(['destroy', '--force', resource[:name]])
  end

  # returns Optional[Tempfile] to the pkglist's contents
  # users of this function should take care that it's deleted!
  def create_pkglist(pkglist)
    return nil if pkglist.nil? || pkglist.empty?
    pkgfile = Tempfile.new('puppet-iocage.pkglist')
    pkgfile.write({ pkgs: pkglist }.to_json)
    pkgfile.close
    pkgfile
  end

  def wrap_create(options, props)
    iocage('create', options, "--name #{resource[:name]}", props)
  end

  def rebuild(options, props)
    wrap_destroy
    wrap_create(options, props)
  end

  def flush
    options = []
    props = []
    if @property_flush
      Puppet.debug "JailPyIocage(#flush): #{@property_flush}"

      # this will need cleanup after use!
      pkgfile = create_pkglist(resource[:pkglist]) if @property_flush[:pkglist]
      (options << '--pkglist' << pkgfile.path) if pkgfile

      (options << '--release' << resource[:release]) if @property_flush[:release]
      (options << '--template' << resource[:template]) if @property_flush[:template]

      props << 'template=yes' if @property_flush[:type] == :template
      props << "ip4_addr=#{resource[:ip4_addr]}" if @property_flush[:ip4_addr]
      props << "ip6_addr=#{resource[:ip6_addr]}" if @property_flush[:ip6_addr]

      props << resource[:properties].each { |k, v| [k, v].join('=') } if @property_flush[:properties]

      case resource[:ensure]
      when :absent
        wrap_destroy
      when :present
        iocage('create', options, "--name #{resource[:name]}", props)
      else
        # if we got here, one or more options on an existing jail changed
        # all options are destructive, which means we need to rebuild the jail
        # XXX: how do we back-fill the other parameters & properties?
        rebuild(options, props) if !options.empty? && resource[:allow_rebuild]
        rebuild(options, props) if @property_flush[:template] && resource[:allow_rebuild]
        # other changes just need a restart, and are handled below
      end

      pkgfile.delete if pkgfile

      if resource[:state] == :up && resource[:ensure] == :present
        iocage(['start', resource[:name]])
        if resource[:user_data]
          tmpfile = Tempfile.new('puppet-iocage')
          tmpfile.write(resource[:user_data])
          tmpfile.close
          iocage('exec', resource[:name], '/bin/sh', stdinfile: tmpfile.path)
          tmpfile.delete
        end
      end

      need_restart = false
      [:ip4_addr, :ip6_addr].each do |p|
        if @property_flush[p]
          need_restart = true
          set_property(p.to_s, @property_flush[p])
        end
      end

      if @property_flush[:properties]
        # none of these need a restart
        @property_flush[:properties].each { |p, v| set_property(p.to_s, v) }
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

      restart if need_restart && @resource[:allow_restart] == :true
    end
    @property_hash = resource.to_hash
  end
end
