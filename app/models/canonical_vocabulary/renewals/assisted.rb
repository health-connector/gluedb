require "spreadsheet"
module CanonicalVocabulary
  module Renewals
    class Assisted < RenewalReport

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
        "Tax Status 1",
        "MEC 1",
        "HH Size 1",
        "Projected Income 1",
        "Incarcerated 1"
      ]

      POLICY_COLUMNS = [   
        "APTC",
        "Response Date",
        "2014 Health Plan", 
        "2015 Health Plan",
        "2015 Health Plan Premium",
        "HP Premium After APTC",
        "2014 Dental Plan", 
        "2015 Dental Plan",
        "2015 Dental Plan Premium",
        "HH Total Income",  
        "CSR Eligibility",
        "IRS Consent"
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
            "P#{n} Last",
            "Age #{n}",
            "Residency #{n}",
            "Citizenship #{n}",
            "Tax Status #{n}",
            "MEC #{n}",
            "HH Size #{n}",
            "Projected Income #{n}",
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
        builder.append_tax_status_of(@primary)
        builder.append_mec_of(@primary)
        builder.append_app_group_size
        builder.append_yearwise_income_of(@primary)
        builder.append_incarcerated(@primary)

        @other_members.each do |individual|  
          builder.append_name_of(individual)
          builder.append_age_of(individual)
          builder.append_residency_of(individual)
          builder.append_citizenship_of(individual)
          builder.append_tax_status_of(individual)
          builder.append_mec_of(individual)
          builder.append_app_group_size
          builder.append_yearwise_income_of(individual)
          builder.append_incarcerated(individual)
        end

        num_blank_members.times do 
          6.times{ builder.append_blank }
          4.times{ builder.append_blank }
        end

        builder.append_aptc
        builder.append_response_date("10/10/2014")
        builder.append_policy(@health)
        builder.append_post_aptc_premium
        builder.append_policy(@dental)
        builder.append_financials
        @sheet.row(@row).concat builder.data_set
        @row += 1 
      end
    end
  end
end
