# frozen_string_literal: true

require 'rubyXL'
require 'rubyXL/convenience_methods'

module Services
  class PlanValidationReport

    attr_accessor :workbook, :active_date, :active_year

    def initialize(active_date)
      @workbook = RubyXL::Workbook.new
      @active_date = active_date
      @active_year = active_date.year
    end

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

    def generate_file(file_name)
      workbook.write(file_name)
      puts "Successfully reports generation process completed" unless Rails.env.test?
    end

    def sheet1
      worksheet = workbook[0]
      worksheet.sheet_name = 'Report1'
      headers = %w[PlanYearId CarrierId CarrierName PlanTypeCode Tier Count]
      generate_excel(headers, worksheet)
      a = 1
      hios_plan_ids = Plan.where(year: active_year).map{|a| a.hios_plan_id[0..4]}.uniq
      hios_plan_ids.each do |hios_plan_id|
        ["platinum", "gold", "bronze", "silver", "dental"].each do |metal_level|
          begin
            plans = Plan.where(year: active_year, hios_plan_id: /#{hios_plan_id}/i, metal_level: metal_level)
            next if plans.count < 1
            carrier_name = plans.first.carrier.abbrev
            plan_type_code = plans.first.coverage_type == "health" ? "QHP" : "QDP"
            data = [active_year, hios_plan_id, carrier_name, plan_type_code, metal_level, plans.count.to_s]
            generate_data(worksheet, data, a)
            a += 1
          rescue Exception => e
            puts "Report1 Plan validation issue for hios_plan_id: #{hios_plan_id}, #{e.message}" unless Rails.env.test?
          end
        end
      end
      puts "Successfully generated Plan validation Report1" unless Rails.env.test?
    end

    def sheet2
      worksheet2 = workbook.add_worksheet('Report2')
      headers = %w[PlanYearId CarrierId CarrierName Age(Range) IndividualRate]
      generate_excel(headers, worksheet2)
      b = 1
      hios_plan_ids = Plan.where(year: active_year).map{|a| a.hios_plan_id[0..4]}.uniq
      hios_plan_ids.each do |hios_plan_id|
        begin
          plans = Plan.where(year: active_year, hios_plan_id: /#{hios_plan_id}/i)
          next if plans.count < 1
          carrier_name = plans.first.carrier.name
          premium_tables = plans.map(&:premium_tables).flatten.select do |prem_table|
            start_date = prem_table.rate_start_date.to_date
            end_date = prem_table.rate_end_date.to_date
            (start_date..end_date).cover?(active_date)
          end
          (14..64).each do |age|
            age_cost = premium_tables.select{|a|a.age == age}.map(&:amount).sum
            [active_year, hios_plan_id, carrier_name, age == 14 ? "0-14" : (age == 64 ? "64 and over" : age), age_cost.round(2).to_s]
            generate_data(worksheet2, data, b)
            b += 1
          end
        rescue Exception => e
          puts "Report2 Plan validation issue for hios_plan_id: #{hios_plan_id}, #{e.message}" unless Rails.env.test?
        end
      end
      puts "Successfully generated Plan validation Report2" unless Rails.env.test?
    end
  end
end
