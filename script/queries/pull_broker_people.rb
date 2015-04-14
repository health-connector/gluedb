require 'csv'

ssns = []

CSV.foreach("script/queries/brokers_from_curam.csv", :headers => true) do |inrow|
  row_h = inrow.to_hash
  if row_h['SSN'].blank?
  elsif row_h['SSN'].strip == '#N/A'
  else
    ssns << row_h['SSN'].strip
  end
end

p_map = Person.collection.aggregate([{"$unwind"=> "$members"}, {"$project" => {"_id" => 0, member_id: "$members.hbx_member_id", ssn: "$members.ssn"}}])

ssn_member_map = {}

member_ids = []

p_map.each do |pm|
  if ssns.include?(pm['ssn'])
    member_ids << pm['member_id']
    ssn_member_map[pm['ssn']] = pm['member_id']
  end
end

all_pols = Policy.where({
  :enrollees => {"$elemMatch" => {
    :rel_code => "self",
    :m_id => {"$in" => member_ids}
  }}})

mem_pols = all_pols.group_by { |pol| pol.subscriber.m_id }

Caches::MongoidCache.allocate(Broker)
Caches::MongoidCache.allocate(Carrier)
Caches::MongoidCache.allocate(Plan)

CSV.open('brokers_with_glue_data_20150318.csv', 'w') do |csv|
  csv << ["PROVIDERTYPE",  "PROVIDERPRACTICEBUSINESSAREA" , "PROVIDERREFERENCENUMBER", "NATIONALPRODUCERNUMBER", "PROVIDERNAME", "CLIENT_NAME", "SSN", "DOB", "USER_ACCOUNT", "PROVIDERSTATUS", "STARTDATE", "ENDDATE",
          "CARRIERINGLUE", "BROKERINGLUE", "SHOP", "GLUE ENROLLMENT ID", "GLUE START DATE", "GLUE END DATE","Plan Name","Plan Hios-id"]

  CSV.foreach("script/queries/brokers_from_curam.csv", :headers => true)do |inrow|
    row_a = inrow.fields
    row_h = inrow.to_hash
    if row_h['SSN'].blank?
      csv << (row_a + ["NO SSN"])
    elsif row_h['SSN'].strip == '#N/A'
      csv << (row_a + ["NO SSN"])
    else
=begin
      per = Person.where({
        "members" => {
          "$elemMatch" => {
            "ssn" =>
            row_h['SSN'].strip
          }
        }}).first
=end
   #     if !per.blank?
          m_id = ssn_member_map[row_h['SSN'].strip]
          if !m_id.blank?
            per_pols = mem_pols[m_id] || []
            counted_pols = per_pols.select { |a| !a.canceled? }
            if counted_pols.any?
              pol_vals = counted_pols.map do |pol|
                broker = Caches::MongoidCache.lookup(Broker, pol.broker_id) { pol.broker }
                plan = Caches::MongoidCache.lookup(Plan, pol.plan_id) { pol.plan }
                carrier = Caches::MongoidCache.lookup(Carrier, plan.carrier_id) { plan.carrier }
                [carrier.name, broker.nil? ? "" : broker.name_full,
                 pol.employer_id.blank? ? "N" : "Y",
                 pol.eg_id,
                 pol.subscriber.coverage_start,
                 pol.subscriber.coverage_end,
                 pol.plan.name,
                 pol.plan.hios_plan_id
                ]
              end
              pol_vals.uniq.each do |pval|
                csv << row_a + pval
              end
            else
              csv << row_a + ["NOT IN GLUE"]
            end
          else
            csv << row_a + ["NOT IN GLUE"]
          end
        #else
        #  csv << row_a + ["NOT IN GLUE"]
        #end
    end
  end
end
