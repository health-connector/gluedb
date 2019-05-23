namespace :ct_demo do
  def import_file_year(f_name, year)
    puts "Importing #{f_name} plans"
    plan_file = File.open("db/plans/#{f_name}_plans.json", "r")
    data = plan_file.read
    plan_file.close
    plan_data = JSON.load(data)
    puts "Before: total #{Plan.count} plans"
    puts "#{plan_data.size} plans in json file"
    plan_data.each do |pd|
      pd["carrier_id"] = Carrier.for_fein(pd["fein"]).id
      plan = Plan.where(year: year.to_i).and(hios_plan_id:pd["hios_plan_id"]).first
      if plan.blank?
        plan = Plan.new(pd)
        plan.id = pd["id"]
        plan.save!
      else
        plan.update_attributes(pd)
      end
    end
    puts "After: total #{Plan.count} plans"
    puts "Finished importing #{f_name} plans"
  end

  desc "Load Demo Plans"
  task :load_plans => "ct_demo:load_carriers" do
    import_file_year("2019_ivl", 2019)
    import_file_year("2019_shop", 2019)
    import_file_year("2020_ivl", 2020)
    import_file_year("2020_shop", 2020)
  end
end
