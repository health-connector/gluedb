# frozen_string_literal: true

# This rake tasks should be run to generate reports after plans loading.
# To generate all reports please use this rake command: RAILS_ENV=production bundle exec rake cca_plan_validation:reports["2019-12-01"]
require 'rubyXL'
require 'rubyXL/convenience_methods'

namespace :cca_plan_validation do

  def generate_excel(headers, worksheet)
    h = 0
    headers.each do |header|
      worksheet.add_cell(0, h, header)
      h += 1
    end
  end

  def generate_data(worksheet, data, count)
    j = 0
    data.each do |info|
      worksheet.add_cell(count, j, info)
      j += 1
    end
    worksheet
  end

  desc "reports generation after plan loading"
  task :reports, [:active_date] => :environment do |_task, args|
    puts "Reports generation started" unless Rails.env.test?
    active_date = args[:active_date].to_date
    active_year = active_date.year
    workbook = RubyXL::Workbook.new

    #Report1: Details about Plan Count by Carrier, Coverage and Tier
    worksheet = workbook[0]
    worksheet.sheet_name = 'Report1'
    headers = %w[PlanYearId CarrierId CarrierName PlanTypeCode Tier Count]
    generate_excel(headers, worksheet)
    a = 1
    plans = Plan.where(year: active_year)
    plans.no_timeout.each do |plan|
      begin
        carrier_id = plan.hios_plan_id[0..4]
        carrier_name = plan.carrier.abbrev
        plan_type_code = plan.coverage_type == "health" ? "QHP" : "QDP"
        tier = plan.metal_level
        count = Carrier.where(id: plan.carrier_id).first.plans.where(year: active_year, metal_level: tier).count
        data = [active_year, carrier_id, carrier_name, plan_type_code, tier, count.to_s]
        generate_data(worksheet, data, a)
        a += 1
      rescue Exception => e
        puts "Report1 Plan validation issue for plan_id: #{plan.id}, #{e.message}"
      end
    end
    puts "Successfully generated Plan validation Report1"

    #Report2: Rating Area and Age Based Plan Rate Sum
    worksheet2 = workbook.add_worksheet('Report2')
    headers = %w[PlanYearId CarrierId CarrierName Age Sum]
    generate_excel(headers, worksheet2)
    b = 1
    Carrier.all.each do |carrier|
      begin
        next if carrier.plans.where(year: active_year).count < 1
        carrier_name = carrier.name
        carrier_id = carrier.plans.first.hios_plan_id[0..4]
        plans = carrier.plans.where(year: active_year)
        premium_tables = plans.map(&:premium_tables).flatten.select do |prem_table|
          start_date = prem_table.rate_start_date.to_date
          end_date = prem_table.rate_end_date.to_date
          (start_date..end_date).cover?(active_date)
        end
        (0..120).each do |age|
          age_cost = premium_tables.select{|a|a.age == age}.map(&:amount).sum
          data = [active_year, carrier_id, carrier_name, age, age_cost.round(2).to_s]
          generate_data(worksheet2, data, b)
          b += 1
        end
      rescue Exception => e
        puts "Report2 Plan validation issue for carrier_name: #{carrier_name}, #{e.message}"
      end
    end
    puts "Successfully generated Plan validation Report2"

    current_date = Date.today.strftime("%Y_%m_%d")
    file_name = "#{Rails.root}/CCA_PlanLoadValidation_Report_GDB_#{current_date}.xlsx"
    workbook.write(file_name)

    upload_to_s3 = Aws::S3Storage.new
    uri = upload_to_s3.save(file_path: filename, options: { internal_artifact: true})
    upload_to_s3.publish_to_sftp(filename,"Legacy::PushGluePlanValidationReport", uri)
    timey2 = Time.now
    puts "Report ended at #{timey2}"
  end
end
