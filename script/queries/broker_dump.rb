require 'csv'

brokers = Broker.all

CSV.open("all_brokers.csv", 'w') do |csv|
  csv << ["First Name", "Last Name", "NPN", "Address","Phone","Email"]
  brokers.each do |b|
    csv << [b.name_first,b.name_last, b.npn,b.addresses.first.try(:full_address), b.phones.first.try(:phone_number), b.emails.first.try(:email_address)]
  end
end
