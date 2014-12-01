feins = []

emp_ids = Employer.where(:fein => { "$in" => feins } ).map(&:id)

calc = Premiums::PolicyCalculator.new

pols = Policy.where(PolicyStatus::Active.as_of(Date.parse('12/31/2014'), { "employer_id" => { "$in" => emp_ids }}).query)

p_id = 50000

pols.each do |pol|
  if pol.subscriber.coverage_end.blank?
    r_pol = pol.clone_for_renewal(Date.new(2015,1,1))
    calc.apply_calculations(r_pol)
    p_id = p_id + 1
    out_file = File.open("renewals/#{p_id}.xml", 'w')
    member_ids = r_pol.enrollees.map(&:m_id)
    r_pol.eg_id = p_id.to_s
    ms = CanonicalVocabulary::MaintenanceSerializer.new(r_pol,"change", "renewal", member_ids, member_ids)
    out_file.print(ms.serialize)
    out_file.close
  end
end
