
# This rake task updates the kind field for the given policy to "coverall".
# format RAILS_ENV=production  bundle exec rake migrations:transform_xmls eg_ids="100618,232344,555444" reason_code="reinstate_enrollment"
namespace :migrations do 
  desc "Generate Transforms"
  task :transform_xmls => :environment do 
    require File.join(Rails.root,"app","data_migrations","transform_xmls")
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
    gt = GenerateTransforms.new
    gt.generate_transform
    Caches::CustomCache.release(Carrier, :cv2_carrier_cache)
    Caches::CustomCache.release(Plan, :cv2_plan_cache)
    Caches::CustomCache.release(Plan, :cv2_hios_active_year_plan_cache)
  end
end