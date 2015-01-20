require 'securerandom'

active_pols = Policy.where(Policy.active_as_of_expression(Date.new(2014, 12, 31)).merge({"employer_id" => nil, "responsible_party_id" => nil,
"applied_aptc" => {"$in" => ["0", "0.0", "0.00"]}
}))

def create_me_a_group(sub, people)
  Family.create!(
    :primary_applicant_id => sub,
    :person_ids => people
  )
end

def add_people_to_group(group, people_ids)
  group.person_ids  = group.person_ids & people_ids
  group.save!
end


active_pols.each do |pol|
  sub = pol.subscriber.person.id
  member_people = pol.enrollees.map { |en| en.person.id }
  ags = Family.where(
    :person_ids => {
      "$elemMatch" => { "$in" => [sub]}
    }
  )
  case ags.count
  when 0
    application_group = create_me_a_group(sub, member_people)
    pol.application_group = ags.first
    pol.save!
  when 1
    ag = ags.first
    add_people_to_group(ag, member_people)
    pol.application_group = ag
    pol.save
  else
  end
end
