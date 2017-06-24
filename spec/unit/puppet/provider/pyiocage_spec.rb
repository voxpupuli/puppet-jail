require 'spec_helper'
require 'puppet/provider/jail/pyiocage'

provider_class = Puppet::Type.type(:jail).provider(:pyiocage)

describe provider_class do
  context '#jail_list' do
    it 'parses jail listing' do
      fixture_fields = File.read('spec/fixtures/pyiocage_list-f')
      fixture_jails  = File.read('spec/fixtures/pyiocage_list-l')
      fixture_tmpl   = File.read('spec/fixtures/pyiocage_list-t')
      # provider_class.stub(:iocage).with(['list']) { fixture }
      allow(provider_class).to receive(:execute).with('/usr/local/bin/iocage list -lt', override_locale: false) { fixture_fields }
      allow(provider_class).to receive(:execute).with('/usr/local/bin/iocage list -Htl', override_locale: false) { fixture_tmpl }
      allow(provider_class).to receive(:execute).with('/usr/local/bin/iocage list -Hl', override_locale: false) { fixture_jails }

      wanted = [{ jid: '-',
                  uuid: 'f946372e-1830-4eff-8448-b12e8f7c4264',
                  boot: 'off',
                  state: 'down',
                  tag: 'f11-ats6',
                  type: 'template',
                  release: '11.0-RELEASE-p10',
                  ip4: 'vtnet0|172.16.0.6/12',
                  ip6: '-',
                  template: '-' },
                { jid: '-',
                  uuid: 'e27b37fe-1658-4150-b853-883153a1e33f',
                  boot: 'off',
                  state: 'down',
                  tag: 'f11-php71',
                  type: 'template',
                  release: '11.0-RELEASE-p10',
                  ip4: 'vtnet0|172.16.0.4/12',
                  ip6: '-',
                  template: '-' },
                { jid: '-',
                  uuid: '6cfbc2fb-2234-4bf8-bac3-c6c3c7bdbabf',
                  boot: 'off',
                  state: 'down',
                  tag: 'f11-puppet4',
                  type: 'template',
                  release: '11.0-RELEASE-p10',
                  ip4: '-',
                  ip6: '-',
                  template: '-' },
                { jid: '9',
                  uuid: 'd439dfc9-2891-40c1-8d04-95024d9fa7bb',
                  boot: 'off',
                  state: 'up',
                  tag: 'blag',
                  type: 'jail',
                  release: '11.0-RELEASE-p10',
                  ip4: 'vtnet0|172.16.0.5/12',
                  ip6: '-',
                  template: 'f11-php71' },
                { jid: '-',
                  uuid: 'f0c1c16a-ef74-4412-8322-00b77eef124e',
                  boot: 'off',
                  state: 'down',
                  tag: 'cdn',
                  type: 'jail',
                  release: '11.0-RELEASE-p10',
                  ip4: 'vtnet0|172.16.0.7/12',
                  ip6: 'vtnet0|2a03:b0c0:3:d0::4c97:6007',
                  template: 'f11-ats6' },
                { jid: '-',
                  uuid: 'aaecf4d2-56c8-4ce3-8cab-0851b4551c38',
                  boot: 'off',
                  state: 'down',
                  tag: 'cdn01',
                  type: 'jail',
                  release: '11.0-RELEASE-p10',
                  ip4: 'vtnet0|172.16.0.8/12',
                  ip6: 'vtnet0|2a03:b0c0:3:d0::4c97:6008',
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

      results = provider_class.get_jail_properties('f9e67f5a-4bbe-11e6-a9b4-eca86bff7d21')

      expect(results).to(include(
                           'tag'              => 'media2',
                           'boot'             => 'on',
                           'jail_zfs'         => 'on',
                           'jail_zfs_dataset' => 'media_in',
                           'ip4_addr'         => 'ethernet0|10.0.0.10',
                           'ip6_addr'         => 'ethernet0|2001:470:deed::100'
      ))
    end
  end
end
