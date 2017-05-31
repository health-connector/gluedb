puts "Report started at #{Time.now}"
policies = Policy.no_timeout.where(
  {"eg_id" => {"$not" => /DC0.{32}/},
   :enrollees => {"$elemMatch" =>
      {:rel_code => "self",
            :coverage_start => {"$gt" => Date.new(2015,12,31)}}}}
)

policies = policies.reject{|pol| pol.market == 'individual' && !pol.subscriber.nil? &&(pol.subscriber.coverage_start.year == 2014||pol.subscriber.coverage_start.year == 2015) }

enroll_list = File.read("all_enroll_policies.txt").split("\n").map(&:strip)

missing = []

policies.each do |policy|
  next if policy.hbx_enrollment_ids.blank?
  if policy.hbx_enrollment_ids.all?{|id| enroll_list.include?(id)} 
    next
  else
    missing << policy
  end
end

puts "Glue Total: #{policies.size}"
puts "Enroll Total: #{enroll_list.size}"
puts "Total Missing: #{missing.size}"


def bad_eg_id(eg_id)
  (eg_id =~ /\A000/) || (eg_id =~ /\+/)
end

# timestamp = Time.now.strftime('%Y%m%d%H%M')

# Caches::MongoidCache.with_cache_for(Carrier, Plan, Employer) do
#   CSV.open("enrollments_in_glue_but_not_in_enroll.csv","w") do |csv|
#     csv << ["Subscriber HBX ID", "Enrollee HBX ID", "Enrollment HBX ID", "First Name","Last Name","SSN","DOB","Gender","Relationship to Subscriber",
#             "Plan Name", "Plan HIOS ID", "Plan Metal Level", "Carrier Name",
#             "Premium for Enrollee", "Premium Total for Policy","APTC/Employer Contribution",
#             "Enrollee Coverage Start","Enrollee Coverage End",
#             "Employer Name","Employer DBA","Employer FEIN","Employer HBX ID",
#             "Home Address","Mailing Address","Home Email", "Work Email","Home Phone Number", "Work Phone Number", "Mobile Phone Number",
#             "Broker Name", "Broker NPN",
#             "AASM State"]
#   end
# end