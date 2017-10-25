# Terminates Plan Years
require File.join(Rails.root, "lib/mongoid_migration_task")

class TerminatePlanYear < MongoidMigrationTask
  def migrate
    if Employer.where(fein: ENV['fein']).size > 1
      puts "There are multiple employers with this FEIN. Please correct this situation before moving forward."
    elsif Employer.where(fein: ENV['fein']).size < 1
      puts "No employer was found with this FEIN. Please check your FEIN or correct the employer's FEIN before moving forward."
    elsif Employer.where(fein: ENV['fein']).size == 1
      employer = Employer.find_for_fein(ENV['fein'])

      start_date = Date.strptime(ENV['start_date'], '%m-%d-%Y')
      end_date = Date.strptime(ENV['new_end_date'], '%m-%d-%Y')
      
      plan_year = employer.plan_year_of(start_date)
      plan_year.terminate_plan_year(end_date)
    end
  end
end