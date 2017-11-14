require File.join(Rails.root,"app","data_migrations","set_cobra_eligibility_date_for_policy.rb")
# This rake tasks used to set cobra eligibility date for policy.
# format RAILS_ENV = production bundle exec rake migrations:set_cobra_eligibility_date_for_policy
namespace :migrations do
  desc "set cobra eligibility date for policy"
  SetCobraEligibilityDateForPolicy.define_task :set_cobra_eligibility_date_for_policy => :environment
end