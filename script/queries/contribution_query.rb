# h = array of feins

h = Hash[feins.map{ |f| [f,Employer.where(fein: f).first.plan_years.last.contribution_strategy] }]

CSV.open("contribution.csv","wb") {|csv| h.each{|e| csv << [ e[0], Plan.find(e[1].reference_plan_id).hios_plan_id,e[1].employee_max_percent, e[1].dependent_max_percent ]}}
