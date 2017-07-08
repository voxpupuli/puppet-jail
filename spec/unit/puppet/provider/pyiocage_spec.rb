require 'spec_helper'
require 'puppet/provider/jail/pyiocage'

provider_class = Puppet::Type.type(:jail).provider(:pyiocage)

describe provider_class do
  context '#jail_list' do
    it 'parses jail listing' do
      fixture_jails  = File.read('spec/fixtures/pyiocage_list-l')
      fixture_tmpl   = File.read('spec/fixtures/pyiocage_list-t')
      # provider_class.stub(:iocage).with(['list']) { fixture }
      allow(provider_class).to receive(:execute).with('/usr/local/bin/iocage list -Htl', override_locale: false) { fixture_tmpl }
      allow(provider_class).to receive(:execute).with('/usr/local/bin/iocage list -Hl', override_locale: false) { fixture_jails }

      wanted = [{ jid: '-',
                  uuid: 'f11-ats6',
                  boot: 'off',
                  state: 'down',
                  type: 'template',
                  release: '11.0-RELEASE-p10',
                  ip4_addr: 'vtnet0|172.16.0.6/12',
                  ip6_addr: '-',
                  template: '-' },
                { jid: '-',
                  uuid: 'f11-php71',
                  boot: 'off',
                  state: 'down',
                  type: 'template',
                  release: '11.0-RELEASE-p10',
                  ip4_addr: 'vtnet0|172.16.0.4/12',
                  ip6_addr: '-',
                  template: '-' },
                { jid: '-',
                  uuid: 'f11-puppet4',
                  boot: 'off',
                  state: 'down',
                  type: 'template',
                  release: '11.0-RELEASE-p10',
                  ip4_addr: '-',
                  ip6_addr: '-',
                  template: '-' },
                { jid: '9',
                  uuid: 'blag',
                  boot: 'off',
                  state: 'up',
                  type: 'jail',
                  release: '11.0-RELEASE-p10',
                  ip4_addr: 'vtnet0|172.16.0.5/12',
                  ip6_addr: '-',
                  template: 'f11-php71' },
                { jid: '-',
                  uuid: 'cdn',
                  boot: 'off',
                  state: 'down',
                  type: 'jail',
                  release: '11.0-RELEASE-p10',
                  ip4_addr: 'vtnet0|172.16.0.7/12',
                  ip6_addr: 'vtnet0|2a03:b0c0:3:d0::4c97:6007',
                  template: 'f11-ats6' },
                { jid: '-',
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
    it 'parses jail properties' do
      list_fixture = File.read('spec/fixtures/pyiocage_list')
      allow(provider_class).to receive('/usr/local/bin/iocage').with(['list']) { list_fixture }

      get_fixture = File.read('spec/fixtures/pyiocage_jail_get_all')
      allow(provider_class).to receive('execute').with('/usr/local/bin/iocage get all f9e67f5a-4bbe-11e6-a9b4-eca86bff7d21', override_locale: false) { get_fixture }

      results = provider_class.get_jail_properties('f9e67f5a-4bbe-11e6-a9b4-eca86bff7d21').to_h

      expect(results).to(include(
                           'boot'     => 'on',
                           'ip4_addr' => 'ethernet0|10.0.0.10',
                           'ip6_addr' => 'ethernet0|2001:470:deed::100'
      ))
    end
  end
end
