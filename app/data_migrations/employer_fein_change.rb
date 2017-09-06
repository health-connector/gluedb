# Changes FEINs
require File.join(Rails.root, "lib/mongoid_migration_task")

class EmployerFeinChange < MongoidMigrationTask
  def migrate
    employer_to_change = Employer.find(ENV['employer_id'])
    if Employer.find_for_fein(ENV['new_fein']).present?
      puts "Employer with FEIN #{ENV['new_fein']} already exists. Please check before making FEIN changes." unless Rails.env.test?
    else
      employer_to_change.update_attributes(:fein => ENV['new_fein'])
    end
  end
end