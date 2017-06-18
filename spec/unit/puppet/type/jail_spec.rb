require 'spec_helper'
require 'puppet/type/jail'

type_class = Puppet::Type.type(:jail)

describe type_class do
  [:absent, :present, :template].each do |v|
    it "should support #{v} as a value to :ensure" do
      j = type_class.new(name: 'myjail', ensure: v)
      expect(j.should(:ensure)).to eq(v)
    end
  end

  let :params do
    [
      :name,
      :jid,
      :user_data
    ]
  end

  let :properties do
    [
      :ensure,
      :state,
      :boot,
      :ip4_addr,
      :ip6_addr,
      :jail_zfs,
      :jail_zfs_dataset
    ]
  end

  it 'has expected properties' do
    properties.each do |property|
      expect(type_class.properties.map(&:name)).to be_include(property)
    end
  end

  it 'has expected parameters' do
    params.each do |param|
      expect(type_class.parameters).to be_include(param)
    end
  end
end
