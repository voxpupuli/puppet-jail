# frozen_string_literal: true

require 'tempfile'

Puppet::Type.type(:jail).provide(:pyiocage) do
  desc 'Manage jails using iocage(8)'
  confine    kernel: :freebsd
  defaultfor kernel: :freebsd

  # this is used for further confinement
  commands pyiocage: '/usr/local/bin/iocage'

  def self.iocage(*args)
    cmd = ['/usr/local/bin/iocage', args].flatten.join(' ')
    execute(cmd, override_locale: false, failonfail: true, combine: true)
  end

  def iocage(*args)
    self.class.iocage(args)
  end

  mk_resource_methods

  Fields = [ # rubocop:disable Lint/ConstantDefinitionInBlock,Naming/ConstantName
    :jid,
    :uuid,
    :boot,
    :state,
    :type,
    :release,
    :ip4_addr,
    :ip6_addr,
    :template,
    :cloned_release # cheat to filter out cloned_release from `properties`
  ].freeze

  def self.jail_list
    output  = iocage('list', '-Htl').split("\n")
    output += iocage('list', '-Hl').split("\n")

    data = []

    output.each do |j|
      jail_data = {}
      values = j.split(%r{\s+})
      values.each_index do |i|
        jail_data[Fields[i]] = values[i] == '-' ? nil : values[i]
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
        ensure: :present,
        jid: j[:jid],
        name: j[:uuid],
        state: j[:state],
        boot: j[:boot],
        type: j[:type],
        release: j[:release],
        ip4_addr: j[:ip4_addr],
        ip6_addr: j[:ip6_addr],
        template: j[:template]
      }

      all_properties = get_jail_properties(j[:uuid])
      our_props = (all_properties - default_properties).to_h
      jail_properties[:properties] = our_props.empty? ? nil : our_props

      if j[:type] == 'jail'
        fstabs = iocage('fstab', '-Hl', j[:uuid]).split("\n")
        jail_properties[:fstab] = [] unless fstabs.empty?
        fstabs.each do |f|
          _, src, dst, fs, opts, freq, passno = f.split(%r{\s+})
          jail_properties[:fstab] << if dst =~ %r{#{src}$} && fs == 'nullfs' && opts == 'ro'
                                       src
                                     else
                                       "#{src} #{dst} #{fs} #{opts} #{freq} #{passno}"
                                     end
        end
      end

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

      next if key == 'last_started'
      next if key == 'jail_zfs_dataset'
      next if key == 'devfs_ruleset'

      data[key] = value.chomp
    end
    data.reject! { |k, v| k.nil? || Fields.include?(k.to_sym) || v.nil? || v == jailname }

    debug 'Data for get_jail_properties'
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
    Puppet.debug "JailPyIocage(#set_property): #{property}=#{value}"
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

  def properties=(value)
    @property_flush[:properties] = value
  end

  def fstab=(value)
    desired_fstab = Array(value)
    current_fstab = Array(fstab)
    (current_fstab - desired_fstab).each do |f|
      iocage('fstab', '--remove', resource[:name], f)
    end
    (desired_fstab - current_fstab).each do |f|
      iocage('fstab', '--add', resource[:name], f)
    end
    @property_flush[:fstab] = value
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

  def rebuild(options, props)
    iocage(['destroy', '--force', resource[:name]])
    iocage('create', options, "--name #{resource[:name]}", props)
  end

  def flush
    options = []
    props = []

    if @property_flush
      Puppet.debug "JailPyIocage(#flush): #{@property_flush}"
      Puppet.debug "JailPyIocage(#hash): #{@property_hash}"

      # this will need cleanup after use!
      pkgfile = create_pkglist(resource[:pkglist]) if resource[:pkglist]
      (options << '--pkglist' << pkgfile.path) if pkgfile

      (options << '--release' << resource[:release]) if resource[:release]
      (options << '--template' << resource[:template]) if resource[:template]

      props << 'template=yes' if resource[:type] == :template
      props << "ip4_addr='#{resource[:ip4_addr]}'" if resource[:ip4_addr]
      props << "ip6_addr='#{resource[:ip6_addr]}'" if resource[:ip6_addr]

      resource[:properties]&.each { |k, v| props << [k, v].join('=') }

      case @property_flush[:ensure]
      when :absent
        iocage(['destroy', '--force', resource[:name]]) unless @property_hash[:ensure] != :present
      when :present
        # unless @property_hash[:ensure] == :present
        iocage('create', options, "--name #{resource[:name]}", props)
        # else
        #   # if we got here, one or more options on an existing jail changed
        #   # all options are destructive, which means we need to rebuild the jail
        #   # XXX: how do we back-fill the other parameters & properties?
        #   rebuild(options, props) if !options.empty? && resource[:allow_rebuild]
        #   rebuild(options, props) if @property_flush[:template] && resource[:allow_rebuild]
        #   # other changes just need a restart, and are handled below
        # end
      end

      pkgfile&.delete

      # When a jail has just been created, the @property_flush will only
      # contain :ensure=>:present.  As such, when we have that in the property
      # flush, and we desire the state to be up, then we must start it since we
      # have just created it.
      if resource[:state] == :up && @property_flush[:ensure] == :present
        iocage(['start', resource[:name]])

        # Now that the jail has been started after initial creation, iwe need
        # to handle the user_data for the new jail.
        if resource[:user_data]
          tmpfile = Tempfile.new('puppet-iocage')
          tmpfile.write(resource[:user_data])
          tmpfile.close
          execute("/usr/local/bin/iocage exec #{resource[:name]} /bin/sh < #{tmpfile.path}")
          tmpfile.delete
        end
      end

      need_restart = false
      %i[ip4_addr ip6_addr].each do |family_addr|
        if @property_flush.keys.include? family_addr
          need_restart = true
          set_property(family_addr.to_s, "\"#{@property_flush[family_addr]}\"")
        end
      end

      if @property_flush[:properties]
        # none of these need a restart
        keys_to_set = @property_flush[:properties].select do |p, _v|
          @property_hash.keys.include? p
        end
        keys_to_set.each do |x|
          set_property(x.to_s, @property_flush[x]) if @property_hash[x] != @property_flush[x]
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

      set_property('boot', @property_flush[:boot].to_s) if @property_flush[:boot]

      restart if need_restart && @resource[:allow_restart] == :true
    end

    @property_hash = resource.to_hash
  end
end
