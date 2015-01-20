module Parsers::Xml::Reports
  class ApplicationGroup
    
    attr_reader :individual_policy_holders

    RENEWAL_DATE = Date.parse("2015-1-1")

    def initialize(parser = nil)
      # parser = File.open(Rails.root.to_s + "/sample_xmls/application_group_address.xml")
      # parser = Nokogiri::XML(parser).root
      @root = parser
      @individual_policy_holders = {}
      @quotes_for_applicants = {}
      @future_plans_by_coverage = {}
      @policy_details = {}
      populate_individual_policies
      policies_details
    end

    def id
      @root.at_xpath("n1:id").text
    end

    def family_members
      @root.xpath("n1:applicants/n1:applicant")
    end

    def applicant_person_ids
      family_members.map {|e| e.at_xpath("n1:person/n1:id").text.match(/\w+$/)[0]}.uniq
    end

    def primary_applicant_id
      @root.at_xpath("n1:primary_applicant_id").text
    end

    # TODO: need to confirm applicants can't have duplicates
    def size
      @root.xpath("n1:applicants/n1:applicant").count
    end

    def integrated_case
      node = @root.at_xpath("n1:e_case_id")
      node.nil? ? nil : @root.at_xpath("n1:e_case_id").text 
    end

    def irs_households
    	@root.xpath("n1:households/n1:household")
    end

    def yearly_income(year)
      incomes = irs_households.xpath("n1:total_incomes/n1:total_income")
      income = incomes.detect{|income| income.at_xpath("n1:calendar_year").text == year }
      income.nil? ? 0.0 : sprintf("%.2f", income.at_xpath("n1:total_income").text.to_f)
    end

    def irs_consent
      node = @root.at_xpath("n1:coverage_renewal_year")
      node.nil? ? nil : @root.at_xpath("n1:coverage_renewal_year").text
    end
    
    def current_insurance_plan(coverage)
      @policy_details.detect{|id, policy| policy[:coverage_type] == coverage }
    end

    def future_insurance_plan(coverage)
      @future_plans_by_coverage[coverage]
    end
    
    def quoted_insurance_premium(coverage)
      @quotes_for_applicants.values.inject(0.0) do |premium, quote| 
        premium + quote[coverage].to_f
      end
    end

    def individual_policies
      @individual_policy_holders.values.flatten.uniq
    end

    def populate_individual_policies
      @root.xpath("n1:applicants/n1:applicant").each do |applicant|
        applicant_link = ApplicantLinkType.new(applicant)
        calc_individual_policies(applicant_link)
        calc_policy_quotes(applicant_link)
      end
    end

    def calc_individual_policies(applicant_link)
      individual_policies = []
      applicant_link.policies.each do |policy| 
        policy_link = PolicyLinkType.new(policy)
        if policy_link.individual_market? && policy_link.state == 'active'
          individual_policies << policy_link.id
        end
      end
      @individual_policy_holders[applicant_link.person_id] = individual_policies.uniq
    end

    def calc_policy_quotes(applicant_link)
      quotes = {}
      applicant_link.qhp_quotes.each do |quote|
        quote_link = QuoteLinkType.new(quote)
        coverage = quote_link.coverage_type
        next if @future_plans_by_coverage[coverage]       
        quotes[coverage] = quote_link.rate
        @future_plans_by_coverage[coverage] = quote_link.qhp_id
      end
      @quotes_for_applicants[applicant_link.person_id] = quotes
    end

    def policies_details     
      policy_ids = individual_policies.map{|policy| policy.match(/\d+$/)[0]}
      policies_xml = Net::HTTP.get(URI.parse("http://localhost:3000/api/v1/policies?ids[]=#{policy_ids.join("&ids[]=")}&user_token=zUzBsoTSKPbvXCQsB4Ky"))
      root = Nokogiri::XML(policies_xml).root
      root.xpath("n1:policy").each do |policy|
        policy = Parsers::Xml::Reports::Policy.new(policy)
        @policy_details[policy.id] = {
          :plan => policy.plan,
          :begin_date => policy.start_date,
          :end_date => policy.end_date,
          :elected_aptc => policy.elected_aptc,
          :coverage_type => policy.coverage_type,
          :qhp_id => policy.qhp_number
        }
      end
    end
  end
end
