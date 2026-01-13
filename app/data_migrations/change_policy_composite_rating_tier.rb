# Example use case:
# rake to change the composite rating tier for the affected health policy
# to composite_rating_tier#employee_and_spouse

require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangePolicyCompositeRatingTier < MongoidMigrationTask
  def migrate
  	possible_rating_tiers = [
  	  "urn:openhbx:terms:v1:composite_rating_tier#family",
  	  "urn:openhbx:terms:v1:composite_rating_tier#employee_only",
  	  "urn:openhbx:terms:v1:composite_rating_tier#employee_and_one_or_more_dependents",
  	  "urn:openhbx:terms:v1:composite_rating_tier#employee_and_spouse",
  	  nil
  	]
  	policy = Policy.where(eg_id: ENV['eg_id']).first
  	rating_tier = ENV['rating_tier']
  	beginning_rating_tier_string = "urn:openhbx:terms:v1:composite_rating_tier#"
  	unless Rails.env.test?
      raise "This policy cannot be found" if policy.blank?
      raise "No rating tier provided" if rating_tier.blank?
  	end
  	new_rating_tier = beginning_rating_tier_string + rating_tier.to_s
  	unless Rails.env.test?
      raise "Invalid rating tier input. Tier entered is " + new_rating_tier.to_s + ". Must be: " + possible_rating_tiers.each {|tier| tier.to_s }
  	end
  	policy.update_attributes(composite_rating_tier: new_rating_tier)
    puts("Composite rating tier changed to " + policy.composite_rating_tier) unless Rails.env.test?
  end
end
