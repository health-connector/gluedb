require File.join(Rails.root,"app","data_migrations","change_policy_broker.rb")

# This rake tasks changes the broker of a policy in Glue.
# RAILS_ENV=production bundle exec rake migrations:change_policy_broker eg_id='123456' broker_npn='123456'

namespace :migrations do 
  desc "Change Policy Broker"
  ChangePolicyBroker.define_task :change_policy_broker => :environment
end