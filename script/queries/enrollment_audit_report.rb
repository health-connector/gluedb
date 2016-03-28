require 'pry'
require 'csv'
require 'mongoid'

db = Mongoid::Sessions.default
person_collection = db[:people]

start_date = Time.mktime(2015,10,15,0,0,0)

end_date = Time.mktime(2016,2,29,23,59,59)

created_enrollments = Policy.where(:created_at => {"$gte" => start_date, "$lte" => end_date})

potential_terminations = Policy.where(:updated_at => {"$gte" => start_date, "$lte" => end_date})

def dependent_end_date(policy)
	if policy.enrollees.any? {|enrollee| enrollee.coverage_end != nil} == true
		return true
	else
		return false
	end
end

has_terminated_member = []

potential_terminations.each do |policy|
	if policy.canceled?
		has_terminated_member.push(policy)
	elsif policy.terminated?
		has_terminated_member.push(policy)
	elsif dependent_end_date(policy) == true
		has_terminated_member.push(policy)
	end
end

all_policies_to_analyze = (created_enrollments + has_terminated_member).uniq!

timestamp = Time.now.strftime('%Y%m%d%H%M')

def different_effective_dates(policy)
	coverage_start_dates = policy.enrollees.map(&:coverage_start).uniq
	if coverage_start_dates.size > 1
		return true
	elsif coverage_start_dates == 1
		return false
	end
end

def date_term_sent(policy,end_date)
	formatted_end_date = end_date_formatter(end_date)
	termination_transactions = []
	policy.transaction_set_enrollments.each do |tse|
		if tse.body.read(formatted_end_date) != nil
			termination_transactions.push(tse)
		end
	end
	if termination_transactions.size > 0
		termination_transactions.sort_by(&:submitted_at)
		return termination_transactions.first.submitted_at
	else
		return policy.updated_at
	end
end

def end_date_formatter(date)
	year = date.year.to_s
	month = date.month.to_s
	if month.length == 1
		month = "0"+month
	end
	day = date.day.to_s
	if day.length == 1
		day = "0"+day
	end
	return year+month+day
end

Caches::MongoidCache.with_cache_for(Carrier, Plan, Employer) do

CSV.open("enrollment_audit_report_#{timestamp}.csv","w") do |csv|
	csv << ["Subscriber First Name","Subscriber Last Name","HBX ID","DOB","Market","Policy ID","Carrier","QHP ID","Plan Name",
			"Start Date","End Date","Date Termination Sent","Plan Metal Level","Premium Total",
			"","","","","","","","","","","",
			"APTC/Employer Contribution",
			"","","","","","","","","","","",
			"Employer Name","Employer FEIN"]
	csv << ["","","","","","","","","","","","","",
			"January","February","March","April","May","June","July","August","September","October","November","December",
			"January","February","March","April","May","June","July","August","September","October","November","December"]
	all_policies_to_analyze.each do |policy|
		market = policy.market
		policy_id = policy._id
		carrier = Caches::MongoidCache.lookup(Carrier, policy.carrier_id) {policy.carrier}
        carrier_name = carrier.name
        plan = Caches::MongoidCache.lookup(Plan, policy.plan_id) {policy.plan}
        plan_hios_id = plan.hios_plan_id
        plan_name = plan.name
        plan_metal = plan.metal_level
        if policy.is_shop?
        	if policy.enrollees.size == 1
        		premium_total = policy.pre_amt_tot
        		employer_contribution = policy.tot_emp_res_amt
        		employer = Caches::MongoidCache.lookup(Employer, policy.employer_id) {policy.employer}
        		employer_name = employer.name
        		employer_fein = employer.fein
        		policy.enrollees.each do |enrollee|
        			enrollee_person = person_collection.find("members.hbx_member_id" => enrollee.m_id).first
        			first_name = enrollee_person["name_first"]
        			last_name = enrollee_person["name_last"]
        			hbx_id = enrollee.m_id
        			dob = enrollee_person["members"].first["dob"]
        			start_date = enrollee.coverage_start
        			end_date = nil
        			if enrollee.end_date != nil
        				end_date = enrollee.end_date
        				date_sent = date_term_sent(policy,end_date)
        				csv << [first_name,last_name,hbx_id,dob,market,policy_id,carrier_name,plan_hios_id,plan_name,
        						start_date,end_date,date_sent,plan_metal,
        						premium_total,premium_total,premium_total,premium_total,premium_total,premium_total,premium_total,
        						premium_total,premium_total,premium_total,premium_total,premium_total,
        						employer_contribution,employer_contribution,employer_contribution,employer_contribution,
        						employer_contribution,employer_contribution,employer_contribution,employer_contribution,
        						employer_contribution,employer_contribution,employer_contribution,employer_contribution,
        						employer_name,employer_fein]
        			else
        				csv << [first_name,last_name,hbx_id,dob,market,policy_id,carrier_name,plan_hios_id,plan_name,
        						start_date,"","",plan_metal,
        						premium_total,premium_total,premium_total,premium_total,premium_total,premium_total,premium_total,
        						premium_total,premium_total,premium_total,premium_total,premium_total,
        						employer_contribution,employer_contribution,employer_contribution,employer_contribution,
        						employer_contribution,employer_contribution,employer_contribution,employer_contribution,
        						employer_contribution,employer_contribution,employer_contribution,employer_contribution,
        						employer_name,employer_fein]
        			end # Ends enrollee end date checker.
        		end  # Ends enrollees.each loop.
        	else ## if there's more than one enrollee
        		next
        	end # Ends enrollee count evaluator
        else ## If it's an IVL policy
        	next
        end # Ends SHOP/IVL evaluator
	end
end

end # ends MongoidCache