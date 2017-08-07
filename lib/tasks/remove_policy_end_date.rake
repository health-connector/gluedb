require File.join(Rails.root,"app","data_migrations","remove_policy_end_date.rb")

# This rake tasks removes end dates from all members of a policy in Glue. 
# format RAILS_ENV = production bundle exec rake migrations:remove_policy_end_date aasm_state='submitted' eg_id='123456'

namespace :migrations do 
  desc "Remove Policy End Date"
  RemovePolicyEndDate.define_task :remove_policy_end_date => :environment
end