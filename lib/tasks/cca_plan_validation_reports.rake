# frozen_string_literal: true

# This rake tasks should be run to generate reports after plans loading.
# To generate all reports please use this rake command: RAILS_ENV=production bundle exec rake cca_plan_validation:reports["2019-12-01"]
require 'rubyXL'
require 'rubyXL/convenience_methods'

namespace :cca_plan_validation do

  desc "reports generation after plan loading"
  task :reports, [:active_date] => :environment do |_task, args|
    puts "Reports generation started" unless Rails.env.test?
    active_date = args[:active_date].to_date
    report = Services::PlanValidationReport.new(active_date)
    report.sheet1
    report.sheet2

    current_date = Date.today.strftime("%Y_%m_%d")
    file_name = "#{Rails.root}/CCA_PlanLoadValidation_Report_GDB_#{current_date}.xlsx"
    report.generate_file(file_name)

    if Rails.env.production?
      upload_to_s3 = Aws::S3Storage.new
      uri = upload_to_s3.save(file_path: filename, options: { internal_artifact: true})
      upload_to_s3.publish_to_sftp(filename,"Legacy::PushGluePlanValidationReport", uri)
    end

    timey2 = Time.now
    puts "Report ended at #{timey2}"
  end
end
