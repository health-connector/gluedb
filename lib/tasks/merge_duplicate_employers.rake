require File.join(Rails.root,"app","data_migrations","merge_duplicate_employers.rb")

# This rake task merges employers in Glue.
# format RAILS_ENV=production bundle exec rake migrations:merge_duplicate_employers employer_to_keep='employer_mongo_id' employer_to_remove='employer_mongo_id'

namespace :migrations do 
  desc "Merge Duplicate Employers"
  MergeDuplicateEmployers.define_task :merge_duplicate_employers => :environment
end