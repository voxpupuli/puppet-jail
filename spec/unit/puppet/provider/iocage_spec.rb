require 'spec_helper'
require 'puppet/provider/jail/iocage'

provider_class = Puppet::Type.type(:jail).provider(:iocage)

describe provider_class do

  context "#jail_list" do

    it "should parse the jail results" do
      fixture = File.read('spec/fixtures/iocage_list')
      #provider_class.stub(:iocage).with(['list']) { fixture }
      allow(provider_class).to receive(:iocage).with(['list']) { fixture }
      wanted = [{:jid=>"-", :uuid=>"018e776d-4315-11e5-94bc-0025905cf7cc", :boot=>"off", :state=>"down", :tag=>"auth4"}, {:jid=>"-", :uuid=>"14b47568-448e-11e5-94bc-0025905cf7cc", :boot=>"off", :state=>"down", :tag=>"graphite2"}, {:jid=>"1", :uuid=>"19e2885e-448e-11e5-94bc-0025905cf7cc", :boot=>"on", :state=>"up", :tag=>"git2"}, {:jid=>"2", :uuid=>"64a7af2c-4909-11e5-9073-0025905cf7cc", :boot=>"on", :state=>"up", :tag=>"pm3"}, {:jid=>"-", :uuid=>"c3936d1d-46f5-11e5-9073-0025905cf7cc", :boot=>"off", :state=>"down", :tag=>"ns1"}, {:jid=>"333", :uuid=>"ca29dc76-46f6-11e5-9073-0025905cf7cc", :boot=>"on", :state=>"up", :tag=>"pdb2"}, {:jid=>"-", :uuid=>"e2f5f461-4314-11e5-94bc-0025905cf7cc", :boot=>"off", :state=>"down", :tag=>"mon1"}]
      expect(provider_class.jail_list).to eq(wanted)
    end
  end
end
