count = 18942874
count_end = 19742873

$logger = Logger.new("#{Rails.root}/log/fix_hbx_member_id_#{Time.now.to_s.gsub(' ', '')}.log")
person_counter = 0

puts "Total persons #{Person.count}"

Person.all.each do |person|
  exit if count >= count_end

  if person.authority_member_id.present?
    if person.authority_member_id.include? 'concern_role'
      member = person.members.first
      person.authority_member_id = count
      member.hbx_member_id = count
      person.save!
      $logger.info "Fixed #{person.id} #{person.authority_member_id} #{member.hbx_member_id} #{count}"
      count = count + 1
    else
      $logger.info "Not fixed #{person.id} #{person.authority_member_id}"
    end
  end
end
