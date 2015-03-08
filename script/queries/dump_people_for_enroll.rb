def dump_person(person)
  if !person.authority_member.blank?
    auth_member = person.authority_member
    json_data = {
      :id => person.id.to_s,
      :hbx_id => auth_member.hbx_member_id,
      :name_pfx => person.name_pfx,
      :first_name => person.name_first,
      :middle_name => person.name_middle,
      :last_name => person.name_last,
      :name_sfx => person.name_sfx,
      :ssn => auth_member.ssn,
      :dob => auth_member.dob,
      :gender => auth_member.gender,
      :addresses => [],
      :phones => [],
      :emails => []
    }
    person.emails.each do |email|
      json_data[:emails] << {
        :kind => email.email_type,
        :address => email.email_address
      }
    end
    person.phones.each do |phone|
      json_data[:phones] << {
        :kind => phone.phone_type,
        :full_phone_number => phone.phone_number
      }
    end
    person.addresses.each do |address|
      address_data = {
        :kind => address.address_type,
        :address_1 => address.address_1,
        :city => address.city,
        :state => address.state,
        :zip => address.zip
      }
      if !address.address_2.blank?
         address_data[:address_2] = address.address_2
      end
      json_data[:addresses] << address_data
    end
    puts JSON.dump(json_data)
  end
end

pols = Policy.where({
    :enrollees => {"$elemMatch" => {
          :rel_code => "self",
          :coverage_start => {"$gt" => Date.new(2014,12,31)}
    }}})

member_ids = []

pols.each do |pol|
  if !pol.canceled?
    pol.enrollees.each do |en|
      if !en.canceled?
        member_ids << en.m_id
      end
    end
  end
end

member_ids.uniq!

people = Person.find_for_members(member_ids)

puts "["
people.each do |person|
  dump_person(person)
  puts ","
end
