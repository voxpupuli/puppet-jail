require 'spec_helper'
require 'puppet/provider/jail/iocage'

provider_class = Puppet::Type.type(:jail).provider(:iocage)

describe provider_class do

  context "#jail_list" do

    it "should parse the jail results" do
      fixture = File.read('spec/fixtures/iocage_list')
      #provider_class.stub(:iocage).with(['list']) { fixture }
      allow(provider_class).to receive(:iocage).with(['list']) { fixture }
      wanted = [{:jid=>"1", :uuid=>"b604d70f-220f-11e5-ad5f-0025905cf7cd", :boot=>"off", :state=>"up", :tag=>"mon1"}, {:jid=>"-", :uuid=>"fdfad85f-220c-11e5-ad5f-0025905cf7cd", :boot=>"off", :state=>"down", :tag=>"fbsd10.1"}]
      expect(provider_class.jail_list).to eq(wanted)
    end
  end
end
