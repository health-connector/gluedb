module CanonicalVocabulary
  module Renewals
    class RenewalReportRowBuilder
      attr_reader :data_set
      def initialize(application_group, primary)
        @data_set = []
        @application_group = application_group
        @primary = primary
      end

      def append_integrated_case_number
        @data_set << @application_group.e_case_id
      end

      def append_name_of(member)
        @data_set << member.person.name_first
        @data_set << member.person.name_last
      end

      def append_notice_date(notice_date)
        @data_set << notice_date
      end

      def append_household_address
        address = @primary.person.addresses[0]
        @data_set << address[:address_1]
        @data_set << address[:address_2]
        @data_set << address[:apt]
        @data_set << address[:city]
        @data_set << address[:state]
        @data_set << address[:postal_code]
      end

      def append_aptc
        append_blank 
      end

      def append_response_date(response_date)
        @data_set << response_date
      end

      def append_policy(policy)
        @data_set << (policy.current.nil? ? nil : policy.current[1][:plan])
        @data_set << policy.future_plan_name
        @data_set << policy.quoted_premium
      end

      def append_post_aptc_premium
        append_blank  
      end

      def append_financials
        @data_set << @application_group.yearly_income("2014")
        append_blank 
        @data_set << @application_group.irs_consent
      end

      def append_age_of(member)
        @data_set << member.age
      end

      def append_residency_of(member)
        @data_set << residency(member)
      end

      def append_citizenship_of(member)
        @data_set << citizenship(member)
      end

      def append_tax_status_of(member)
        @data_set << tax_status(member)
      end

      def append_mec_of(member)
        @data_set << member.mec
      end

      def append_app_group_size
        @data_set << @application_group.applicants.count
      end

      def append_yearwise_income_of(member)
        @data_set << member.yearwise_incomes("2014")
      end

      def append_blank
        @data_set << nil
      end

      def append_incarcerated(member)
        @data_set << incarcerated?(member)
      end

      private

      def residency(member)
        if member.person.addresses.blank?
          member = @primary
        end
        member.person.addresses[0][:state].strip == 'DC' ? 'D.C. Resident' : 'Not a D.C. Resident'
      end

      def citizenship(applicant)
        return if applicant.person_demographics.blank?
        demographics = applicant.person_demographics
        if demographics.citizen_status.blank?
          raise "Citizenship status missing for person #{self.name_first} #{self.name_last}"
        end

        citizenship_mapping = {
          "U.S. Citizen" => %W(us_citizen naturalized_citizen indian_tribe_member),
          "Lawfully Present" => %W(alien_lawfully_present lawful_permanent_resident),
          "Not Lawfully Present" => %W(undocumented_immigrant not_lawfully_present_in_us)
        }
        citizen_status = demographics.citizen_status
        citizenship_mapping.each do |key, value|
          return key if value.include?(citizen_status)
        end
      end

      def tax_status(applicant)
        return if applicant.financial_statements.blank?
        financial_statement = applicant.financial_statements[0]
        tax_status = financial_statement.tax_filing_status
        case tax_status
        when 'non_filer'
          'Non-filer'
        when 'tax_dependent'
          'Tax Dependent'
        when 'tax_filer'
          tax_filer_status(applicant, financial_statement)
        end
      end

      def tax_filer_status(applicant, financial_statement)
        relationship = applicant.person_relationships.detect{|i| ['spouse', 'life partner'].include?(i.relationship_uri)}
        if relationship.nil?
          return 'Single'
        end
        financial_statement.is_tax_filing_together ? 'Married Filing Jointly' : 'Married Filing Separately'
      end

      def incarcerated?(member)
        return 'No' if member.person_demographics.blank?
        member.person_demographics.is_incarcerated == 'true' ? 'Yes' : 'No'
      end
    end
  end
end
