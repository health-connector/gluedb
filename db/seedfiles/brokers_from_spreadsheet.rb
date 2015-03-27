require 'csv'

brokercsv =  CSV.read("./db/seedfiles/brokers/Brokers4-1.csv", headers: true)

ImportBrokers.from_csv(brokercsv)
