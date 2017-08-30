require File.join(Rails.root,"app","data_migrations","employer_fein_change.rb")

# This rake task changes employer FEINs. 
# format RAILS_ENV=production bundle exec rake migrations:employer_fein_change employer_id='some_mongo_id' new_fein='123456789'

namespace :migrations do 
  desc "Employer FEIN Change"
  EmployerFeinChange.define_task :employer_fein_change => :environment
end