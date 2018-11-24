require File.join(Rails.root,"app","data_migrations","change_plan_year_dates.rb")

# This rake task Changes Plan Year Start_Date and End_Date. 
# format RAILS_ENV=production  bundle exec rake migrations:change_plan_year_dates hbx_id="1" old_start_date="08/01/2018" new_start_date="10/01/2018" new_end_date="10/31/2018"

namespace :migrations do 
  desc "Change Plan Year Start and End dates"
  ChangePlanYearDates.define_task :change_plan_year_dates => :environment
end