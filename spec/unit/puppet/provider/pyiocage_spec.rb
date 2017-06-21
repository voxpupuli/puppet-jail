require 'spec_helper'
require 'puppet/provider/jail/pyiocage'

provider_class = Puppet::Type.type(:jail).provider(:pyiocage)

describe provider_class do
  context '#jail_list' do
    it 'parses jail listing' do
      fixture = File.read('spec/fixtures/pyiocage_list')
      # provider_class.stub(:iocage).with(['list']) { fixture }
      allow(provider_class).to receive(:execute).with('/usr/local/bin/iocage list -l', override_locale: false) { fixture }

      wanted = [{ jid: '-',
                  uuid: '018e776d-4315-11e5-94bc-0025905cf7cc',
                  boot: 'off',
                  state: 'down',
                  tag: 'auth4',
                  type: 'jail',
                  ip4: 'igb0|10.101.11.120',
                  release: '11.0-RELEASE-p1',
                  template: '-' },
                { jid: '6',
                  uuid: '8742644d-a6ee-11e6-8931-0025905cf7cc',
                  boot: 'on',
                  state: 'up',
                  tag: 'auth6',
                  type: 'jail',
                  ip4: 'igb0|10.101.11.125',
                  release: '11.0-RELEASE-p1',
                  template: '-' },
                { jid: '4',
                  uuid: '5f6cad50-137d-11e7-a1a5-0025905cf7cc',
                  boot: 'on',
                  state: 'up',
                  tag: 'ci2',
                  type: 'jail',
                  ip4: 'igb0|10.101.11.127',
                  release: '11.0-RELEASE-p1',
                  template: '-' },
                { jid: '2',
                  uuid: '1cf80120-737b-11e5-a2db-0025905cf7cc',
                  boot: 'on',
                  state: 'up',
                  tag: 'db1',
                  type: 'jail',
                  ip4: 'igb0|10.101.11.121',
                  release: '11.0-RELEASE-p1',
                  template: '-' },
                { jid: '-',
                  uuid: '9019f320-21e7-11e5-ac4f-0025905cf7cd',
                  boot: 'off',
                  state: 'down',
                  tag: 'fbsd10_1',
                  type: 'jail',
                  ip4: '-',
                  release: '10.1-RELEASE-p14',
                  template: '-' },
                { jid: '1',
                  uuid: '19e2885e-448e-11e5-94bc-0025905cf7cc',
                  boot: 'on',
                  state: 'up',
                  tag: 'git2',
                  type: 'jail',
                  ip4: 'igb0|10.101.11.122',
                  release: '11.0-RELEASE-p1',
                  template: '-' },
                { jid: '3',
                  uuid: '520a74bf-2517-11e7-a1a5-0025905cf7cc',
                  boot: 'on',
                  state: 'up',
                  tag: 'metrics4',
                  type: 'jail',
                  ip4: 'igb0|10.101.11.128',
                  release: '11.0-RELEASE-p1',
                  template: '-' },
                { jid: '7',
                  uuid: 'a5e58b72-23e9-11e7-a1a5-0025905cf7cc',
                  boot: 'on',
                  state: 'up',
                  tag: 'mon6',
                  type: 'jail',
                  ip4: 'igb0|10.101.11.129',
                  release: '11.0-RELEASE-p1',
                  template: '-' },
                { jid: '5',
                  uuid: '64a7af2c-4909-11e5-9073-0025905cf7cc',
                  boot: 'on',
                  state: 'up',
                  tag: 'pm3',
                  type: 'jail',
                  ip4: 'igb0|10.101.11.124',
                  release: '11.0-RELEASE-p1',
                  template: '-' },
                { jid: '-',
                  uuid: 'f7ebd857-b9c3-11e6-93eb-0025905cf7cc',
                  boot: 'off',
                  state: 'down',
                  tag: 'pm6',
                  type: 'jail',
                  ip4: 'igb0|10.101.11.126',
                  release: '11.0-RELEASE-p1',
                  template: '-' }]

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

      expect(results).to(include('tag' => 'media2'))
      expect(results).to(include('boot' => 'on'))
      expect(results).to(include('jail_zfs' => 'on'))
      expect(results).to(include('jail_zfs_dataset' => 'media_in'))
      expect(results).to(include('ip4_addr' => 'ethernet0|10.0.0.10'))
      expect(results).to(include('ip6_addr' => 'ethernet0|2001:470:deed::100'))
    end
  end
end
