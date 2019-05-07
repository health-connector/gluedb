class PoliciesMissingTransmissions

  attr_accessor :ct_cache, :all_pol_ids, :all_policies, :untransmitted_pols, :excluded_policies, :timestamp

  def initialize
    @ct_cache = Caches::Mongoid::SinglePropertyLookup.new(Plan, "coverage_type")
    @all_pol_ids = Protocols::X12::TransactionSetHeader.collection.aggregate([
      {"$match" => {
        "policy_id" => { "$ne" => nil }
      }},
      { "$group" => { "_id" => "$policy_id" }}
    ]).map { |val| val["_id"] }
    # No cancels/terms in this batch!
    @all_policies = Policy.all.no_timeout.to_a
    puts(@all_policies.length.to_s + " policies present")
    @untransmitted_pols = []
    if File.exists?("policy_blacklist.txt")
      @excluded_policies = File.read("policy_blacklist.txt").split("\n").map(&:strip).map(&:to_i)
    else
      @excluded_policies = []
    end
    @timestamp = Time.now.strftime('%Y%m%d%H%M')
  end
  
  # The ruby script returns a CSV containing the created at, eg_id, carrier
  # employer, subscriber name, and subscriber HBX id.
  # The criteria for policies missing transmissions is as follows:
  # 1. The policy's id is ecluded from a list of all Policy Id's taken from 
  #    Caches::Mongoid::SinglePropertyLookup
  # 2. The policy subscriber is present and the policy is not cancelled
  # 3. The policy is not included in "excluded policies", which comes from a text
  #    file called "policy_backlist.txt" (where does this come from?)

  def process
    CSV.open("policies_without_transmissions_#{@timestamp}.csv","w") do |csv|
      csv << ["Created At", "Enrollment Group ID", "Carrier", "Employer", "Subscriber Name", "Subscriber HBX ID"]
      @all_policies.each do |pol|
        if !@all_pol_ids.include?(pol.id)
          if pol.subscriber.present? && !pol.canceled?
            unless @excluded_policies.include? pol.id
              created_at = pol.created_at
              eg_id = pol.eg_id
              carrier = pol.plan.carrier.abbrev
              employer = pol.try(:employer).try(:name)
              subscriber_name = pol.subscriber.person.full_name rescue ""
              subscriber_hbx_id = pol.subscriber.m_id
              csv << [created_at,eg_id,carrier,employer,subscriber_name,subscriber_hbx_id]
            end
          end
        end
      end
      puts("Finished creating policies without transmissions CSV.")
    end 
  end
end

PoliciesMissingTransmissions.new.process