require File.join(Rails.root,"app","data_migrations","employer_fein_removal.rb")

# This rake task removes employer FEINs. 
# format RAILS_ENV=production bundle exec rake migrations:employer_fein_removal employer_id='some_mongo_id' new_fein='123456789'

namespace :migrations do 
  desc "Employer FEIN Removal"
  EmployerFeinRemoval.define_task :employer_fein_removal => :environment
end