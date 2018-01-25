# This rake task generates carrier audits; it does not change data. 

# Examples
# RAILS_ENV=production bundle exec rake audits:generate_audits market='ivl' cutoff_date='01-01-2018' carrier='GHMSI'
# RAILS_ENV=production bundle exec rake audits:generate_audits market='shop' cutoff_date='01-01-2018' carrier='GHMSI'

namespace :audits do 
  desc "Generate Audits"
  task :generate_audits => :environment do 
    require File.join(Rails.root,"app","data_migrations","generate_audits_via_cv2")
    carrier_id_map = {}
    Carrier.all.each do |c|
      carrier_id_map[c.id] = c
    end

    plan_id_map = {}
    active_year_hios_map = {}
    Plan.where(:year => {"$gte" => 2017}).each do |p|
      plan_id_map[p.id] = p
      active_year_hios_map[[p.year,p.hios_plan_id]] = p
    end

    Caches::CustomCache.allocate(Carrier, :cv2_carrier_cache, carrier_id_map)
    Caches::CustomCache.allocate(Plan, :cv2_plan_cache, plan_id_map)
    Caches::CustomCache.allocate(Plan, :cv2_hios_active_year_plan_cache, active_year_hios_map)
    ga = GenerateAudits.new
    ga.generate_cv2s
    Caches::CustomCache.release(Carrier, :cv2_carrier_cache)
    Caches::CustomCache.release(Plan, :cv2_plan_cache)
    Caches::CustomCache.release(Plan, :cv2_hios_active_year_plan_cache)
  end
end