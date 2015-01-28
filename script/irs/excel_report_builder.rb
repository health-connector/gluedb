require 'spreadsheet'
require 'csv'

module Irs
  class ExcelReportBuilder

    def build_1095a_report(file)
      workbook = Spreadsheet::Workbook.new
      sheet = workbook.create_worksheet :name => 'Multi Assisted QHP'
      index = 1

      columns = ['POLICY ID']
      5.times {|i| columns += ["NAME#{i+1}", "SSN#{i+1}", "DOB#{i+1}", "BEGINDATE#{i+1}", "ENDDATE#{i+1}"]}
      12.times {|i| columns += ["PREMIUM#{i+1}", "SLCSP#{i+1}", "APTC#{i+1}"]}
      sheet.row(0).concat columns

      CSV.foreach("#{Rails.root}/1095as_filtered.csv") do |row|
        policy = Policy.find(row[0].strip)
        begin
          next if policy.applied_aptc == 0
          active_enrollees = policy.enrollees.reject{|en| en.canceled?}
          next if active_enrollees.empty? || active_enrollees.size == 1
          @notice = Generators::Reports::IrsInputBuilder.new(policy).notice
          build_1095a_row
          sheet.row(index).concat @data
        rescue Exception => e
          puts policy.id
        end
        index += 1
      end

      workbook.write "#{Rails.root.to_s}/#{file}"
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