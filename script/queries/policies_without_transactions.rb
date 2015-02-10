require 'csv'

pols = Policy.all.select{ |p| p.transaction_list.empty? }

ids = []

pols.each{ |p| ids << p.enrollees.map(&:m_id) }

ids = ids.flatten

ppl = Person.find_for_members(ids)

pwt = []

ppl.each{ |person| pwt << person.policies.select{ |p| !p.transaction_list.empty? && p.created_at.day >= 19 }}

pwt = pwt.flatten.uniq

puts pwt.length

CSV.open("saadi_query.csv", 'w') do |csv|
  csv << ["policy ID","Employer Name","Employer FEIN","Last Name","First Name", "DOB", "# of Dependants", "Carrier", "Filename"]

  pwt.each do |p|
    transactions = p.transaction_list.select{ |t| t.transaction_kind == "maintenance" }
    fn = transactions.map(&:body)
    employer_name = p.employer.nil? ? " IVL " : p.employer.name
    employer_fein = p.employer.nil? ? " IVL " : p.employer.fein
    csv << [p.id, employer_name,employer_fein,p.subscriber.person.name_last, p.subscriber.person.name_first, p.subscriber.person.authority_member.dob, p.enrollees.count - 1, p.carrier.name,fn]
  end
end
