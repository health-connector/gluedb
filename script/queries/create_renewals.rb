feins = []

emp_ids = Employer.where(:fein => { "$in" => feins } ).map(&:id)


pols_mems = Policy.where(PolicyStatus::Active.as_of(Date.parse('12/31/2014'), { "employer_id" => { "$in" => emp_ids }}).query)
pols = Policy.where(PolicyStatus::Active.as_of(Date.parse('12/31/2014'), { "employer_id" => { "$in" => emp_ids }}).query).no_timeout

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

p_id = 50000

pols.each do |pol|
  if pol.subscriber.coverage_end.blank?
    r_pol = pol.clone_for_renewal(Date.new(2015,1,1))
    calc.apply_calculations(r_pol)
    p_id = p_id + 1
    out_file = File.open("renewals/#{p_id}.xml", 'w')
    member_ids = r_pol.enrollees.map(&:m_id)
    r_pol.eg_id = p_id.to_s
    ms = CanonicalVocabulary::MaintenanceSerializer.new(r_pol,"change", "renewal", member_ids, member_ids, {:member_repo => member_repo})
    out_file.print(ms.serialize)
    out_file.close
  end
end

Caches::MongoidCache.release(Plan)
Caches::MongoidCache.release(Carrier)
Caches::MongoidCache.release(Employer)

