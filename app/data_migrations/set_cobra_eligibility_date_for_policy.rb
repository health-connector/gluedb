# To set cobra eligibility date for policy on ALL members of a policy
require File.join(Rails.root, "lib/mongoid_migration_task")

class SetCobraEligibilityDateForPolicy < MongoidMigrationTask

  def migrate
    
    policy_count = Policy.all_active_states.count
    offset_count = 0
    limit_count = 500
    processed_count = 0

    while (offset_count <= policy_count) do
      puts "offset_count: #{offset_count}"
      Policy.all_active_states.limit(limit_count).offset(offset_count).each do |policy|
        begin
          if (policy.is_cobra?) && (policy.cobra_eligibility_date.blank?) 
            policy.cobra_eligibility_date = policy.subscriber.coverage_start
            if policy.save!
              puts "policy: #{policy.eg_id} updated with cobra eligibility date" unless Rails.env.test?
              processed_count += 1
            else
              puts "unable to save policy: #{policy.eg_id}" unless Rails.env.test?
            end
          end
        rescue => e
          puts "Policy #{policy.eg_id}" + e.message
        end
      end
      offset_count += limit_count
    end
    puts "Total policy processed_count #{processed_count}"
  end
end
