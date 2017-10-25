require File.join(Rails.root,"app","data_migrations","change_policy_start_date.rb")

# This rake tasks changes start dates for all members of a policy in Glue. 
# RAILS_ENV=production bundle exec rake migrations:change_policy_start_date eg_id='123456' new_start_date='08/04/2017'

namespace :migrations do 
  desc "Change Policy Start Date"
  ChangePolicyStartDate.define_task :change_policy_start_date => :environment
end