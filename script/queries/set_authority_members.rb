require 'csv'

no_authority_ids = Person.where({
 "members.0" => { "$exists" => true },            
 "members.1" => { "$exists" => false },
 "authority_member_id" => nil
})

puts no_authority_ids.count
CSV.open("funky_authority_ids", 'w') do |csv|
  no_authority_ids.each do |per|
    csv << [per.name_first, per.name_middle, per.name_last]
  end
end

no_authority_ids.each do |nap|
  nap.authority_member_id = nap.members.first.hbx_member_id
  nap.save!
end
