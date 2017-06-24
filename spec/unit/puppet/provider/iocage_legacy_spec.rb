require 'spec_helper'
require 'puppet/provider/jail/iocage_legacy'

provider_class = Puppet::Type.type(:jail).provider(:iocage_legacy)

describe provider_class do
  context '#jail_list' do
    it 'parses jail listing' do
      fixture = File.read('spec/fixtures/iocage_list')
      # provider_class.stub(:iocage).with(['list']) { fixture }
      allow(provider_class).to receive(:iocage).with(['list']) { fixture }
      wanted = [{ jid: '-', uuid: '018e776d-4315-11e5-94bc-0025905cf7cc', boot: 'off', state: 'down', tag: 'auth4' }, { jid: '-', uuid: '14b47568-448e-11e5-94bc-0025905cf7cc', boot: 'off', state: 'down', tag: 'graphite2' }, { jid: '1', uuid: '19e2885e-448e-11e5-94bc-0025905cf7cc', boot: 'on', state: 'up', tag: 'git2' }, { jid: '2', uuid: '64a7af2c-4909-11e5-9073-0025905cf7cc', boot: 'on', state: 'up', tag: 'pm3' }, { jid: '-', uuid: 'c3936d1d-46f5-11e5-9073-0025905cf7cc', boot: 'off', state: 'down', tag: 'ns1' }, { jid: '333', uuid: 'ca29dc76-46f6-11e5-9073-0025905cf7cc', boot: 'on', state: 'up', tag: 'pdb2' }, { jid: '-', uuid: 'e2f5f461-4314-11e5-94bc-0025905cf7cc', boot: 'off', state: 'down', tag: 'mon1' }, { jid: '10', uuid: 'e2f5f462-4314-11e5-94bc-0025905cf7cc', boot: 'off', state: 'down', tag: 'mon2' }, { jid: '-', uuid: 'fdd4151c-d555-11e5-b08a-0025906cac26', boot: 'off', state: 'down', tag: '741ac3b9-7c44-4400-8916-4ee6037d94bd' }]
      expect(provider_class.jail_list).to eq(wanted)
    end
  end

  context '#jail_list-t' do
    it 'parses jail listing' do
      fixture = File.read('spec/fixtures/iocage_list-t')
      allow(provider_class).to receive(:iocage).with(['list']) { fixture }
      wanted = [{ jid: '-', uuid: 'b439bd7a-5376-11e7-ad91-d979c2a3eb55', boot: 'off', state: 'down', tag: 'f11-puppet4' }]
      expect(provider_class.jail_list).to eq(wanted)
    end
  end

  context '#get_jail_properties-t' do
    it 'parses jail properties' do
      list_fixture = File.read('spec/fixtures/iocage_list-t')
      allow(provider_class).to receive(:iocage).with(['list']) { list_fixture }

      get_fixture = File.read('spec/fixtures/iocage_jail_get_all-t')
      allow(provider_class).to receive(:iocage).with(['get', 'all', 'b439bd7a-5376-11e7-ad91-d979c2a3eb55']) { get_fixture }

      results = provider_class.get_jail_properties('b439bd7a-5376-11e7-ad91-d979c2a3eb55')

      expect(results).to(include(
                           'tag'      => 'f11-puppet4',
                           'boot'     => 'off',
                           'template' => 'yes'
      ))
    end
  end
end
