require File.join(Rails.root, "script/queries/policy_id_generator")

feins = [
]

emp_ids = Employer.where(:fein => { "$in" => feins } ).map(&:id)

pols_mems = Policy.where(PolicyStatus::Active.as_of(Date.new(2015,6,30)).query).where({ "employer_id" => { "$in" => emp_ids }})
pols = Policy.where(PolicyStatus::Active.as_of(Date.new(2015,6,30)).query).where({ "employer_id" => { "$in" => emp_ids }}).no_timeout

m_ids = []

pols_mems.each do |mpol|
  mpol.enrollees.each do |en|
    m_ids << en.m_id
  end
end

member_repo = Caches::MemberCache.new(m_ids)
calc = Premiums::PolicyCalculator.new(member_repo)
Caches::MongoidCache.allocate(Employer)
Caches::MongoidCache.allocate(Plan)
Caches::MongoidCache.allocate(Carrier)

polgen = PolicyIdGenerator.new(10)

FileUtils.rm_rf(Dir.glob('renewals/*'))

pols.each do |pol|
  if pol.subscriber.coverage_end.blank?
    sub_member = member_repo.lookup(pol.subscriber.m_id)
    authority_member = sub_member.person.authority_member
    if authority_member.blank?
      puts "No authority member for: #{pol.subscriber.m_id}"
    else
      if (sub_member.person.authority_member.hbx_member_id == pol.subscriber.m_id)
        begin
          r_pol = pol.clone_for_renewal(Date.new(2015,7,1))
          calc.apply_calculations(r_pol)
          p_id = polgen.get_id
          out_file = File.open("renewals/#{p_id}.xml",'w')
          member_ids = r_pol.enrollees.map(&:m_id)
          r_pol.eg_id = p_id.to_s
          ms = CanonicalVocabulary::MaintenanceSerializer.new(r_pol,"change", "renewal", member_ids, member_ids, {:member_repo => member_repo})
          out_file.print(ms.serialize)
          out_file.close
        rescue
          puts pol.inspect
        end
      end
    end
  end
end

Caches::MongoidCache.release(Plan)
Caches::MongoidCache.release(Carrier)
Caches::MongoidCache.release(Employer)
