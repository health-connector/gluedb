require File.join(Rails.root,"app","data_migrations","remove_issuer_ids_from_plan_year.rb")
# This rake task used to update plan year issuer ids
# format RAILS_ENV=production  bundle exec rake migrations:remove_issuer_ids_from_plan_year hbx_id="1" start_date="08/01/2018" issuer_id='1111'
namespace :migrations do
  desc "update plan year issuer ids"
  RemoveIssuerIdsFromPlanYear.define_task :remove_issuer_ids_from_plan_year => :environment
end
