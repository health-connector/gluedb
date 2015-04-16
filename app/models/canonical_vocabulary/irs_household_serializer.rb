require 'net/http'

module CanonicalVocabulary
  class IrsHouseholdSerializer

    CV_API_URL = "http://localhost:3000/api/v1/"

    NS = { 
      "xmlns"     => "urn:us:gov:treasury:irs:common",
      "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
      "xmlns:n1"  => "urn:us:gov:treasury:irs:msg:sbmpolicylevelenrollment"
    }
    
    def serialize
      builder.to_xml
    end

    def builder
      Nokogiri::XML::Builder.new do |xml|
        xml['n1'].HealthExchange(NS) do
          xml.SubmissionYr 1000
          xml.SubmissionMonthNum 1
          xml.ApplicableCoverageYr 1000
          xml.IndividualExchange do |xml|
            xml.HealthExchangeId "00.AA*.000.000.000"
            group_xml = Net::HTTP.get(URI.parse("#{CV_API_URL}families/5431b03feb899a49e0000004?user_token=zUzBsoTSKPbvXCQsB4Ky"))
            app_group_xml = Nokogiri::XML(group_xml).root
            @app_group = Parsers::Xml::Reports::Family.new(app_group_xml)
            next if @app_group.individual_policies.empty?
            serialize_irs_household_grp(xml)
          end
        end
      end
    end
    
    def serialize_irs_household_grp(xml)
      xml.IRSHouseholdGrp do |xml|
        xml.IRSGroupIdentificationNum
        @individual_policies = []
        @app_group.irs_households.each do |household|
          serialize_taxhousehold(xml, household)
          serialize_insurance_policies(xml)
        end
      end
    end
    
    def serialize_insurance_policies(xml)
      @individual_policies.uniq.each do |policy|
        xml.InsurancePolicy do |xml|
          xml.InsuranceCoverage do |xml|
            xml.ApplicableCoverageMonthNum 1
            xml.QHPPolicyNum "00000000000000000000000000000000000000000000000000"
            xml.QHPId policy.qhp_id
            xml.PediatricDentalPlanPremiumInd "N"
            xml.QHPIssuerEIN "000000000"
            xml.IssuerNm "Issuer"
            xml.PolicyCoverageStartDt date_formatter(policy.start_date)
            xml.PolicyCoverageEndDt date_formatter(policy.end_date)
            xml.TotalQHPMonthlyPremiumAmt policy.total_monthly_premium
            xml.APTCPaymentAmt policy.household_aptc
            serialize_policy_individuals(xml, policy)
          end
        end
      end
    end

    def serialize_policy_individuals(xml, policy)
      policy.individuals.each do |individual_xml|
        xml.CoveredIndividual do |xml|
          xml.InsuredPerson do |xml|
            individual = Parsers::Xml::Reports::Individual.new(individual_xml.at_xpath("n1:individual"))
            serialize_name_ssn_dob(xml, individual)
          end
          xml.CoverageStartDt date_formatter(individual_xml.at_xpath("n1:benefit/n1:begin_date").text)
          if individual_xml.at_xpath("n1:benefit/n1:end_date")
            end_date = individual_xml.at_xpath("n1:benefit/n1:end_date").text
          end
          xml.CoverageEndDt date_formatter(end_date)
        end
      end
    end

    def serialize_taxhousehold(xml, household=nil)       
      household = Parsers::Xml::Reports::Household.new(household)
      xml.TaxHousehold do |xml|
        xml.TaxHouseholdCoverage do |xml|
          xml.ApplicableCoverageMonthNum 1
          xml.Household do |xml|
            serialize_household_members(xml, household)
            serialize_associated_policies(xml, household)
          end
        end
      end
    end

    def serialize_household_members(xml, household)
      family_members_xml = @app_group.family_members_xml
      primary_xml = family_members_xml[household.primary]
      individual = Parsers::Xml::Reports::Individual.new(primary_xml)
      serialize_individual(xml, individual)

      serialize_members = Proc.new do |xml, members|
        members.each do |key, val|
          family_member_xml = family_members_xml[key]
          individual = Parsers::Xml::Reports::Individual.new(family_member_xml)
          serialize_individual(xml, individual, val.camelcase)
        end
      end

      serialize_members.call(xml, household.spouse)
      serialize_members.call(xml, household.dependents)     
    end
    
    def serialize_associated_policies(xml, household)
      policies = []
      household.all_members.each{|member| policies << @app_group.individual_policy_holders[member]}

      policy_ids = []
      policies.flatten.uniq.each do |policy|
        if @app_group.individual_policies.include?(policy)
          policy_ids << policy.match(/\d+$/)[0]
        end
      end

      policies_xml = Net::HTTP.get(URI.parse("#{CV_API_URL}policies?ids[]=#{policy_ids.join("&ids[]=")}&user_token=zUzBsoTSKPbvXCQsB4Ky"))
      parser = Nokogiri::XML(policies_xml).root
      parser.xpath("n1:policy").each do |policy_xml|
        policy = Parsers::Xml::Reports::Policy.new(policy_xml)
        serialize_policy(xml, policy)
        @individual_policies << policy
      end
    end
    
    def serialize_policy(xml, policy)
      xml.AssociatedPolicy do |xml|
        xml.QHPPolicyNum "00000000000000000000000000000000000000000000000000"
        xml.QHPIssuerEIN "000000000"
        xml.PediatricDentalPlanPremiumInd "N"
        xml.SLCSPAdjMonthlyPremiumAmt 0
        xml.HouseholdAPTCAmt policy.household_aptc
        xml.TotalHsldMonthlyPremiumAmt policy.total_monthly_premium			
      end
    end
    
    def serialize_individual(xml, individual, relation="Primary")
      xml.send("#{relation}Grp") do |xml|
        xml.send(relation) do |xml|
          serialize_name_ssn_dob(xml, individual)
          next unless relation == "Primary"
          individual.addresses.each{|address| serialize_address(xml, address)}
        end
        individual.employers.each do |employer_url|
          employer_xml = Net::HTTP.get(URI.parse("#{employer_url}?user_token=zUzBsoTSKPbvXCQsB4Ky"))
          employer = Parsers::Xml::Reports::Employer.new(employer_xml)
          serialize_employer(xml, employer)
        end
      end
    end
    
    def serialize_name_ssn_dob(xml, individual)
      xml.CompletePersonName do |xml|
        xml.PersonFirstName individual.name_first
        xml.PersonMiddleName individual.name_middle
        xml.PersonLastName individual.name_last
        xml.SuffixName individual.name_suffix
      end   
      xml.SSN individual.ssn
      xml.BirthDt individual.dob
    end
    
    def serialize_employer(xml, employer)
      xml.EmployerMEC do |xml|
        xml.EIN employer.ein
        xml.BusinessName do |xml|
          xml.BusinessNameLine1 employer.name
          xml.BusinessNameLine2
        end
        xml.BusinessAddressGrp do |xml|
          employer.addresses.each{|address| serialize_address(xml, address)}
        end
        xml.MECStatusInd "Y"
      end
    end
    
    def serialize_address(xml, address)
      xml.USAddressGrp do |xml|
        xml.AddressLine1Txt address[:address_1]
        xml.AddressLine2Txt address[:address_2]
        xml.CityNm address[:city]
        xml.USStateCd address[:state]
        xml.USZIPCd address[:postal_code]
        xml.USZIPExtensionCd "0000"
      end			
    end

    def date_formatter(date)
       return if date.nil?
       Date.strptime(date,'%Y%m%d').strftime("%Y-%m-%d")
    end
  end
end
