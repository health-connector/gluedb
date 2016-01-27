bad_cons = EmployerContributions::DistrictOfColumbiaEmployer.all.select{ |con| con.employee_max_percent.to_f > 1.0}
emp_ids = bad_cons.map{|con| con.plan_year.employer_id}
bad_pols = Policy.where({
                "employer_id" => {"$in" => emp_ids},
                created_at:
                {
                  "$gte" => DateTime.new(2015,03,19,00),
                  "$lt" => DateTime.new(2015,03,21,00)
                }
            })

calc = Premiums::PolicyCalculator.new

bad_cons.each do |con|
  con.employee_max_percent *= 0.01
  con.dependent_max_percent *= 0.01
  con.save!
end

bad_pols.each do |pol|
  unless pol.canceled?
    out_f = File.open(File.join("bad", "#{pol._id}_recalced.xml"), 'w')
    puts "pre: #{pol.tot_emp_res_amt}"
    begin
      calc.apply_calculations(pol)
    rescue NoMethodError => e
      puts "crashing: #{pol._id}"
      pol.plan_year = "2014"
      correct = Plan.find_by_hios_id_and_year(pol.plan.hios_plan_id,2014)
      pol.plan = correct
      pol.save!
      calc.apply_calculations(pol)
    end
    puts "post: #{pol.tot_emp_res_amt}"
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
