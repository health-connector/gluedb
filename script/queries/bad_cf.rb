require 'csv'

badCF = Policy.where({
 :enrollees => {"$elemMatch" => {
   :rel_code => "self",
   :coverage_start => {"$lt" => Date.new(2015,1,1)},
   :coverage_end => {"$gt" => Date.new(2014,12,31)}
 }},:employer_id => nil
})

CSV.open("bad_cf_cancels.csv", "wb") do |csv|
  csv << ["Policy ID", "Carrier", "Plan Name", "Plan Hios", "Subscriber Name", "HBX ID","Start","End","File name"]
  badCF.each do |pol|
    t = pol.transaction_list.select{ |t| t.transaction_kind == "maintenance"}.first.body
    csv << [pol.id, pol.carrier.name ,pol.plan.name, pol.plan.hios_plan_id, pol.subscriber.person.name_full, pol.subscriber.m_id,pol.subscriber.coverage_start, pol.subscriber.coverage_end,t]
  end
end
