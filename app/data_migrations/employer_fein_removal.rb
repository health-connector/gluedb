# Removes FEINs
require File.join(Rails.root, "lib/mongoid_migration_task")

class EmployerFeinRemoval < MongoidMigrationTask
  def migrate
    employer_to_change = Employer.find(ENV['employer_id'])
    employer_to_change.unset(:fein)
    employer_to_change.save
  end
end