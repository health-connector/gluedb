# Changes/Addes end dates to policies
require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangePolicyEndDate < MongoidMigrationTask
  def deactivate_enrollees
    policy = Policy.where(eg_id: ENV['eg_id']).first
    policy.enrollees.each do |enrollee|
      enrollee.emp_stat = "terminated"
      enrollee.coverage_status = "inactive"
      enrollee.coverage_end = ENV['end_date'].to_date
      enrollee.save!
    end
  end

  def change_aasm_state
    policy = Policy.where(eg_id: ENV['eg_id']).first
    if policy.policy_start == ENV['end_date'].to_date
      policy.aasm_state = 'canceled'
    elsif policy.policy_start != ENV['end_date'].to_date
      policy.aasm_state = 'terminated'
    end
    policy.save!
  end

  def migrate
    deactivate_enrollees
    change_aasm_state
    puts "Changed end date for policy #{ENV['eg_id']} to #{ENV['end_date']}" unless Rails.env.test?
  end
end