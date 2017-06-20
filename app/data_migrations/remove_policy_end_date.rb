# Removes end dates from policies 
require File.join(Rails.root, "lib/mongoid_migration_task")

class RemovePolicyEndDate < MongoidMigrationTask
  def remove_end_dates
    policy = Policy.where(eg_id: ENV['eg_id']).first
    policy.enrollees.each do |enrollee|
      enrollee.emp_stat = "active"
      enrollee.coverage_status = "active"
      enrollee.coverage_end = nil
      enrollee.save!
    end
  end

  def change_aasm_state
    policy = Policy.where(eg_id: ENV['eg_id']).first
    policy.aasm_state = ENV['aasm_state']
    policy.save!
  end

  def migrate
    remove_end_dates
    change_aasm_state
    puts "Removed end date from policy #{ENV['eg_id']}" unless Rails.env.test?
  end
end