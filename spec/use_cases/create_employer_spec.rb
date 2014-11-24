# require './app/use_cases/create_employer'
require 'rails_helper'
describe CreateEmployer do
  subject { CreateEmployer.new(listener, factory, plan_year_factory, address_factory, email_factory, phone_factory, broker_repo) }

  let(:employer) { 
    double(
      save!: nil, 
      valid?: true, 
      plan_years: plan_years, 
      addresses: addresses,
      emails: emails, 
      phones: phones,
      :name_pfx= => nil,
      :name_first= => nil,
      :name_middle= => nil,
      :name_last= => nil,
      :name_sfx= => nil,
      update_carriers: nil
    ) 
  }
  let(:plan_years) { double(:<< => nil) }
  let(:addresses) { double(:<< => nil) }
  let(:emails) { double(:<< => nil) }
  let(:phones) { double(:<< => nil) }

  let(:factory) { double(make: employer) }
  let(:plan_year_factory) { double(make: plan_year) }
  let(:plan_year) { double(:broker= => nil) }

  let(:address_factory) { double(make: address) }
  let(:address) { double }

  let(:email_factory) { double(make: email) }
  let(:email) { double }

  let(:phone_factory) { double(make: phone) }
  let(:phone) { double }

  let(:broker_repo) { double(find_by_npn: broker) }
  let(:broker) { double }

  let(:listener) { double(success: nil, fail: nil, invalid_employer: nil)}
  let(:request) do
    {
      :name => 'The Best Employer',
      :fein => '123456',
      :hbx_id => '654321',
      :sic_code => '1234',
      :fte_count => 1,
      :pte_count => 1,
      :open_enrollment_start => Date.today,
      :open_enrollment_end => Date.today,
      :plan_year_start => Date.today,
      :plan_year_end => Date.today,
      :notes => 'blah blah blah',
      :contact => {
        :name => {
          :prefix => 'Mr',
          :first => 'Joe',
          :middle => 'J',
          :last => 'Dirt',
          :suffix => 'Jr'
        },
        :address => {
          :type => 'work',
          :street1 => '1234 high street',
          :street2 => '#2',
          :city => 'Atlanta',
          :state => 'GA',
          :zip => '12345'
        },
        :email => {
          :email_type => 'home',
          :email_address => 'example@example.com'
        },
        :phone => {
          :phone_type => 'work',
          :phone_number => '123-123-1234'
        }
        
      },
      :broker_npn => '123456',
      :plans => [
        {
          :carrier_id => '11111',
          :qhp_id => '22222',
          :coverage_type => 'health',
          :metal_level => 'gold',
          :hbx_plan_id => '33333',
          :original_effective_date => Date.today,
          :plan_name => 'Super Plan',
          :carrier_policy_number => '12345',
          :carrier_employer_group_id => '4321'
        }
      ]
    }
  end

  before :each do
    allow(employer).to receive(:merge_plan_year).with(plan_year)
  end

  it 'makes an employer' do
    expect(factory).to receive(:make).with(request)
    subject.execute(request)
  end

  # it 'finds the broker' do
  #   expect(broker_repo).to receive(:find_by_npn).with(request[:broker_npn]).and_return(broker)
  #   subject.execute(request)
  # end

  # it 'associates broker to plan year' do
  #   expect(plan_year).to receive(:broker=).with(broker)
  #   subject.execute(request)
  # end

  it 'creates a plan year' do
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

    # expect(plan_years).to receive(:<<).with(plan_year)
    expect(employer).to receive(:merge_plan_year).with(plan_year)
    subject.execute(request)
  end
=begin
  it 'associates with with carriers' do
    expect(employer).to receive(:update_carriers).with(plan_year)
    subject.execute(request)
  end
=end
  it 'assigns contact name' do
    name = request[:contact][:name]
    expect(employer).to receive(:name_pfx=).with(name[:prefix])
    expect(employer).to receive(:name_first=).with(name[:first])
    expect(employer).to receive(:name_middle=).with(name[:middle])
    expect(employer).to receive(:name_last=).with(name[:last])
    expect(employer).to receive(:name_sfx=).with(name[:suffix])
    subject.execute(request)
  end

  it 'creates an address' do
    expect(address_factory).to receive(:make).with(request[:contact][:address]).and_return(address)
    expect(addresses).to receive(:<<).with(address)
    subject.execute(request)
  end

  it 'creates a phone' do
    expect(phone_factory).to receive(:make).with(request[:contact][:phone]).and_return(phone)
    expect(phones).to receive(:<<).with(phone)
    subject.execute(request)
  end

  it 'creates an email' do
    expect(email_factory).to receive(:make).with(request[:contact][:email]).and_return(email)
    expect(emails).to receive(:<<).with(email)
    subject.execute(request)
  end

  it 'saves new employer' do
    expect(employer).to receive(:save!)
    expect(listener).to receive(:success)
    subject.execute(request)
  end

  context "when employer is invalid" do
    let(:error_details) { {:something => ["can't be blank"]} }
    let(:employer) { double(:valid? => false, :errors => error_details) }

    it 'notifies the listener that there is an invalid employer' do
      expect(listener).to receive(:invalid_employer).with(error_details)
      expect(listener).to receive(:fail)

      subject.execute(request)
    end

    it 'does not save' do
      expect(employer).not_to receive(:save!)
      subject.execute(request)
    end
  end
end
