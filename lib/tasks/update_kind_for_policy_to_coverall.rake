require File.join(Rails.root,"app","data_migrations","update_kind_for_policy_to_coverall.rb")

# This rake task updates the kind field for the given policy to "coverall".
# format RAILS_ENV=production bundle exec rake migrations:update_kind_for_policy eg_id="abc123"

namespace :migrations do
  desc "Update kind for policy to coverall"
  UpdateKindForPolicyToCoverall.define_task :update_kind_for_policy_to_coverall => :environment
end