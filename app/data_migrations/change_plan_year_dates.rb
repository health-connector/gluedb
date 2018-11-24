# Changes Plan_year start_date and end_date
require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangePlanYearDates < MongoidMigrationTask
  def migrate
    hbx_id = ENV["hbx_id"]
    old_start_date = ENV["old_start_date"] 
    new_end_date = ENV["new_end_date"]
    new_start_date = ENV["new_start_date"]

    employer = Employer.where(hbx_id: hbx_id).first

    if employer.blank?
      puts "No employer was found with the given hbx_id: hbx_id } " unless Rails.env.test?
    else
      plan_year = employer.plan_years.where(start_date: old_start_date).first
      if plan_year.present?
        plan_year.update_attributes!(start_date: new_start_date)  unless new_start_date == "" || new_start_date == nil
        plan_year.update_attributes!(end_date: new_end_date) unless new_end_date == "" || new_end_date == nil
        puts "Successfully updated, current plan_year dates are start_date:#{plan_year.start_date} and end_date:#{plan_year.end_date}" unless Rails.env.test?
      else
        puts "Plan_year is not found for the employer: #{hbx_id}" unless Rails.env.test?
      end
    end
  end
end