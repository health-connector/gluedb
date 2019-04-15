require File.join(Rails.root,"app","data_migrations","change_policy_employer.rb"),
# This rake tasks changes the employer of a policy in Glue.
# RAILS_ENV=production bundle exec rake migrations:change_policy_employer eg_ids='123456,123123,123654' employer_id='some_mongo_id'

namespace :migrations do 
  desc "Change Policy Employer"
  ChangePolicyEmployer.define_task :change_policy_employer => :environment
end