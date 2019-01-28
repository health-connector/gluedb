require File.join(Rails.root, "app", "data_migrations", "change_policy_composite_rating_tier.rb")

# This rake tasks change the Policy's composite_rating_tier
# Format:
# RAILS_ENV=production bundle exec rake migrations:change_policy_composite_rating_tier eg_id="12345" rating_tier="family"

namespace :migrations do
  desc "Change policy composite rating tier"
  ChangePolicyCompositeRatingTier.define_task :change_policy_composite_rating_tier => :environment
end
