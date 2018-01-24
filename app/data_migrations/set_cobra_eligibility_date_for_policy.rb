# To set cobra eligibility date for policy on ALL members of a policy
require File.join(Rails.root, "lib/mongoid_migration_task")

class SetCobraEligibilityDateForPolicy < MongoidMigrationTask

  def migrate
    
    policy_count = Policy.all_active_states.count
    offset_count = 0
    limit_count = 500
    processed_count = 0
    @logger = Logger.new("#{Rails.root}/log/set_cobra_eligibility_date_for_policy.log")
    while (offset_count <= policy_count) do
      @logger.info "Total offset  #offset_count}"
      Policy.limit(limit_count).offset(offset_count).each do |policy|
        begin
          if Policy.where("enrollee.ben_stat" => "cobra", "cobra_eligibility_date" => nil)
            policy.cobra_eligibility_date = policy.subscriber.coverage_start
            if policy.save!
              @logger.info "policy: #{policy.eg_id} updated with cobra eligibility date" unless Rails.env.test?
              processed_count += 1
            else
              @logger.info "unable to save policy: #{policy.eg_id}" unless Rails.env.test?
            end
          end
        rescue => e
          @logger.error "Policy #{policy.eg_id}" + e.message
        end
      end
      offset_count += limit_count
    end
    @logger.info "Total policy processed_count #{processed_count}"
  end
end

