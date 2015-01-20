module CanonicalVocabulary
  module Renewals

    class PolicyBuilder
      def initialize(application_group)
        @family = application_group
        generate_policy_details
      end

      def current_insurance_plan(coverage)
        current_plan = @policy_details.detect{|id, policy| policy.coverage_type == coverage }
        current_plan.nil? ? nil : current_plan[1]
      end

      def generate_policy_details
        policy_ids = @family.policies_enrolled
        renewals_xml = Net::HTTP.get(URI.parse("http://localhost:3000/api/v1/renewal_policies?ids[]=#{policy_ids.join("&ids[]=")}&user_token=zUzBsoTSKPbvXCQsB4Ky"))
        renewals = Nokogiri::XML(policies_xml).root.xpath("n1:renewal_policy")
        # renewals = [ File.open(Rails.root.to_s + "/renewal_772.xml") ]
        @policy_details = renewals.inject({}) do |policy_details, renewal_xml|
          renewal = Parsers::Xml::Cv::Renewal.parse(renewal_xml)
          current_plan = renewal.current_policy.enrollment.plan
          policy_details[renewal.current_policy.id] = OpenStruct.new({
            :plan_name => current_plan.name,
            :coverage_type => current_plan.coverage_type.split('#')[1],
            :future_plan_name => renewal.renewal_policy.enrollment.plan.name,
            :quoted_premium => renewal.renewal_policy.enrollment.premium_amount_total
          })
          policy_details
        end
      end
    end
  end
end