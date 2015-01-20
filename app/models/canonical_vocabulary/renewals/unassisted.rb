module CanonicalVocabulary
  module Renewals
    class Unassisted < RenewalReport

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
        "Zip",
        "Age 1",
        "Residency 1",
        "Citizenship 1",
        "Incarcerated 1"
      ]

      POLICY_COLUMNS = [   
        "Response Date",
        "2014 Health Plan", 
        "2015 Health Plan",
        "2015 Health Plan Premium",
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

      # repeated for each Unassisted Household member
      def member_columns(limit)
        (2..(limit+1)).inject([]) do |columns, n|
          columns += [
            "P#{n} First",
            "P#{n} Last",
            "Age #{n}",
            "Residency #{n}",
            "Citizenship #{n}",
            "Incarcerated #{n}"
          ]
        end
      end

      def build_report
        builder = RenewalReportRowBuilder.new(@family, @primary)

        builder.append_integrated_case_number
        builder.append_notice_date("10/10/2014")

        builder.append_name_of(@primary)
        builder.append_household_address
        builder.append_age_of(@primary)
        builder.append_residency_of(@primary)
        builder.append_citizenship_of(@primary)
        builder.append_incarcerated(@primary)

        @other_members.each do  |m|  
          builder.append_name_of(individual)
          builder.append_age_of(individual)
          builder.append_residency_of(individual)
          builder.append_citizenship_of(individual)
          builder.append_incarcerated(individual)
        end

        num_blank_members.times do 
          6.times{ builder.append_blank }
        end

        builder.append_response_date("10/10/2014")
        builder.append_policy(@health)
        builder.append_policy(@dental)
        @sheet.row(@row).concat builder.data_set
        @row += 1 
      end
    end
  end
end
