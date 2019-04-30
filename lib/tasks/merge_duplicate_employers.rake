require File.join(Rails.root,"app","data_migrations","merge_duplicate_employers.rb")

# This rake task merges employers in Glue.


# This rake task updates the kind field for the given policy to "coverall".
# Without CSV_FILE Updating Premium Amounts rake
# format RAILS_ENV=production bundle exec rake migrations:merge_duplicate_employers employer_to_keep='employer_mongo_id' employer_to_remove='employer_mongo_id' csv_file="false"

# With CSV_FILE updating duplicate employer records rake and 
# 1.Place a csv file on the root
# 2.Change the csv file name as duplicate_employer_records.csv
# 3.Then run the rake
# formatformat RAILS_ENV=production bundle exec rake migrations:merge_duplicate_employers csv_file="true"


namespace :migrations do 
  desc "Merge Duplicate Employers"
  MergeDuplicateEmployers.define_task :merge_duplicate_employers => :environment
end