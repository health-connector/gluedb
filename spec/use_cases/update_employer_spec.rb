# require './app/use_cases/update_employer'
require 'rails_helper'
describe UpdateEmployer do
  subject { UpdateEmployer.new(repository, address_factory, phone_factory, email_factory, plan_year_factory) }
  let(:repository) { double(find_for_fein: employer) }
  let(:employer) { double(merge_address: nil, merge_phone: nil, merge_email: nil, merge_plan_year: nil, merge_carriers: nil, save!: nil) }
  let(:address_factory) { double(make: address)}
  let(:address) { double }

  let(:phone_factory) { double(make: phone)}
  let(:phone) { double }

  let(:email_factory) { double(make: email)}
  let(:email) { double }

  let(:plan_year_factory) { double(make: plan_year) }
  let(:plan_year) { double(carriers: [double])}

  let(:request) do
    {
      fein: '111111111',
      contact: {
        address: {
          type: 'work',
          street1: '1234 high street',
          street2: '#2',
          city: 'Atlanta',
          state: 'GA',
          zip: '12345'
        },
        email: {
          email_type: 'home',
          email_address: 'example@example.com'
        },
        phone: {
          phone_type: 'work',
          phone_number: '123-123-1234'
        },
        name:{
          first: 'Joe',
          last: 'Kramer'
        }
      },
      fte_count: 1,
      pte_count: 1,
      open_enrollment_start: Date.today,
      open_enrollment_end: Date.today,
      plan_year_start: Date.today,
      plan_year_end: Date.today,
      broker_npn: '123456',
      plans: [
        {
          carrier_id: '11111',
          qhp_id: '22222',
          coverage_type: 'health',
          metal_level: 'gold',
          hbx_plan_id: '33333',
          original_effective_date: Date.today,
          plan_name: 'Super Plan',
          carrier_policy_number: '12345',
          carrier_employer_group_id: '4321'
        }
      ]
    }
  end

  before do
    allow(employer).to receive(:name=)
    allow(employer).to receive(:hbx_id=)
    allow(employer).to receive(:fein=)
    allow(employer).to receive(:sic_code=)
    allow(employer).to receive(:notes=)
    allow(employer).to receive(:update_contact)
  end

  it 'finds the employer' do
    expect(repository).to receive(:find_for_fein).with(request[:fein])
    subject.execute(request)
  end

  it 'makes an address' do
    expect(address_factory).to receive(:make).with(request[:contact][:address])
    subject.execute(request)
  end

  it 'merges requested address into employer' do
    expect(employer).to receive(:merge_address).with(address)
    subject.execute(request)
  end

  it 'makes a phone' do
    expect(phone_factory).to receive(:make).with(request[:contact][:phone])
    subject.execute(request)
  end

  it 'merges requested phone into employer' do
    expect(employer).to receive(:merge_phone).with(phone)
    subject.execute(request)
  end

  it 'makes an email' do
    expect(email_factory).to receive(:make).with(request[:contact][:email])
    subject.execute(request)
  end

  it 'merges requested email into employer' do
    expect(employer).to receive(:merge_email).with(email)
    subject.execute(request)
  end

  it 'makes a plan year' do
    expect(plan_year_factory).to receive(:make).with({
      open_enrollment_start: request[:open_enrollment_start],
      open_enrollment_end: request[:open_enrollment_end],
      start_date: request[:plan_year_start],
      end_date: request[:plan_year_end],
      plans: request[:plans],
      broker_npn: request[:broker_npn],
      fte_count: request[:fte_count],
      pte_count: request[:pte_count]
    }).and_return(plan_year)

    subject.execute(request)
  end

  it 'overwrites the contact info' do
    expect(employer).to receive(:update_contact).with(request[:contact][:name])
    subject.execute(request)
  end

  it 'merges plan year into employer' do
    expect(employer).to receive(:merge_plan_year).with(plan_year)
    subject.execute(request)
  end

  it 'merges employers direct attributes' do
    # expect(employer).to receive(:merge_without_blanking).with(e,
    #       :name,
    #       :hbx_id,
    #       :fein,
    #       :sic_code,
    #       :open_enrollment_start,
    #       :open_enrollment_end,
    #       :plan_year_start,
    #       :plan_year_end,
    #       :aasm_state,
    #       :fte_count,
    #       :pte_count,
    #       :msp_count,
    #       :notes
    #       )
    # subject.execute(request)
  end

  it 'saves the employer' do
    expect(employer).to receive(:save!)
    subject.execute(request)
  end
end
