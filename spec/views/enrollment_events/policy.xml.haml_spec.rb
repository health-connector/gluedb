require "rails_helper"
require File.join(Rails.root, "spec", "support", "acapi_vocabulary_spec_helpers")

describe "enrollment_events/_policy.xml" do
  include AcapiVocabularySpecHelpers

  before :all do
    download_vocabularies
  end

  let(:broker) do
    instance_double Broker,
      npn: 'npn',
      full_name: 'Full Name',
      is_active: true
  end

  let(:carrier) do
    instance_double Carrier,
      name: 'Carrier',
      hbx_carrier_id: 'hbx_carrier_id',
      id: 'sd8f7s9d8f7'
  end

  let(:plan) do
    instance_double Plan,
      hios_plan_id: 'hios_plan_id',
      carrier: carrier,
      name: "The Plan",
      year: Date.today.year,
      coverage_type: 'health',
      metal_level: 'Gold',
      ehb: BigDecimal.new("0.0"),
      id: 'a12db3',
      carrier_id: carrier.id
  end

  let(:subscriber_person) do
    instance_double Person,
      authority_member: instance_double(Member,
        hbx_member_id: 'hbx_member_id',
        ssn: '222-22-2222',
        dob: Date.new(1981, 9, 22),
        gender: 'male'),
      name_first: 'John',
      name_last: 'Jacobjingheimerschmidt',
      name_pfx: nil,
      name_sfx: nil,
      name_middle: nil,
      addresses: [],
      emails: [],
      phones: []
  end

  let(:subscriber) do
    instance_double Enrollee,
      person: subscriber_person,
      subscriber?: true,
      pre_amt: BigDecimal.new("899.99"),
      coverage_start: Date.today + 1.day,
      coverage_end: Time.now.end_of_year.to_date,
      cp_id: 'carrier_policy_id',
      c_id: 'carrier_member_id'
  end

  let(:policy) do
    instance_double Policy,
      eg_id: 'the-eg-id',
      broker: broker,
      subscriber: subscriber,
      has_responsible_person?: false,
      plan: plan,
      carrier_specific_plan_id: 'carrier_specific_plan_id',
      is_shop?: false,
      applied_aptc: BigDecimal.new("0.0"),
      assistance_effective_date: Date.today + 1.day,
      pre_amt_tot: BigDecimal.new("899.99"),
      tot_res_amt: BigDecimal.new("899.99"),
      rating_area: 'rating_area',
      created_at: Time.now - 1.week,
      updated_at: nil
  end

  let(:life_partner_person) do
    instance_double Person,
      authority_member: instance_double(Member,
        hbx_member_id: 'hbx_member_id',
        ssn: '222-22-2223',
        dob: Date.new(1981, 9, 22),
        gender: 'male'),
      name_first: 'Jacob',
      name_last: 'Jacobjingheimerschmidt',
      name_pfx: nil,
      name_sfx: nil,
      name_middle: nil,
      addresses: [],
      emails: [],
      phones: []
  end

  let(:life_partner) do
    instance_double Enrollee,
      person: life_partner_person,
      subscriber?: false,
      relationship_status_code: "life partner",
      pre_amt: BigDecimal.new("899.99"),
      coverage_start: Date.today + 1.day,
      coverage_end: Time.now.end_of_year.to_date,
      cp_id: 'carrier_policy_id',
      c_id: 'carrier_member_id'
  end

  before do
    allow(policy).to receive(:plan_id).and_return(plan.id)
    render :template => "enrollment_events/_policy",
      :layout => 'layouts/policy_test',
      :locals => { :policy => policy, :enrollees => [ subscriber, life_partner ] }
  end

  subject { rendered }

  it "should be schema valid" do
    expect(validate_with_schema(Nokogiri::XML(subject))).to eq([])
  end
end
