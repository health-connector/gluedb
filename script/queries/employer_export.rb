require 'csv'
require 'pry'

timestamp = Time.now.strftime('%Y%m%d%H%M')

file = CSV.open("employer_export_#{timestamp}.csv", "w")
file << %w{ employer.name employer.hbx_id employer.name_first employer.name_middle employer.name_last employer.fein
            employer.addresses.address_1, employer.addresses.address_2, employer.addresses.city, employer.addresses.state, employer.addresses.zip, employer.phones.phone_number, employer.emails.email_address
            plan_year.start_date, 
            broker.name_first broker.name_last employer.broker.npn}

Employer.all.each do |employer|

  row = []

  employer.plan_years.each do |plan_year|
    row = [employer.name, employer.hbx_id, employer.name_first, employer.name_middle, employer.name_last, employer.fein, employer.addresses.last.address_1, employer.addresses.last.address_2, employer.addresses.last.city, employer.addresses.last.state, employer.addresses.last.zip, employer.phones.last.try(:phone_number), employer.emails.try(:last).try(:email_address)]
    row << plan_year.start_date
    row << plan_year.broker.name_first << plan_year.broker.name_last << plan_year.broker.npn if plan_year.broker
    file << row
  end
end
