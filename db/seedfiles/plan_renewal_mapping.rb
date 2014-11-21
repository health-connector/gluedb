hios_2014_to_2015 = {
        "77422DC0060001" => "77422DC0060002",
        "77422DC0060003" => "77422DC0060002",
        "77422DC0060007" => "77422DC0060008",
        "77422DC0060009" => "77422DC0060008",
        "78079DC0210001" => "78079DC0210001" }

plans_2014 = Plan.where({year: 2014})
plans_2015 = Plan.where({year: 2015})

map_for_2015 = plans_2015.inject({}) do |h, plan|
  h[plan.hios_plan_id] = plan
  h
end

def get_map_hios(current_year_hios, hios_map)
  components = current_year_hios.split("-")
  main_component = components.first
  variant = ""
  if components.length > 1
    variant = "-#{components.last}"
  end
  if hios_map.has_key?(main_component)
    return(hios_map[main_component] + variant)
  end
  current_year_hios
end

plans_2014.each do |pl|
  renewal_plan = map_for_2015[get_map_hios(pl.hios_plan_id, hios_2014_to_2015)]
  raise pl.inspect if renewal_plan.blank?
#  pl.save!
end
