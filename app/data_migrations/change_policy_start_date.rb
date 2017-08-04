# Changes the start date on ALL members of a policy
require File.join(Rails.root, "lib/mongoid_migration_task")
class ChangePolicyStartDate < MongoidMigrationTask

  def move_effective_date(policy,new_start_date)
    policy.enrollees.each do |enrollee|
      enrollee.coverage_start = ENV['new_start_date'].to_date
      enrollee.save
    end
    puts "Changed start date for policy #{ENV['eg_id']} to #{ENV['new_start_date']}" unless Rails.env.test?
  end

  def migrate
    if Policy.where(eg_id: ENV['eg_id']).size > 1
      puts "There are multiple policies for policy #{ENV['eg_id']}. Please resolve before changing effective dates."
    elsif Policy.where(eg_id: ENV['eg_id']).size == 0
      puts "Policy #{ENV['eg_id']} not found."
    else
      policy = Policy.where(eg_id: ENV['eg_id']).first
      if policy.enrollees.map(&:coverage_start).uniq.size > 1
        puts "There are enrollees with different effective dates. Are you certain you want to continue? Doing so will give all enrollees the same effective date. y/n?"
        response = gets.chomp.to_s
        if response.downcase == "y"
          move_effective_date(policy,ENV['new_start_date'])
        else
          "Effective date for policy #{ENV['eg_id']} was not moved."
        end
      else
        move_effective_date(policy,ENV['new_start_date'])
      end
    end
  end
end