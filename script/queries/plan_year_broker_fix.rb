employer = Employer.where(:broker_id.exists => true)

employer.each do |e|
  e.plan_years.each do |py|
    if py.start_date.year == 2014 && py.broker.nil?
      py.broker = e.broker
      py.save!
    end
  end
end
