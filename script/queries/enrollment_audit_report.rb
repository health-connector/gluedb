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

timestamp = Time.now.strftime('%Y%m%d%H%M')

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
end

end # ends MongoidCache