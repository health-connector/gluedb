module CanonicalVocabulary
  module Renewals
    class AssistedNov < RenewalReport

      PRIMARY_COLUMNS = [
        "IC Number",
        "Date of Notice", 
        "Primary First",
        "Primary Last",
        "Primary Street 1",
        "Primary Street 2",
        "Apt",
        "City",
        "State",
        "Zip"
      ]

      POLICY_COLUMNS = [   
        "APTC",
        "2014 Health Plan", 
        "2015 Health Plan",
        "2015 Health Plan Premium",
        "HP Premium After APTC",
        "2014 Dental Plan", 
        "2015 Dental Plan",
        "2015 Dental Plan Premium"
      ]
      
      attr_accessor :book, :file

      def initialize(options)
        super
        columns = PRIMARY_COLUMNS
        @other_members_limit = options[:other_members]
        columns += member_columns(@other_members_limit)
        @sheet.row(0).concat  columns + POLICY_COLUMNS
      end

      # Repeated for each IA household member
      def member_columns(limit)
        (2..(limit+1)).inject([]) do |columns, n|
          columns += [
            "P#{n} First",
            "P#{n} Last"
          ]
        end
      end

      def build_report
        builder = RenewalReportRowBuilder.new(@application_group, @primary)

        builder.append_integrated_case_number
        builder.append_notice_date("10/10/2014")
        builder.append_name_of(@primary)
        builder.append_household_address

        @other_members.each do |individual|  
          builder.append_name_of(individual)
        end

        num_blank_members.times do 
          6.times{ builder.append_blank }
          4.times{ builder.append_blank }
        end

        builder.append_aptc
        builder.append_policy(@health)
        builder.append_post_aptc_premium
        builder.append_policy(@dental)
        @sheet.row(@row).concat builder.data_set
        @row += 1 
      end
    end
  end
end
