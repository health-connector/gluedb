require File.join(Rails.root,"app","data_migrations","duplicate_employer_cleanup.rb")

# This rake tasks removes end dates from all members of a policy in Glue. 
# format RAILS_ENV = production bundle exec rake migrations:duplicate_employer_cleanup good_employer_id='some_mongo_id' bad_employer_id='some_other_mongo_id'

namespace :migrations do 
  desc "Duplicate Employer Cleanup"
  DuplicateEmployerCleanup.define_task :duplicate_employer_cleanup => :environment
end