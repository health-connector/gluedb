# This rake task generates carrier audits; it does not change data. 

# Examples
# RAILS_ENV=production bundle exec rake audits:generate_audits market='ivl' cutoff_date='01-01-2018' carrier='GHMSI'
# RAILS_ENV=production bundle exec rake audits:generate_audits market='shop' cutoff_date='01-01-2018' carrier='GHMSI'

namespace :audits do 
  desc "Generate Audits"
  task :generate_audits => :environment do 
    require File.join(Rails.root,"app","data_migrations","generate_audits_via_cv2")
    ga = GenerateAudits.new
    ga.generate_cv2s
  end
end