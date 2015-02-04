require 'spreadsheet'
require 'csv'

module Irs
  class ExcelReportBuilder

    def initialize
      @workbook = Spreadsheet::Workbook.new
      @sheet = @workbook.create_worksheet :name => 'report' 
    end

    def append_column_names
      columns = ['POLICY ID']
      5.times {|i| columns += ["NAME#{i+1}", "SSN#{i+1}", "DOB#{i+1}", "BEGINDATE#{i+1}", "ENDDATE#{i+1}"]}
      12.times {|i| columns += ["PREMIUM#{i+1}", "SLCSP#{i+1}", "APTC#{i+1}"]}
      @sheet.row(0).concat columns
    end

    def build_1095a_report(file)
      append_column_names
      index = 1
      CSV.foreach("#{Rails.root}/1095as_filtered.csv") do |row|
        policy = Policy.find(row[0].strip)
        begin
          next if policy.applied_aptc == 0
          active_enrollees = policy.enrollees.reject{|en| en.canceled?}
          next if active_enrollees.empty? || active_enrollees.size == 1
          @notice = Generators::Reports::IrsInputBuilder.new(policy).notice
          build_1095a_row
          @sheet.row(index).concat @data
        rescue Exception => e
          puts policy.id
        end
        index += 1
      end

      @workbook.write "#{Rails.root.to_s}/aptc_multiple_enrollees.xls"
    end

    def export_as_1095a(policies, file)
      append_column_names
      index = 1
      policies.each do |policy|
        begin
          active_enrollees = policy.enrollees.reject{|en| en.canceled?}
          next if active_enrollees.empty?
          @notice = Generators::Reports::IrsInputBuilder.new(policy).notice
          build_1095a_row
          @sheet.row(index).concat @data
        rescue Exception => e
          puts policy.id
        end
        index += 1
      end
      @workbook.write "#{Rails.root.to_s}/#{file}.xls"
    end


    def export_policy_versions(policies, file)
      columns = ['POLICY ID', "HBX Member Id", "Coverage Start", "Coverage End", "Member Count", "APTC"]
      5.times {|i| columns += ["V#{i+1} Coverage Start", "V#{i+1} Coverage End", "V#{i+1} Member Count", "V#{i+1} APTC"]}
      @sheet.row(0).concat columns

      index = 1
      policies.each do |policy|
        begin
          @data = [ 
            policy.id, 
            policy.subscriber.hbx_member_id, 
            policy.subscriber.coverage_start.strftime("%m-%d-%Y"), 
            policy.subscriber.coverage_end.blank? ? nil : policy.subscriber.coverage_end.strftime("%m-%d-%Y"),
            policy.enrollees.reject{|en| en.canceled?}.size,
            policy.applied_aptc
          ]

          policy.versions.each do |version|
            @data += [
              version.subscriber.coverage_start.strftime("%m-%d-%Y"),
              version.subscriber.coverage_end.blank? ? nil : version.subscriber.coverage_end.strftime("%m-%d-%Y") ,
              version.enrollees.reject{|en| en.canceled?}.size,
              version.applied_aptc
            ]
          end

          @sheet.row(index).concat @data
        rescue Exception => e
          puts policy.id
        end
        index += 1
      end
      @workbook.write "#{Rails.root.to_s}/#{file}.xls"
    end

    def build_1095a_row
      @data = [ @notice.policy_id ]
      append_coverage_household
      append_premiums
    end

    def append_covered_member(indiv)
      @data += [indiv.name, indiv.ssn, indiv.dob, indiv.coverage_start_date, indiv.coverage_termination_date]
    end

    def append_coverage_household
      @notice.covered_household.each do |indiv|
        append_covered_member(indiv)
      end
      (5 - @notice.covered_household.size).times{ append_blank_arr(5) }
    end

    def append_blank_arr(size)
      size.times{ @data << '' }
    end

    def append_premiums
      (1..12).each do |index|
        monthly_premium = @notice.monthly_premiums.detect{|p| p.serial == index}
        if monthly_premium.blank?
          append_blank_arr(3)
        else
          @data += [monthly_premium.premium_amount, monthly_premium.premium_amount_slcsp, monthly_premium.monthly_aptc]
        end
      end
    end
  end
end