require "spreadsheet"
module CanonicalVocabulary
	module Renewals

    class PolicyProjection
      attr_reader :current, :future_plan_name, :quoted_premium
      def initialize(app_group, coverage_type)
        @coverage_type = coverage_type
        policy_builder = CanonicalVocabulary::Renewals::PolicyBuilder.new(app_group)
        @current = policy_builder.current_insurance_plan(coverage_type)
        @future = policy_builder.future_insurance_plan(coverage_type)
        @quoted_premium = policy_builder.quoted_insurance_premium(coverage_type)
        @future_plan_name = future_plan_name_by_hios(@future)
      end

      def future_plan_name_by_hios(hios_id)
        hios_ids = {
          "health" => {
            "77422DC0060002" => "Aetna Bronze $20 Copay",
            "77422DC0060004" => "Aetna Bronze Deductible Only HSA Elgible",
            "77422DC0060005" => "Aetna Catastrophic 100%",
            "77422DC0060006" => "Aetna Gold $5 Copay",
            "77422DC0060010" => "Aetna Silver $5 Copay 2750",
            "77422DC0060008" => "Aetna Silver $10 Copay",
            "78079DC0160001" => "BlueCross BlueShield Preferred 500, A Multi-State Plan",
            "78079DC0180001" => "BlueCross BlueShield Preferred 1500, A Multi-State Plan",
            "78079DC0200001" => "BluePreferred HSA Bronze",
            "78079DC0210001" => "BluePreferred Platinum $0",
            "86052DC0400001" => "BlueChoice Silver $2,000",
            "86052DC0400002" => "BlueChoice Gold $0",
            "86052DC0400003" => "BlueChoice Gold $1,000",
            "86052DC0400004" => "BlueChoice Young Adult $6,600",
            "86052DC0410001" => "BlueChoice HSA Bronze $4,000",
            "86052DC0410002" => "BlueChoice HSA Bronze $6,000",
            "86052DC0410003" => "BlueChoice HSA Silver $1,300",
            "86052DC0420001" => "BlueChoice Plus Bronze $5,500",
            "86052DC0420002" => "BlueChoice Plus Silver $2,500",
            "86052DC0430001" => "HealthyBlue Gold $1,500",
            "86052DC0430002" => "HealthyBlue Platinum $0",
            "94506DC0390001" => "KP DC Platinum 0/10/Dental/Ped Dental",
            "94506DC0390002" => "KP DC Gold 0/20/Dental/Ped Dental",
            "94506DC0390003" => "KP DC Gold 1000/20/Dental/Ped Dental",
            "94506DC0390004" => "KP DC Silver 1500/30/Dental/Ped Dental",
            "94506DC0390005" => "KP DC Silver 2500/30/Dental/Ped Dental",
            "94506DC0390006" => "KP DC Silver 1750/25%/HSA/Dental/Ped Dental",
            "94506DC0390007" => "KP DC Bronze 4500/50/Dental/Ped Dental",
            "94506DC0390008" => "KP DC Catastrophic 6600/0/Dental/ Ped Dental",
            "94506DC0390009" => "KP DC Bronze 4500/50/HSA/Dental/Ped Dental",
            "94506DC0390010" => "KP DC Bronze 5000/30%/HSA/Dental/Ped Dental"
          },
          "dental" => {
            "78079DC0320002" => "BlueDental Preferred - Low Option",
            "95051DC0020003" => "BESTOne Dental Advantage-High",  
            "95051DC0020004" => "BESTOne Dental Plus-High",  
            "95051DC0020005" => "BESTOne Dental Plus-Low",  
            "95051DC0020006" => "BESTOne Dental Basic-Low",  
            "81334DC0010004" => "Delta Dental Individual & Family Delta Dental PPO Preferred Plan for Families", 
            "81334DC0010006" => "Delta Dental Individual & Family Delta Dental PPO Basic Plan for Families",  
            "81334DC0030004" => "Delta Dental Individual & Family DeltaCare USA Preferred Plan for Families",  
            "81334DC0030006" => "Delta Dental Individual & Family DeltaCare USA Basic Plan for Families",  
            "92479DC0010002" => "Select Plan",  
            "92479DC0020002" => "Access PPO",  
            "96156DC0010004" => "Dentegra Dental PPO Family Preferred Plan",  
            "96156DC0010006" => "Dentegra Dental PPO Family Basic Plan"
          }
        } 
        hios_ids[@coverage_type][hios_id]
      end
    end

		class RenewalReport
      
      CV_API_URL = "http://localhost:3000/api/v1/"

      def initialize(options)
        @book  = Spreadsheet::Workbook.new
        @sheet = book.create_worksheet :name => 'Manual Renewal'
        @renewal_logger = Logger.new("#{Rails.root}/log/#{options[:log_file]}")
        @file  = options[:file]
        @row = 1
      end
      
      def setup(application_group)
        @application_group = application_group

        # individuals = find_many_individuals_by_id(@application_group.applicant_person_ids)
        # @primary = individuals.detect { |i| (i.id == @application_group.primary_applicant_id || individuals.count == 1) }
        @primary = @application_group.primary_applicant
        raise "Primary Applicant Address Not Present" if @primary.person.addresses.empty?

        @other_members = @application_group.applicants.reject { |i| i == @primary }

        @dental = PolicyProjection.new(@application_group, "dental")
        @health = PolicyProjection.new(@application_group, "health")

        if @health.current.nil? && @dental.current.nil?
          raise "No active health or dental policy"
        end
      end

      def append_household(application_group)
        begin
          setup(application_group)
          build_report
        rescue Exception  => e
          @renewal_logger.info "#{application_group.id.match(/\w+$/)},#{e.inspect}"
        end
      end

      private

      def find_many_individuals_by_id(ids)
        members_xml = Net::HTTP.get(URI.parse("#{CV_API_URL}people?ids[]=#{ids.join("&ids[]=")}&user_token=zUzBsoTSKPbvXCQsB4Ky"))
        individual_elements = Nokogiri::XML(members_xml).root.xpath("n1:individual")
        individual_elements.map { |i| Parsers::Xml::Reports::Individual.new(i) }
      end

      def num_blank_members
        @other_members_limit - @other_members.count
      end
    end
  end
end
