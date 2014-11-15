module Parsers
  module Cv
    class NewPolicy
      include Namespaces

      def initialize(node)
        @xml = node
      end

      def enrollment_group_id
        @enrollment_group_id ||= Maybe.new(@xml.at_xpath("cv:id/cv:id",namespaces)).content.split("#").last.value
      end

      def hios_id
        @hios_id ||= Maybe.new(@xml.at_xpath("cv:enrollment/cv:plan/cv:id/cv:id",namespaces)).content.split("#").last.value
      end

      def plan_year
        @plan_year ||= Maybe.new(@xml.at_xpath("cv:enrollment/cv:plan/cv:plan_year",namespaces)).content.split("#").last.value
      end

      def tot_res_amt
        @tot_res_amount ||= Maybe.new(@xml.at_xpath("cv:enrollment/cv:plan/cv:total_responsible_amount",namespaces)).content.split("#").last.value || "0.0"
      end

      def pre_amt_tot
        @pre_amt_tot ||= Maybe.new(@xml.at_xpath("cv:enrollment/cv:plan/cv:premium_total_amount",namespaces)).content.split("#").last.value || "0.0"
      end

      def applied_aptc
        @applied_aptc ||= Maybe.new(@xml.at_xpath("cv:enrollment/cv:plan/cv:individual_market/cv:applied_aptc_amount",namespaces)).content.split("#").last.value || "0.0"
      end

      def carrier_to_bill
        @carrier_to_bill ||= Maybe.new(@xml.at_xpath("cv:enrollment/cv:plan/cv:individual_market/cv:is_carrier_to_bill",namespaces)).content.split("#").last.value
      end



      def to_hash
        { 
          :enrollment_group_id => enrollment_group_id,
          :hios_id => hios_id,
          :plan_year => plan_year,
          :tot_res_amt => tot_res_amt,
          :pre_amt_tot => pre_amt_tot,
          :applied_aptc => applied_aptc,
          :carrier_to_bill => carrier_to_bill
        }
      end
    end
  end
end
