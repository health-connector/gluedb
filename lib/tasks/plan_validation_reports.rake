# frozen_string_literal: true

# These rake tasks should be run to generate reports after plans loading.
# To run all reports please use this rake command: RAILS_ENV=production bundle exec rake plan_validation:reports['2020']
require 'csv'

namespace :plan_validation do

  desc "reports generation after plan loading"
  task :reports, [:plan_year] => :environment do |task, args|
    puts "Reports generation started" unless Rails.env.test?
    puts "Reports generation started for Report1" unless Rails.env.test?
    Rake::Task['plan_validation:report1'].invoke(args[:plan_year])
  end

  #To run first report: RAILS_ENV=production bundle exec rake plan_validation:report1['2020']
  desc "Details about Plan Count by Carrier, Coverage and Tier"
  task :report1, [:plan_year] => :environment do |task, args|
    CSV.open("#{Rails.root}/plan_loading_report1_#{args[:plan_year]}.csv", "w", force_quotes: true) do |csv|
      csv << %w(Plan_year_ID Carrier_ID Carrier_Name Plan_Type_Code Tier Count)
      plans = Plan.where(year: args[:plan_year])
      plans.no_timeout.inject([]) do |_dummy, plan|
        plan_year_id = plan.year
        carrier_id = plan.hios_plan_id
        carrier_name = plan.carrier.abbrev
        plan_type_code = plan.coverage_type == "health" ? "QHP" : "QDP"
        tier = plan.metal_level
        count = Carrier.where(abbrev: carrier_name).first.plans.where(year: plan_year_id, metal_level: tier).count
        csv << [plan_year_id, carrier_id, carrier_name, plan_type_code, tier, count]
      end
    end
  end
end
