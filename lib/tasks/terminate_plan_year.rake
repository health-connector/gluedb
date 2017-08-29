require File.join(Rails.root,"app","data_migrations","terminate_plan_year.rb.rb")

# This rake tasks terminates plan years. 
# format RAILS_ENV=production bundle exec rake migrations:terminate_plan_year start_date='01-01-2017' new_end_date='01-31-2017'

namespace :migrations do 
  desc "Terminate Plan Year"
  TerminatePlanYear.define_task :terminate_plan_year => :environment
end