require 'spec_helper'

describe Carrier do
  subject(:carrier) { build :carrier }
  [
    :name,
    :abbrev,
    :hbx_carrier_id,
    :ind_hlt,
    :ind_dtl,
    :shp_hlt,
    :shp_dtl,
    :plans,
    :policies,
    :premium_payments,
    :brokers,
    :carrier_profiles
  ].each do |attribute|
    it { should respond_to attribute }
  end

  it 'retrieves carriers in individual health market' do
    carrier.ind_hlt = true;
    carrier.save!
    expect(Carrier.individual_market_health.to_a).to eq [carrier]
  end

  it 'retrieves carrier in individual dental market' do
    carrier.ind_dtl = true;
    carrier.save!
    expect(Carrier.individual_market_dental.to_a).to eq [carrier]
  end

  it 'retrieves carrier in shop health market' do
    carrier.shp_hlt = true;
    carrier.save!
    expect(Carrier.shop_market_health.to_a).to eq [carrier]
  end

  it 'retrieves carrier in shop dental market' do
    carrier.shp_dtl = true;
    carrier.save!
    expect(Carrier.shop_market_dental.to_a).to eq [carrier]
  end

  it 'finds carrier by hbx id' do
    carrier.save!
    expect(Carrier.for_hbx_id(carrier.hbx_carrier_id)).to eq carrier
  end

  it 'find carriers by fein' do
    fein = '1234'
    carrier.carrier_profiles << CarrierProfile.new(fein: fein)
    carrier.save!
    expect(Carrier.for_fein(fein)).to eq carrier
  end
end
