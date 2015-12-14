## This script generates a list of mid-month terminations for a specified carrier. 

require 'csv'
require 'pry'

## List the carriers you want the report generated for. 
carrier_abbrevs = ["DDPA", "DTGA"]

carrier_ids = Carrier.where({
 :abbrev => {"$in" => carrier_abbrevs}
}).map(&:id)

plan_ids = Plan.where(:carrier_id => {"$in" => carrier_ids}).map(&:id)

jan_end_2014 = Date.new(2014,1,31)
feb_end_2014 = Date.new(2014,2,28)
mar_end_2014 = Date.new(2014,3,31)
apr_end_2014 = Date.new(2014,4,30)
may_end_2014 = Date.new(2014,5,31)
jun_end_2014 = Date.new(2014,6,30)
jul_end_2014 = Date.new(2014,7,31)
aug_end_2014 = Date.new(2014,8,31)
sep_end_2014 = Date.new(2014,9,30)
oct_end_2014 = Date.new(2014,10,31)
nov_end_2014 = Date.new(2014,11,30)
dec_end_2014 = Date.new(2014,12,31)
jan_end_2015 = Date.new(2015,1,31)
feb_end_2015 = Date.new(2015,2,28)
mar_end_2015 = Date.new(2015,3,31)
apr_end_2015 = Date.new(2015,4,30)
may_end_2015 = Date.new(2015,5,31)
jun_end_2015 = Date.new(2015,6,30)
jul_end_2015 = Date.new(2015,7,31)
aug_end_2015 = Date.new(2015,8,31)
sep_end_2015 = Date.new(2015,9,30)
oct_end_2015 = Date.new(2015,10,31)
nov_end_2015 = Date.new(2015,11,30)
dec_end_2015 = Date.new(2015,12,31)

date_array = [jan_end_2014,jan_end_2015,feb_end_2015,feb_end_2014,mar_end_2015,mar_end_2014,apr_end_2015,apr_end_2014,may_end_2015,
may_end_2014,jun_end_2015,jun_end_2014,jul_end_2015,jul_end_2014,aug_end_2015,aug_end_2014,sep_end_2015,sep_end_2014,oct_end_2015,
oct_end_2014,nov_end_2015,nov_end_2014,dec_end_2015,dec_end_2014]

eligible_pols = Policy.where({
  :enrollees => {"$elemMatch" => {
    :rel_code => "self",
    :coverage_end => {"$nin" => date_array}
  }}, :aasm_state => {"$nin" => ["submitted","canceled","resubmitted"]}, :plan_id => {"$in" => plan_ids}}).no_timeout

timestamp = Time.now.strftime('%Y%m%d%H%M')

CSV.open("midmonth_terminations_#{timestamp}.csv", "w") do |csv|
	csv << ["Policy ID", "HBX ID", "Name,", "Plan", "End Date"]
	eligible_pols.each do |policy|
		policy_id = policy._id
		plan_name = policy.plan.name
		policy.enrollees.each do |enrollee|
			hbx_id = enrollee.m_id
			name = enrollee.person.name_full
			end_date = enrollee.coverage_end
			csv << [policy_id, hbx_id, name, plan_name, end_date]
		end
	end
end