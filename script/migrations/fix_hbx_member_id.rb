count = 18775316
$logger = Logger.new("#{Rails.root}/log/fix_hbx_member_id_#{Time.now.to_s.gsub(' ', '')}.log")
person_counter = 0

puts "Total persons #{Person.count}"
persons = Person.where(:created_at.gte => (Date.today - 1))
puts "Person.count #{persons.count}"

persons.each do |person|
  person_counter = person_counter + 1
  puts "person_counter #{person_counter}"

  if person.authority_member_id.present?
    if person.authority_member_id.include? 'concern_role'
      member = person.members.first
      $logger.info "Fixed #{person.created_at} #{person.id} #{person.authority_member_id} #{member.hbx_member_id} #{count}"
      person.authority_member_id = count
      member.hbx_member_id = count
      count = count + 1
      person.save!
    else
      $logger.info "Not fixed #{person.id} #{person.authority_member_id}"
    end
  end
end
