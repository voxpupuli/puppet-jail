require 'spec_helper'
require 'puppet/provider/jail/iocage'

provider_class = Puppet::Type.type(:jail).provider(:iocage)

describe provider_class do

  ensures = [:present, :absent]
  states = ['down', 'up']
  # boots = ['on', 'off']

  ensures.each do |e|
    before do
    end

    context "ensure #{e}" do
      states.each do |s|
        context "state #{s}" do

          it do
            fixture = File.read('spec/fixtures/single_list_up')
            get_fixture = File.read('spec/fixtures/single_get_all_up')
            expect(provider_class).to receive(:iocage).with(['get', 'all', 'metrics2']) { get_fixture }
            expect(provider_class).to receive(:iocage).with(['list']) { fixture }

            case e
            when :present
              case s
              when 'up'
                expect(provider_class).to_not receive(:iocage).with(['stop', 'metrics2'])
                expect(provider_class).to_not receive(:iocage).with(['start', 'metrics2'])
                expect(provider_class).to_not receive(:iocage).with(/destroy.*metrics2/)
                expect(provider_class).to_not receive(:iocage).with(/create.*metrics2/)
              when 'down'
                expect(provider_class).to receive(:iocage).with(['stop', 'metrics2'])
              end
            when :absent
              expect(provider_class).to receive(:iocage).with(['stop', 'metrics2'])
              expect(provider_class).to receive(:iocage).with(['destroy', '-f', 'metrics2'])
            end

            resource_hash = {
              name: 'metrics2',
              state: s,
              ensure: e,
            }

            resource = provider_class.new(resource_hash)
            data = provider_class.prefetch({'jail1' => resource})
            instance = data[0]
            instance.resource = resource_hash
            instance.flush
          end

        end
      end
    end
  end

  context '#jail_list' do
    it 'parses jail listing' do
      fixture = File.read('spec/fixtures/iocage_list')
      # provider_class.stub(:iocage).with(['list']) { fixture }
      allow(provider_class).to receive(:iocage).with(['list']) { fixture }
      wanted = [{ jid: '-', uuid: '018e776d-4315-11e5-94bc-0025905cf7cc', boot: 'off', state: 'down', tag: 'auth4' }, { jid: '-', uuid: '14b47568-448e-11e5-94bc-0025905cf7cc', boot: 'off', state: 'down', tag: 'graphite2' }, { jid: '1', uuid: '19e2885e-448e-11e5-94bc-0025905cf7cc', boot: 'on', state: 'up', tag: 'git2' }, { jid: '2', uuid: '64a7af2c-4909-11e5-9073-0025905cf7cc', boot: 'on', state: 'up', tag: 'pm3' }, { jid: '-', uuid: 'c3936d1d-46f5-11e5-9073-0025905cf7cc', boot: 'off', state: 'down', tag: 'ns1' }, { jid: '333', uuid: 'ca29dc76-46f6-11e5-9073-0025905cf7cc', boot: 'on', state: 'up', tag: 'pdb2' }, { jid: '-', uuid: 'e2f5f461-4314-11e5-94bc-0025905cf7cc', boot: 'off', state: 'down', tag: 'mon1' }, { jid: '10', uuid: 'e2f5f462-4314-11e5-94bc-0025905cf7cc', boot: 'off', state: 'down', tag: 'mon2' }, { jid: '-', uuid: 'fdd4151c-d555-11e5-b08a-0025906cac26', boot: 'off', state: 'down', tag: '741ac3b9-7c44-4400-8916-4ee6037d94bd' }]
      expect(provider_class.jail_list).to eq(wanted)
    end
  end

  context '#get_jail_properties' do
    it 'parses jail properties' do
      list_fixture = File.read('spec/fixtures/iocage_list')
      allow(provider_class).to receive(:iocage).with(['list']) { list_fixture }

      get_fixture = File.read('spec/fixtures/iocage_jail_get_all')
      allow(provider_class).to receive(:iocage).with(['get', 'all', 'f9e67f5a-4bbe-11e6-a9b4-eca86bff7d21']) { get_fixture }

      results = provider_class.get_jail_properties('f9e67f5a-4bbe-11e6-a9b4-eca86bff7d21')

      results.should(include('tag' => 'media2'))
      results.should(include('boot' => 'on'))
      results.should(include('jail_zfs' => 'on'))
      results.should(include('jail_zfs_dataset' => 'media_in'))
      results.should(include('ip4_addr' => 'ethernet0|10.0.0.10'))
      results.should(include('ip6_addr' => 'ethernet0|2001:470:deed::100'))
    end
  end
end
