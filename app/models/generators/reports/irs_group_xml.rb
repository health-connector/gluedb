module Generators::Reports  
  class IrsGroupXml

    include ActionView::Helpers::NumberHelper

    NS = { 
      "xmlns" => "urn:us:gov:treasury:irs:common",
      "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
      "xmlns:n1" => "urn:us:gov:treasury:irs:msg:monthlyexchangeperiodicdata"
    }

    def initialize(irs_group)
      @irs_group = irs_group
    end
    
    def serialize
      File.open("#{Rails.root}/h36_sample.xml", 'w') do |file|
        file.write builder.to_xml
      end
    end

    def builder
      Nokogiri::XML::Builder.new do |xml|
        xml['n1'].HealthExchange(NS) do
          xml.SubmissionYr 1000
          xml.SubmissionMonthNum 1
          xml.ApplicableCoverageYr 1000
          xml.IndividualExchange do |xml|
            xml.HealthExchangeId "00.AA*.000.000.000"
            serialize_irs_group(xml)
          end
        end
      end
    end

    def serialize_irs_group(xml)
      xml.IRSHouseholdGrp do |xml|
        xml.IRSGroupIdentificationNum @irs_group.identification_num
        serialize_taxhouseholds(xml)
        serialize_insurance_policies(xml)
      end
    end

    def serialize_taxhouseholds(xml)
      @irs_group.tax_households.each do |tax_household|
        xml.TaxHousehold do |xml|
          tax_household.coverages.each do |coverage|
            serialize_taxhousehold_coverage(xml, coverage)
          end
        end
      end
    end

    def serialize_taxhousehold_coverage(xml, coverage)
      xml.TaxHouseholdCoverage do |xml|
        xml.ApplicableCoverageMonthNum coverage.calender_month
        xml.Household do |xml|
          serialize_household_members(xml, coverage)

          @irs_group.policies_for_ids(coverage.policy_ids).each do |policy|
             montly_disposition = policy.premium_rec_for(coverage.calender_month)
             serialize_associated_policy(xml, montly_disposition, policy)
           end
        end
      end  
    end

    def serialize_household_members(xml, coverage)
      serialize_tax_individual(xml, coverage.primary, 'Primary')
      serialize_tax_individual(xml, coverage.spouse, 'Spouse')
      coverage.dependents.each do |dependent|
        serialize_tax_individual(xml, coverage.spouse, 'Dependent')
      end
    end

    def serialize_tax_individual(xml, individual, relation)
      return if individual.blank?
      xml.send("#{relation}Grp") do |xml|
        xml.send(relation) do |xml|
          serialize_names(xml, individual)
          xml.SSN individual.ssn
          xml.BirthDt date_formatter(individual.dob)
          serialize_address(xml, individual.address)
        end
        # individual.employers.each do |employer_url|
        #   serialize_employer(xml, employer)
        # end
      end
    end

    def serialize_names(xml, individual)
      xml.CompletePersonName do |xml|
        xml.PersonFirstName individual.name_first
        xml.PersonMiddleName individual.name_middle
        xml.PersonLastName individual.name_last
        xml.SuffixName individual.name_sfx
      end
    end

    def serialize_address(xml, address)
      xml.USAddressGrp do |xml|
        xml.AddressLine1Txt address.street_1
        xml.AddressLine2Txt address.street_2
        xml.CityNm address.city
        xml.USStateCd address.state
        xml.USZIPCd address.zip
        # xml.USZIPExtensionCd
      end 
    end

    def serialize_associated_policy(xml, montly_disposition, policy)
      xml.AssociatedPolicy do |xml|
        xml.QHPPolicyNum policy.policy_id
        xml.QHPIssuerEIN "000000000"
        xml.PediatricDentalPlanPremiumInd "N"
        xml.SLCSPAdjMonthlyPremiumAmt montly_disposition.premium_amount_slcsp if montly_disposition.premium_amount_slcsp
        xml.HouseholdAPTCAmt montly_disposition.monthly_aptc if montly_disposition.monthly_aptc
        xml.TotalHsldMonthlyPremiumAmt montly_disposition.premium_amount   
      end
    end

    # def serialize_exemptions(xml)
    # end

    # def serialize_exemption_coverage(xml)
    # end

    def serialize_insurance_policies(xml)
      xml.InsurancePolicy do |xml|
        @irs_group.insurance_policies.each do |policy|
          serialize_insurance_coverages(xml, policy)
        end
      end
    end

    def serialize_insurance_coverages(xml, policy)
      policy.monthly_premiums.each do |premium|
        xml.InsuranceCoverage do |xml|
          xml.ApplicableCoverageMonthNum premium.serial
          xml.QHPPolicyNum policy.policy_id
          # xml.QHPId
          xml.PediatricDentalPlanPremiumInd "N"
          xml.QHPIssuerEIN "000000000"
          xml.IssuerNm policy.issuer_name
          xml.PolicyCoverageStartDt date_formatter(policy.recipient.coverage_start_date)
          xml.PolicyCoverageEndDt date_formatter(policy.recipient.coverage_termination_date)
          xml.TotalQHPMonthlyPremiumAmt premium.premium_amount
          xml.APTCPaymentAmt premium.monthly_aptc if premium.monthly_aptc
          serialize_covered_individuals(xml, policy)
        end
      end
    end

    def serialize_covered_individuals(xml, policy)
      policy.covered_household.each do |individual|
        xml.CoveredIndividual do |xml|
          xml.InsuredPerson do |xml|
            serialize_names(xml, individual)
            xml.SSN individual.ssn
            xml.BirthDt date_formatter(individual.dob)
          end
          xml.CoverageStartDt date_formatter(individual.coverage_start_date)
          xml.CoverageEndDt date_formatter(individual.coverage_termination_date)
        end
      end
    end

    private

    def date_formatter(date)
      return if date.nil?
      Date.strptime(date,'%m/%d/%Y').strftime("%Y-%m-%d")
    end

  end
end