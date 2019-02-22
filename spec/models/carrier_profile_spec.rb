require 'rails_helper'

describe CarrierProfile do
  [:fein, :profile_name, :uses_issuer_centric_sponsor_cycles].each do |attribute|
    it { should respond_to attribute }
  end
  it 'should default the uses_issuer_centric_sponsor_cycles to false' do 
    expect(CarrierProfile.new.uses_issuer_centric_sponsor_cycles).to eq false
  end
end
