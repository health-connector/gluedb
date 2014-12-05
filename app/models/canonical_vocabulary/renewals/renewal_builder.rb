module CanonicalVocabulary
  module Renewals
     module RenewalBuilder
      
      def residency(member)
        if member.person.addresses.blank?
          member = @primary
        end
        member.person.addresses[0].location_state_code == 'DC' ? 'D.C. Resident' : 'Not a D.C. Resident'
      end

      def citizenship(applicant)
        return if applicant.person_demographics.blank?
        demographics = applicant.person_demographics
        if demographics.citizen_status.blank?
          raise "Citizenship status missing for person #{applicant.person.name_first} #{applicant.person.name_last}"
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
        return if applicant.financial_statements.empty?
        financial_statement = applicant.financial_statements[0]
        tax_status = financial_statement.tax_filing_status.split('#')[1]
        case tax_status
        when 'non-filer'
          'Non-filer'
        when 'dependent'
          'Tax Dependent'
        when 'tax_filer'
          tax_filer_status(applicant, financial_statement)
        end
      end

      def tax_filer_status(applicant, financial_statement)
        return 'Single' if is_single?(applicant)
        (financial_statement.is_tax_filing_together == 'true') ? 'Married Filing Jointly' : 'Married Filing Separately'
      end

      def is_single?(applicant)
        relation = applicant.person_relationships.detect{|i| ['spouse', 'life_partner'].include?(i.relationship_uri)}
        relation.blank? ? true : false
      end

      def incarcerated?(member)
        if member.person_demographics.blank?
          return 'No'
        end
        member.person_demographics.is_incarcerated == 'true' ? 'Yes' : 'No'
      end

      # def member_mec(member)
      #   if es_coverage = assistance_eligibility.at_xpath("n1:is_enrolled_for_es_coverage").text
      #     return 'Yes'
      #   end
      #   benefit = assistance_eligibility.xpath("n1:alternate_benefits/n1:alternate_benefit").detect do |benefit|
      #     Date.strptime(benefit.at_xpath("n1:end_date"), "%Y%m%d") <= Date.parse("2015-1-1")
      #   end
      #   benefit.blank? ? 'No' : 'Yes'    
      # end
    end
  end
end