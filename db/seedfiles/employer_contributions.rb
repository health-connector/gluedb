require 'csv'

def clean_percentage(val)
  return 0.00 if val.blank?
  val.strip.gsub("%","").to_f
end

CSV.foreach("employer_conts.csv", headers: true) do |row|
  begin
    props = row.to_hash
    fein = props['fein'].gsub("-","")
    employee_cont = clean_percentage(props['employee'])
    dependent_cont = clean_percentage(props['dependent'])
    reference_hios = props['hios']
    start_date_str = props['date']
    employer_start = Date.strptime(start_date_str, "%m/%d/%Y")
    employer_end = employer_start + 1.year - 1.day
    if (!reference_hios.blank?)
      employer = Employer.find_for_fein(fein)
      plan = Plan.find_by_hios_id_and_year(reference_hios, employer_start.year)
      plan_year = employer.plan_year_of(employer_start)
      if !plan_year
        plan_year = PlanYear.create!({
          :start_date => employer_start,
          :end_date => employer_end,
          :employer => employer
        })
      end
      if plan_year.contribution_strategy.blank?
        EmployerContributions::DistrictOfColumbiaEmployer.create!({
          :plan_year => plan_year,
          :reference_plan => plan,
          :employee_max_percent => employee_cont,
          :dependent_max_percent => dependent_cont
        })
      else
        ecs = plan_year.contribution_strategy
        puts "#{plan_year.employer.name}:#{plan_year.employer.fein}:plan data changed from #{ecs.reference_plan_id} to #{plan.id}" if ecs.reference_plan_id !=  plan.id
        puts "#{plan_year.employer.name}:#{plan_year.employer.fein}:employee data changed #{ecs.employee_max_percent} to #{employee_cont}" if ecs.employee_max_percent != employee_cont
        puts "#{plan_year.employer.name}:#{plan_year.employer.fein}:dependent data changed #{ecs.dependent_max_percent} to #{dependent_cont}" if ecs.dependent_max_percent != dependent_cont
        ecs.update_attributes!({
          :reference_plan => plan,
          :employee_max_percent => employee_cont,
          :dependent_max_percent => dependent_cont
        })
      end
    end
  rescue Exception => e
    puts e.inspect
    raise row.to_hash.inspect
  end
end
