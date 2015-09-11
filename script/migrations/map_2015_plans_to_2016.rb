log_path = "#{Rails.root}/log/map_2015_and_2016_plans_#{Time.now.to_s.gsub(' ', '')}.log"
$logger = Logger.new(log_path)

Plan.where(year: '2015').each do |plan_2015|
  plan_2016 = nil
  if plan_2015.renewal_plan_id
    plan_2016 = Plan.find(plan_2015.renewal_plan_id)
    if plan_2016.nil?
      $logger.info "No 2016 plan found - plan_2015 #{plan_2015.id} hios_plan_id #{plan_2015.hios_plan_id} renewal_plan_id #{plan_2015.renewal_plan_id}"
      next
    end
    plan_2015.renewal_plan = plan_2016
  else
    plan_2016 = Plan.where(year: '2016').and(hios_plan_id: plan_2015.hios_plan_id).first
    if plan_2016.nil?
      $logger.info "No 2016 plan found - plan_2015 #{plan_2015.id} hios_plan_id #{plan_2015.hios_plan_id}"
      next
    end
    plan_2015.renewal_plan = plan_2016
  end
  plan_2015.save
  $logger.info "plan_2015 #{plan_2015.id} hios_plan_id #{plan_2015.hios_plan_id} renewal_plan.id #{plan_2015.renewal_plan.id} plan_2016 #{plan_2016.id} hios_plan_id #{plan_2016.hios_plan_id}"
end

puts "logs written to #{log_path}"