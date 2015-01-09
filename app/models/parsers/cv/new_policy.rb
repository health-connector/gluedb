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
        @plan_year ||= Maybe.new(@xml.at_xpath("cv:enrollment/cv:plan/cv:plan_year",namespaces)).content.value
      end

      def tot_res_amt
        @tot_res_amount ||= Maybe.new(@xml.at_xpath("cv:enrollment/cv:total_responsible_amount",namespaces)).content.split("#").last.value || 0.00
      end

      def pre_amt_tot
        @pre_amt_tot ||= Maybe.new(@xml.at_xpath("cv:enrollment/cv:premium_total_amount",namespaces)).content.split("#").last.value || 0.00
      end

      def tot_emp_res_amt
        @tot_emp_res_amt ||= Maybe.new(@xml.at_xpath("cv:enrollment/cv:shop_market/cv:total_employer_responsible_amount",namespaces)).content.value || 0.00
      end

      def employer_fein
        @employer_fein ||= Maybe.new(@xml.at_xpath("cv:enrollment/cv:shop_market/cv:employer_link/cv:id/cv:id",namespaces)).content.split("#").last.value
      end

      def applied_aptc
        @applied_aptc ||= Maybe.new(@xml.at_xpath("cv:enrollment/cv:individual_market/cv:applied_aptc_amount",namespaces)).content.split("#").last.value || 0.00
      end

      def carrier_to_bill
        @carrier_to_bill ||= Maybe.new(@xml.at_xpath("cv:enrollment/cv:individual_market/cv:is_carrier_to_bill",namespaces)).content.split("#").last.value
      end

      def enrollees
        @enrollees ||= @xml.xpath("cv:enrollees/cv:enrollee",namespaces).map do |node|
          ::Parsers::Cv::Enrollee.new(node)
        end
      end

      def employer_id_uri
        @employer_id_uri ||= Maybe.new(@xml.at_xpath("cv:enrollment/cv:shop_market/cv:employer_link/cv:id/cv:id",namespaces)).content.value
      end

      def employer_id
        @employer_id ||= Maybe.new(@xml.at_xpath("cv:enrollment/cv:shop_market/cv:employer_link/cv:id/cv:id",namespaces)).content.split("/").last.value
      end

      def broker_npn
        @broker_npn ||= Maybe.new(@xml.at_xpath("cv:broker/cv:id/cv:id", namespaces)).first.content.split("#").last.value
      end

      def employer_id=(value)
        @employer_id = value
      end

      def to_hash
        { 
          :enrollment_group_id => enrollment_group_id,
          :hios_id => hios_id,
          :plan_year => plan_year,
          :tot_res_amt => tot_res_amt,
          :pre_amt_tot => pre_amt_tot,
          :applied_aptc => applied_aptc,
          :carrier_to_bill => carrier_to_bill,
          :broker_npn => broker_npn,
          :employer_fein => employer_fein,
          :tot_emp_res_amt => tot_emp_res_amt,
          :enrollees => enrollees.map(&:to_hash),
          :employer_id => employer_id,
          :employer_id_uri => employer_id_uri
        }
      end
    end
  end
end
