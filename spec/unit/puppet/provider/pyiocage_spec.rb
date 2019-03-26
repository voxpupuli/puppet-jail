require 'spec_helper'
require 'puppet/provider/jail/pyiocage'

provider_class = Puppet::Type.type(:jail).provider(:pyiocage)

cmd = '/usr/local/bin/iocage'
exec_props = { override_locale: false, failonfail: true, combine: true }

describe provider_class do
  context '#jail_list' do
    before do
      fixture_jails  = File.read('spec/fixtures/pyiocage_list-l')
      fixture_tmpl   = File.read('spec/fixtures/pyiocage_list-t')
      # provider_class.stub(:iocage).with(['list']) { fixture }
      allow(provider_class).to receive(:execute).with("#{cmd} list -Htl", exec_props) { fixture_tmpl }
      allow(provider_class).to receive(:execute).with("#{cmd} list -Hl", exec_props) { fixture_jails }
    end

    it 'parses jail listing' do
      wanted = [{ jid: nil,
                  uuid: 'f11-ats6',
                  boot: 'off',
                  state: 'down',
                  type: 'template',
                  release: '11.0-RELEASE-p10',
                  ip4_addr: 'vtnet0|172.16.0.6/12',
                  ip6_addr: nil,
                  template: nil },
                { jid: nil,
                  uuid: 'f11-php71',
                  boot: 'off',
                  state: 'down',
                  type: 'template',
                  release: '11.0-RELEASE-p10',
                  ip4_addr: 'vtnet0|172.16.0.4/12',
                  ip6_addr: nil,
                  template: nil },
                { jid: nil,
                  uuid: 'f11-puppet4',
                  boot: 'off',
                  state: 'down',
                  type: 'template',
                  release: '11.0-RELEASE-p10',
                  ip4_addr: nil,
                  ip6_addr: nil,
                  template: nil },
                { jid: '9',
                  uuid: 'blag',
                  boot: 'off',
                  state: 'up',
                  type: 'jail',
                  release: '11.0-RELEASE-p10',
                  ip4_addr: 'vtnet0|172.16.0.5/12',
                  ip6_addr: nil,
                  template: 'f11-php71' },
                { jid: nil,
                  uuid: 'cdn',
                  boot: 'off',
                  state: 'down',
                  type: 'jail',
                  release: '11.0-RELEASE-p10',
                  ip4_addr: 'vtnet0|172.16.0.7/12',
                  ip6_addr: 'vtnet0|2a03:b0c0:3:d0::4c97:6007',
                  template: 'f11-ats6' },
                { jid: nil,
                  uuid: 'cdn01',
                  boot: 'off',
                  state: 'down',
                  type: 'jail',
                  release: '11.0-RELEASE-p10',
                  ip4_addr: 'vtnet0|172.16.0.8/12',
                  ip6_addr: 'vtnet0|2a03:b0c0:3:d0::4c97:6008',
                  template: 'f11-ats6' }]

      expect(provider_class.jail_list).to eq(wanted)
    end
  end

  context '#get_jail_properties' do
    before do
      list_fixture = File.read('spec/fixtures/pyiocage_list')
      allow(provider_class).to receive(cmd).with(['list']) { list_fixture }

      get_fixture = File.read('spec/fixtures/pyiocage_jail_get_all')
      allow(provider_class).to receive('execute').with("#{cmd} get all f9e67f5a-4bbe-11e6-a9b4-eca86bff7d21", exec_props) { get_fixture }
    end

    it 'parses jail properties' do
      results = provider_class.get_jail_properties('f9e67f5a-4bbe-11e6-a9b4-eca86bff7d21').to_h

      expect(results).to(include(
                           'openfiles' => 'off',
                           'memoryuse' => '8G:log'
      ))
    end
  end

  context '#empty jail_list' do
    before do
      provider_class.stub(:iocage).with('list', '-Htl') { '' }
      provider_class.stub(:iocage).with('list', '-Hl') { '' }
    end
    it 'parses empty output an empty hash' do
      expect(provider_class.jail_list).to eq([])
    end
  end

  context '#fstab' do
    before do
      provider_class.stub(:iocage).with('fstab', '-Hl', 'cyhr') do
        <<-EOT
0       /usr/local/etc/puppet /iocage/jails/cyhr/root/usr/local/etc/puppet nullfs ro 0 0
1       /data/www/cyhr /iocage/jails/cyhr/root/usr/local/www nullfs ro 0 0
      EOT
      end
      provider_class.stub(:iocage).with('list', '-Htl') { '' }
      provider_class.stub(:iocage).with('list', '-Hl') do
        <<-EOT
19      cyhr    off     up      jail    11.0-RELEASE-p10        vtnet0|172.16.1.3/12    -       f11-php71
      EOT
      end

      # we don't care about properties
      provider_class.stub(:iocage).with('get', 'all', 'default') { '' }
      provider_class.stub(:iocage).with('get', 'all', 'cyhr') { '' }
    end
    it 'parses fstab entries' do
      expect(provider_class.instances[0].fstab).to eq(['/usr/local/etc/puppet', '/data/www/cyhr /iocage/jails/cyhr/root/usr/local/www nullfs ro 0 0'])
    end
  end
end
