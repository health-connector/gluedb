require File.join(Rails.root,"app","data_migrations","add_plan_catalog_override.rb")

#  RAILS_ENV=production bundle exec rake migrations:add_plan_catalog_override filename='some.csv'

namespace :migrations do 
  desc "Add Plan Year Catalog Override"
  AddPlanCatalogOverride.define_task :add_plan_catalog_override => :environment
end