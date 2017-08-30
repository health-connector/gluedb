require File.join(Rails.root,"app","data_migrations","change_policy_end_date.rb")

# This rake tasks removes end dates from all members of a policy in Glue. 
# format RAILS_ENV = production bundle exec rake migrations:change_policy_end_date eg_id='123456' end_date='05/31/2017'

namespace :migrations do 
  desc "Change Policy End Date"
  ChangePolicyEndDate.define_task :change_policy_end_date => :environment
end