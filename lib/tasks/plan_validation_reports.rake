# frozen_string_literal: true

# These rake tasks should be run to generate reports after plans loading.
# To run all reports please use this rake command: RAILS_ENV=production bundle exec rake plan_validation:reports["2020-01-01"]
require 'csv'

namespace :plan_validation do

  desc "reports generation after plan loading"
  task :reports, [:plan_year] => :environment do |task, args|
    puts "Reports generation started" unless Rails.env.test?
    puts "Reports generation started for Report1" unless Rails.env.test?
    Rake::Task['plan_validation:report1'].invoke(args[:plan_year])
    puts "Reports generation started for Report2" unless Rails.env.test?
    Rake::Task['plan_validation:report2'].invoke(args[:active_date])
  end

  #To run first report: RAILS_ENV=production bundle exec rake plan_validation:report1["2020-01-01"]
  desc "Details about Plan Count by Carrier, Coverage and Tier"
  task :report1, [:plan_year] => :environment do |_task, args|
    active_date = args[:active_date].to_date
    active_year = active_date.year
    CSV.open("#{Rails.root}/plan_loading_report1_#{active_year}.csv", "w", force_quotes: true) do |csv|
      csv << %w(Plan_year_ID Carrier_ID Carrier_Name Plan_Type_Code Tier Count)
      plans = Plan.where(year: active_year)
      plans.no_timeout.inject([]) do |_dummy, plan|
        carrier_id = plan.hios_plan_id
        carrier_name = plan.carrier.abbrev
        plan_type_code = plan.coverage_type == "health" ? "QHP" : "QDP"
        tier = plan.metal_level
        count = Carrier.where(abbrev: carrier_name).first.plans.where(year: active_year, metal_level: tier).count
        csv << [active_year, carrier_id, carrier_name, plan_type_code, tier, count]
      end
      puts "Successfully generated Plan validation Report1"
    end
  end

  #To run second report: RAILS_ENV=production bundle exec rake plan_validation:report2["2020-01-01"]
  desc "Rating Area and Age Based Plan Rate Sum"
  task :report2, [:active_date] => :environment do |_task, args|
    active_date = args[:active_date].to_date
    active_year = active_date.year
    CSV.open("#{Rails.root}/plan_validation_report2_#{active_year}.csv", "w", force_quotes: true) do |csv|
      csv << %w[PlanYearId CarrierId CarrierName Age Sum]
      Carrier.all.each do |carrier|
        begin
          next if carrier.plans.count < 1
          carrier_name = carrier.name
          carrier_id = carrier.plans.first.try(:hios_plan_id)[0..4]
          plans = carrier.plans.where(year: active_year)
          premium_tables = plans.map(&:premium_tables).flatten.select do |prem_table|
            start_date = prem_table.rate_start_date.to_date
            end_date = prem_table.rate_end_date.to_date
            (start_date..end_date).cover?(active_date)
          end
          (0..120).each do |age|
            age_cost = premium_tables.select{|a|a.age == age}.flatten.map(&:amount).sum
            csv << [active_year, carrier_id, carrier_name, age, age_cost.round(2)]
          end
        rescue Exception => e
          puts "#{e.message}, carrier_name: #{carrier_name}"
        end
      end
      puts "Successfully generated Plan validation Report2"
    end
  end
end
