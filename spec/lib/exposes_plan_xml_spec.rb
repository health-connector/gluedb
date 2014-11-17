require 'open-uri'
require 'nokogiri'

require './lib/exposes_plan_xml'

describe ExposesPlanXml do
  let(:namespace) { "xmlns=\"http://dchealthlink.com/vocabulary/20131030/employer\"" }

  it 'exposes qhp id' do
    qhp_id = '666'
    parser = Nokogiri::XML("<plan #{namespace}><qhp_id>#{qhp_id}</qhp_id></plan>")
    plan = ExposesPlanXml.new(parser.root)
    expect(plan.qhp_id).to eq qhp_id
  end

  it 'exposes plan exchange id' do
    plan_exchange_id = '666'
    parser = Nokogiri::XML("<plan #{namespace}><plan_exchange_id>#{plan_exchange_id}</plan_exchange_id></plan>")
    plan = ExposesPlanXml.new(parser.root)
    expect(plan.plan_exchange_id).to eq plan_exchange_id
  end

  it 'exposes carrier id' do
    carrier_id = '1234'
    parser = Nokogiri::XML("<plan #{namespace}><carrier_id>#{carrier_id}</carrier_id></plan>")
    plan = ExposesPlanXml.new(parser.root)
    expect(plan.carrier_id).to eq carrier_id
  end

  it 'exposes carrier_name' do
    carrier_name = 'Carrier of the Wayward Sun'
    parser = Nokogiri::XML("<plan #{namespace}><carrier_name>#{carrier_name}</carrier_name></plan>")
    plan = ExposesPlanXml.new(parser.root)
    expect(plan.carrier_name).to eq carrier_name
  end

  it 'exposes plan name' do
    plan_name = 'Super Awesome Plan'
    parser = Nokogiri::XML("<plan #{namespace}><plan_name>#{plan_name}</plan_name></plan>")
    plan = ExposesPlanXml.new(parser.root)
    expect(plan.name).to eq plan_name
  end

  it 'exposes coverage type' do
    coverage_type = 'Total Coverage'
    parser = Nokogiri::XML("<plan #{namespace}><coverage_type>#{coverage_type}</coverage_type></plan>")
    plan = ExposesPlanXml.new(parser.root)
    expect(plan.coverage_type).to eq coverage_type
  end

  it 'exposes the original effective date' do
    original_effective_date = '1980-02-01'
    parser = Nokogiri::XML("<plan #{namespace}><original_effective_date>#{original_effective_date}</original_effective_date></plan>")
    plan = ExposesPlanXml.new(parser.root)
    expect(plan.original_effective_date).to eq original_effective_date
  end

  describe 'group id' do
    it 'exposes the group id when present' do
      group_id = '777'
      parser = Nokogiri::XML("<plan #{namespace}><group_id>#{group_id}</group_id></plan>")
      plan = ExposesPlanXml.new(parser.root)
      expect(plan.group_id).to eq group_id
    end

    it 'returns blank when absent' do
      parser = Nokogiri::XML("<plan #{namespace}></plan>")
      plan = ExposesPlanXml.new(parser.root)
      expect(plan.group_id).to eq nil
    end
  end

  it 'exposes the metal level code' do
    metal_level_code = 'silver'
    parser = Nokogiri::XML("<plan #{namespace}><metal_level_code>#{metal_level_code}</metal_level_code></plan>")
    plan = ExposesPlanXml.new(parser.root)
    expect(plan.metal_level_code).to eq metal_level_code
  end

  describe 'carrier assigned policy number' do
    it 'exposes number when present' do
      policy_number = '1234'
      parser = Nokogiri::XML("<plan #{namespace}><policy_number>#{policy_number}</policy_number></plan>")
      plan = ExposesPlanXml.new(parser.root)
      expect(plan.policy_number).to eq policy_number
    end

    it 'returns blank when absent' do
      parser = Nokogiri::XML("<plan #{namespace}></plan>")
      plan = ExposesPlanXml.new(parser.root)
      expect(plan.policy_number).to eq ''
    end
  end

end
