require 'rails_helper'

describe Carrier, "given nothing" do
  it "does not require simple plan changes" do
    expect(subject.requires_simple_plan_changes?).to be_falsey
  end
end

describe Carrier, "given:
- a requirement for simple plan changes
", dbclean: :after_each do
  subject do
    Carrier.new({
      :requires_simple_plan_changes => true
    })
  end

  it "requires simple plan changes" do
    expect(subject.requires_simple_plan_changes?).to be_truthy
  end
end

describe Carrier, "given nothing" do
  it "does not require simple renewal" do
    expect(subject.requires_simple_renewal?).to be_falsey
  end
end

describe Carrier, "given:
- a requirement for simple renewal
", dbclean: :after_each  do
  subject do
    Carrier.new({
      :requires_simple_renewal => true
    })
  end

  it "requires simple renewal" do
    expect(subject.requires_simple_renewal?).to be_truthy
  end
end

describe Carrier, dbclean: :after_each do
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
    :carrier_profiles,
    :uses_issuer_centric_sponsor_cycles
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

  it 'has a default value of false for uses_issuer_centric_sponsor_cycles' do
    expect(carrier.uses_issuer_centric_sponsor_cycles).to eq false
  end
end
