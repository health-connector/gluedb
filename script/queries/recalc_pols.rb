pol_ids = %w[

]

calc = Premiums::PolicyCalculator.new

pols = Policy.where({ "id" => {"$in" => pol_ids} })

pols.each do |pol|
  if pol.canceled?
    puts "#{pol.id} - canceled"
  elsif pol.terminated?
    puts "#{pol.id} - terminated"
  else
    prev = pol.employer_contribution
    calc.apply_calculations(pol)
    puts "#{pol.id} - recalced #{prev}:#{pol.employer_contribution}"
    out_f = File.open(File.join("recalc", "#{pol._id}_recalced.xml"), 'w')
    ser = CanonicalVocabulary::MaintenanceSerializer.new(
      pol,
      "change",
      "benefit_selection",
      pol.enrollees.map(&:m_id),
      pol.enrollees.map(&:m_id),
    )
    out_f.write(ser.serialize)
    out_f.close
  end
end

