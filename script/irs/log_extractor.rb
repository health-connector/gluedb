@logger = Logger.new("#{Rails.root}/log/log_dups_#{Time.now.to_s.gsub(' ', '')}.log")

@family_hash = {}

puts "Family hash creating..."

Family.all.each do |family|
  @family_hash[family.primary_applicant.person.id] = family.e_case_id if !family.primary_applicant.nil?
end

puts "Family hash created. Families in DB #{Family.count}, Size of hash #{@family_hash.keys.length}"

@logger.info "Glue E_case_id Duplicate E_case_id Name First Name Last Ssn}"

File.open('/Users/CitadelFirm/Downloads/log-dups.log', 'rb').each do |line|
  if !line.match('Duplicate Primary Applicant person_id').nil?
      parts = line.split(' message:Duplicate Primary Applicant person_id : ')
      e_case_id = parts[0].split('e_case_id:')[1]
      person_id = parts[1].gsub(/\n/,'')

      person = Person.find(person_id)

      glue_e_case_id = @family_hash[person.id]

      if glue_e_case_id.blank?
        @logger.info "error #{e_case_id} #{person.name_first} #{person.name_last} #{person.authority_member.ssn}"
        next
      end

      @logger.info "#{glue_e_case_id} #{e_case_id} #{person.name_first} #{person.name_last} #{person.authority_member.ssn}"
  end
end