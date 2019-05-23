namespace :ct_demo do
  desc "Load Demo Users"
  task :load_data => ["ct_demo:load_plans","ct_demo:load_users"]
end
