def dump_person(person, rel_map, member_cache, dumped_people, person_file, family_file)
  p_id = person.id.to_s
  if !person.authority_member.blank?
    if !dumped_people.include?(p_id)
      new_family = {
        :application_type => "employer_sponsored",
        :family_members => [
          {
            :person_id => person.id.to_s,
            :is_primary_applicant => true
          }
        ],
        :households => [
          {
            :coverage_households => [
              {
                :coverage_household_members => [
                  {
                    :family_member_id => person.id.to_s,
                    :is_subscriber => true
                  } 
                ]
              }
            ]
          }
        ]
      }
      dumped_people << p_id
      auth_member = person.authority_member
      mem_ids = person.members.map(&:hbx_member_id)
      json_data = {
        :id => person.id.to_s,
        :hbx_id => auth_member.hbx_member_id,
        :first_name => person.name_first,
        :last_name => person.name_last,
        :dob => auth_member.dob,
        :gender => auth_member.gender,
        :addresses => [],
        :phones => [],
        :emails => [],
        :person_relationships => []
      }
      if !person.name_pfx.blank?
        json_data[:name_pfx] = person.name_pfx
      end
      if !person.name_sfx.blank?
        json_data[:name_sfx] = person.name_sfx
      end
      if !person.name_middle.blank?
        json_data[:middle_name] = person.name_middle
      end
      if !(["999999999", "000000000"].include?(auth_member.ssn))
        if !auth_member.ssn.blank?
          json_data[:ssn] = auth_member.ssn
        end
      end
      person.emails.each do |email|
        json_data[:emails] << {
          :kind => email.email_type,
          :address => email.email_address
        }
      end
      person.phones.each do |phone|
        if !phone.phone_number.blank?
          if (phone.phone_number.length == 10) 
            json_data[:phones] << {
              :kind => phone.phone_type,
              :full_phone_number => phone.phone_number
            }
          end
        end
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
      relationships = []
      mem_ids.each do |m_id|
        rel_map[m_id].each do |rel|
          member_rel_id = member_cache.lookup(rel[:member_id]).id.to_s
          relationships << {
            :kind => rel[:kind],
            :relative_id => member_rel_id
          }
        end
      end
      relationships.uniq.each do |rel|
        json_data[:person_relationships] << rel
        new_family[:family_members] << {
             :person_id => rel[:relative_id]
        }
        new_family[:households][0][:coverage_households][0][:coverage_household_members] << {
             :family_member_id => rel[:relative_id]
        }
      end
      family_file.puts JSON.dump(new_family)
      family_file.puts ","
      person_file.puts JSON.dump(json_data)
      person_file.puts ","
    end
  end
end

pols = Policy.where({
  :enrollees => {"$elemMatch" => {
    :rel_code => "self",
    :coverage_start => {"$gt" => Date.new(2014,12,31)}
  }}, :employer_id => { "$ne" => nil }})

member_ids = []
relationship_map = Hash.new do |hash,key|
  hash[key] = Array.new
end

pols.each do |pol|
  if !pol.canceled?
    sub_id = pol.subscriber.m_id
    pol.enrollees.each do |en|
      if !en.canceled?
        member_ids << en.m_id
        if (en.m_id != sub_id)
          relationship_map[sub_id] << {
            :kind => en.rel_code,
            :member_id => en.m_id
          }
        end
      end
    end
  end
end

# raise relationship_map.inspect
people_file = File.open("people.json", 'w')
families_file = File.open("families.json", 'w')

member_ids.uniq!

m_cache = Caches::MemberIdPerson.new(member_ids)
people = Person.find_for_members(member_ids)
dumped_peeps = []

people_file.puts "["
families_file.puts "["
people.each do |person|
  dump_person(person, relationship_map, m_cache, dumped_peeps, people_file, families_file)
end

people_file.close
families_file.close
