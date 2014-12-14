require 'rails_helper'
# require './app/models/canonical_vocabulary/renewals/renewal_report_row_builder'

module CanonicalVocabulary::Renewals
  describe RenewalReportRowBuilder do
    subject { RenewalReportRowBuilder.new(app_group, primary) }
    let(:app_group) { double(e_case_id: 'uri#1234', yearwise_incomes: "250000", irs_consent: nil, size: 2, applicants: applicants) }
    let(:applicants) { [primary, member]}
    let(:primary) { double(person: person)}
    let(:member) { double(person: person, person_demographics: person_demographics, age: 30, tax_status: 'Single', mec: nil)}
    let(:person) { double(name_first: 'Joe', name_last: 'Riden', age: 30, tax_status: 'Single', mec: nil, yearwise_incomes: '120000', incarcerated: false, addresses: addresses) }
    let(:policy) { double(current: current, future_plan_name: 'Best Plan', quoted_premium: "12.21") }
    let(:current) { {plan: double} }
    let(:notice_date) { double }
    let(:addresses) { [ address ] }
    let(:address) { double(address_line_1: 'Wilson Building', address_line_2: 'K Street', apt: 'Suite 100', location_city_name: 'Washington DC', location_state_code: state, location_postal_code: '20002') }
    let(:state) { 'DC'}
    let(:response_date) { double }
    let(:aptc) { nil }
    let(:post_aptc_premium) { nil }
    let(:person_demographics) { double(citizen_status: 'us_citizen', is_incarcerated: 'true', birth_date: '1983-26-12') }

    it 'can append integrated case numbers' do
      subject.append_integrated_case_number

      expect(subject.data_set).to include app_group.e_case_id.split('#')[1]
    end

    it 'can append name of a member' do
      subject.append_name_of(member)

      expect(subject.data_set).to include member.person.name_first
      expect(subject.data_set).to include member.person.name_last
    end

    it 'can append notice date' do
      subject.append_notice_date(notice_date)
      expect(subject.data_set).to include notice_date
    end

    it 'can append household address' do 
      subject.append_household_address
      expect(subject.data_set).to eq [addresses[0].address_line_1, addresses[0].address_line_2, nil, addresses[0].location_city_name, addresses[0].location_state_code, addresses[0].location_postal_code]
    end

    it 'can append aptc' do
      subject.append_aptc
      expect(subject.data_set).to include aptc
    end

    it 'can append response date' do
      subject.append_notice_date(response_date)
      expect(subject.data_set).to include response_date
    end

    # context 'when there is a current policy' do
    #   let(:current) { {plan: double} }
    #   it 'can append policy' do
    #     subject.append_policy(policy)
    #     expect(subject.data_set).to eq [policy.current[:plan], policy.future_plan_name, policy.quoted_premium]
    #   end
    # end

    # context 'when there is no current policy' do
    #   let(:current) { nil }
    #   it 'appends policy with nil current plan' do
    #     subject.append_policy(policy)
    #     expect(subject.data_set).to eq [policy.current, policy.future_plan_name, policy.quoted_premium]
    #   end
    # end

    it 'can append post aptc premium' do
      subject.append_post_aptc_premium
      expect(subject.data_set).to include post_aptc_premium
    end

    # it 'can append financials' do
    #   subject.append_financials
    #   expect(subject.data_set).to eq [app_group.yearwise_incomes, nil, app_group.irs_consent]
    # end

    it 'can append age' do 
      subject.append_age_of(member)
      expect(subject.data_set).to include member.age
    end

    context 'residency status' do
      context 'when member is a D.C resident' do 
        it 'appends dc resident status' do
         subject.append_residency_of(member)
         expect(subject.data_set).to include 'D.C. Resident'
        end
      end

      context 'when member is not a D.C resident' do
        let(:address) { double(address_line_1: '3000 Park Drive', apt: 'Suite 10', location_city_name: 'Alexandria', location_state_code: 'VA', location_postal_code: '22302') }
        it 'appends non dc resident status' do
         subject.append_residency_of(member)
         expect(subject.data_set).to include 'Not a D.C. Resident'
        end
      end

      context 'when member address not present' do
        let(:member) { double(person: person1)}
        let(:person1) { double(addresses: nil)}

        context 'primary member is a D.C resident' do 
          it 'appends dc resident status' do
            subject.append_residency_of(member)
            expect(subject.data_set).to include 'D.C. Resident'         
          end
        end

        context 'primary member is not a D.C resident' do
          let(:address) { double(address_line_1: '3000 Park Drive', apt: 'Suite 10', location_city_name: 'Alexandria', location_state_code: 'VA', location_postal_code: '22302') }

          it 'appends non dc resident status' do
            subject.append_residency_of(member)
            expect(subject.data_set).to include 'Not a D.C. Resident'          
          end      
        end
      end
    end

    it 'can append citizenship' do
      subject.append_citizenship_of(member)
      expect(subject.data_set).to include 'U.S. Citizen'
    end

    # it 'can append tax status' do
    #   subject.append_tax_status_of(member)
    #   expect(subject.data_set).to include member.tax_status
    # end
   
    # it 'can append mec' do
    #   subject.append_mec_of(member)
    #   expect(subject.data_set).to include member.mec
    # end

    it 'can append group size' do
      subject.append_app_group_size
      expect(subject.data_set).to include app_group.size 
    end

    # it 'can append yearly income' do
    #   subject.append_yearwise_income_of(member)
    #   expect(subject.data_set).to include member.yearwise_incomes 
    # end

    it 'can append blank' do
      subject.append_blank
      expect(subject.data_set).to include nil
    end

    it 'can append incarcerated status' do
      subject.append_incarcerated(member)
      expect(subject.data_set).to include 'Yes' 
    end
  end
end