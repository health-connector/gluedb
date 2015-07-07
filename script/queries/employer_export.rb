require 'csv'

file = CSV.open("employer_export.csv", "w")
file << %w{ employer.name employer.name_first employer.name_middle employer.name_last employer.fein
            employer.addresses.address_1 employer.addresses.address_2 employer.addresses.city, employer.addresses.state employer.addresses.zip
            plan_year.start_date
            broker.name_first broker.name_last employer.broker.npn}

Employer.all.each do |employer|

  row = []

  employer.plan_years.each do |plan_year|
    row = [employer.name, employer.name_first, employer.name_middle, employer.name_last, employer.fein, employer.addresses.first.address_1, employer.addresses.first.address_2, employer.addresses.first.city, employer.addresses.first.state, employer.addresses.first.zip]
    row << plan_year.start_date
    row << plan_year.broker.name_first << plan_year.broker.name_last << plan_year.broker.npn if plan_year.broker
    file << row
  end
end
