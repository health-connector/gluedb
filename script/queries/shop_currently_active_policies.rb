todays_date = Date.today

def pick_plan_years(todays_date)
	if todays_date.day == 1
		plan_year_date = (todays_date-1.year)+1.day
		return PlanYear.where(:start_date => {"$gt" => plan_year_date})
	else
		plan_year_date = (todays_date-1.year)
		return PlanYear.where(:start_date => {"$gt" => plan_year_date})
	end
end

def pick_correct_policy(eligible_policies)
	active_states = ["effectuated","resubmitted","submitted"]
	if eligible_policies.blank?
		return nil
	elsif eligible_policies.size == 1
		unless eligible_policies.first.terminated?
			return eligible_policies.first
		else
			return nil
		end
	elsif eligible_policies.size > 1
		sorted_policies = sort_policies(eligible_policies)
		if all_active(sorted_policies) == true
			return sorted_policies.last
		else
			if active_states.include?(sorted_policies.last.aasm_state)
				return sorted_policies.last
			else
				return nil
			end
		end
	end
end

def sort_policies(policies)
	return policies.sort_by{|policy| policy.subscriber.coverage_start}
end

def all_active(policies)
	active_states = ["effectuated","resubmitted","submitted"]
	if policies.all?{|policy| active_states.include?(policy.aasm_state)}
		return true
	else
		return false
	end
end

health_plans = Plan.where(coverage_type: "health").map(&:id)
dental_plans = Plan.where(coverage_type: "dental").map(&:id)

correct_policies = []

plan_years = pick_plan_years(todays_date)

	pb = ProgressBar.create(
       :title => "Processing Plan Years",
       :total => plan_years.size,
       :format => "%t %a %e |%B| %P%%"
    )

plan_years.each do |plan_year|
	policy_start_date = plan_year.start_date
	employer = plan_year.employer
	next if employer.blank?
	if employer.employees.size > 51
		pb2 = ProgressBar.create(
	       :title => "#{employer.name}",
	       :total => employer.employees.size,
	       :format => "%t %a %e |%B| %P%%"
	    )
	end
	employer.employees.each do |employee|
		eligible_health_policies = employee.policies.where(:aasm_state => {"$ne" => "canceled"},
														   :employer_id => {"$ne" => nil},
														   :plan_id => {"$in" => health_plans},
														   :enrollees => {"$elemMatch" => {:rel_code => "self", 
																						   :coverage_start => 
																							   {"$gte" => policy_start_date}}})
		eligible_dental_policies = employee.policies.where(:aasm_state => {"$ne" => "canceled"},
														   :employer_id => {"$ne" => nil},
														   :plan_id => {"$in" => dental_plans},
														   :enrollees => {"$elemMatch" => {:rel_code => "self", 
																						   :coverage_start => 
																							   {"$gte" => policy_start_date}}})
		correct_health_policy = pick_correct_policy(eligible_health_policies)
		correct_dental_policy = pick_correct_policy(eligible_dental_policies)
		unless correct_health_policy.blank?
			correct_policies.push(correct_health_policy)
		end
		unless correct_dental_policy.blank?
			correct_policies.push(correct_dental_policy)
		end
	unless pb2 == nil
		pb2.increment
	end
	end # ends line 30 employee loop
	pb.increment
end # ends line 26 plan year loop

CSV.open("currently_active_shop_policies_#{Time.now}.csv", "w") do |csv|
	csv << ["Enrollment Group ID", "AASM State", "Employer Name", "Employer FEIN", 
			"Subscriber HBX ID","Subscriber First Name", "Subscriber Last Name",
			"Plan Name", "Plan HIOS ID", "Coverage Type",
			"Start Date", "End Date"]
	correct_policies.each do |policy|
		eg_id = policy.eg_id
		aasm = policy.aasm_state
		employer = policy.employer
		employer_name = employer.name
		employer_fein = employer.fein
		subscriber_person = policy.subscriber.person
		subscriber_hbx_id = policy.subscriber.m_id
		first_name = subscriber_person.name_first
		last_name = subscriber_person.name_last
		plan = policy.plan
		plan_name = plan.name
		hios_id = plan.hios_plan_id
		coverage_type = plan.coverage_type
		start_date = policy.policy_start
		end_date = policy.policy_end
		csv << [eg_id, aasm, employer_name,employer_fein,
				subscriber_hbx_id,first_name,last_name,
				plan_name,hios_id,coverage_type,
				start_date,end_date]
	end
end