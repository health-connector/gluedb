# Builds CV1s of enrollments using a text file as input.

initials_filename = 'initial_enrollments.txt'

renewals_filename = 'renewal_enrollments.txt'

unless initials_filename.blank?
  initial_eg_ids = File.read(initials_filename).split("\n").map(&:strip)
  initial_policies = Policy.where(:eg_id => {"$in" => initial_eg_ids})
end

unless renewals_filename.blank?
  renewal_eg_ids = File.read(renewals_filename).split("\n").map(&:strip)
  renewal_policies = Policy.where(:eg_id => {"$in" => renewal_eg_ids})
end

policies = initial_policies.to_a + renewal_policies.to_a

m_ids = []

policies.each do |pol|
  pol.enrollees.each do |en|
    m_ids << en.m_id
  end
end

m_cache = Caches::MemberCache.new(m_ids)

Caches::MongoidCache.allocate(Plan)
Caches::MongoidCache.allocate(Carrier)

unless initial_policies.size == 0
  initial_policies.each do |pol|
    subscriber_id = pol.subscriber.m_id
    subscriber_member = m_cache.lookup(subscriber_id)
    auth_subscriber_id = subscriber_member.person.authority_member_id
    enrollee_list = pol.enrollees.reject { |en| en.canceled? }
    all_ids = enrollee_list.map(&:m_id) | [subscriber_id]
    out_f = File.open(File.join("generated_cvs", "#{pol.eg_id}_initial.xml"), 'w')
    ser = CanonicalVocabulary::MaintenanceSerializer.new(pol,"add","initial_enrollment",all_ids,all_ids,{:member_repo => m_cache})
    out_f.write(ser.serialize)
    out_f.close
  end
end

unless renewal_policies.size == 0
  renewal_policies.each do |pol|
    subscriber_id = pol.subscriber.m_id
    subscriber_member = m_cache.lookup(subscriber_id)
    auth_subscriber_id = subscriber_member.person.authority_member_id
    enrollee_list = pol.enrollees.reject { |en| en.canceled? }
    all_ids = enrollee_list.map(&:m_id) | [subscriber_id]
    out_f = File.open(File.join("generated_cvs", "#{pol.eg_id}_renewal.xml"), 'w')
    ser = CanonicalVocabulary::MaintenanceSerializer.new(pol,"change","renewal",all_ids,all_ids,{:member_repo => m_cache})
    out_f.write(ser.serialize)
    out_f.close
  end
end