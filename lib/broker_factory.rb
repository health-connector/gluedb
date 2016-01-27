require 'open-uri'
require 'nokogiri'
require './lib/exposes_broker_xml'

class BrokerFactory
  def create_many_from_xml(xml)
    brokers = []
    doc = Nokogiri::XML(xml)
    doc.css('brokers broker').each do |broker|
      brokers << create_broker(ExposesBrokerXml.new(broker))
    end

    brokers
  end

  def create_many_from_csv(csv)
    brokers = []
    csv.each do |broker|
      brokers << map_broker_data(broker)
    end

    brokers
  end

  def map_broker_data(broker_csv_row)
    broker = Broker.new(
      :npn => broker_csv_row[" NPN"].strip,
      :b_type => 'broker',
      :name_first => broker_csv_row[" First Name"].strip,
      :name_last => broker_csv_row[" Last Name"].strip,
      :name_full => broker_csv_row[" Full Name"].strip,
      :name_middle => (broker_csv_row[" Full Name"].strip.split(" ") - broker_csv_row[" First Name"].strip.to_a - broker_csv_row[" Last Name"].strip.to_a).first,
      :alternative_name => broker_csv_row[" Agency"].strip,
      )

    unless broker_csv_row[" Address 1"].strip.blank?
      broker.addresses << Address.new(
        :address_type => 'work',
        :address_1 => broker_csv_row[" Address 1"].strip,
        :address_2 => broker_csv_row[" Address 2"].strip,
        :city => broker_csv_row[" City"].strip,
        :state => broker_csv_row[" State"].strip,
        :zip => broker_csv_row[" Zip"].strip,
      )
    end

    unless broker_csv_row[" Phone"].strip.blank?
      broker.phones << Phone.new(
        :phone_type => 'work',
        :phone_number => broker_csv_row[" Phone"].strip.gsub(/[^0-9]/,""),
      )
    end

    unless broker_csv_row[" Email"].strip.blank?
      broker.emails << Email.new(
        :email_type => 'work',
        :email_address => broker_csv_row[" Email"].strip,
      )
    end

    broker
  end

  def create_broker(broker_data)
    broker = Broker.new(
      :npn => broker_data.npn.gsub(/[^0-9]/,""),
      :b_type => 'broker', # or tpa
      :name_pfx => broker_data.contact.prefix,
      :name_first => broker_data.contact.first_name,
      :name_middle => broker_data.contact.middle_initial,
      :name_last => broker_data.contact.last_name,
      :name_sfx => broker_data.contact.suffix
    )

    if !broker_data.contact.street1.blank?
      broker.addresses << create_address(broker_data.contact)
    end

    if !broker_data.contact.phone_number.blank?
      broker.phones << create_phones(broker_data.contact)
    end

    if !broker_data.contact.email_address.blank?
      broker.emails << create_emails(broker_data.contact)
    end

    broker
  end

  def create_address(contact_data)
    Address.new(
      :address_type => contact_data.address_type.downcase,
      :address_1 => contact_data.street1,
      :address_2 => contact_data.street2,
      :city => contact_data.city,
      :state => contact_data.state,
      :zip => contact_data.zip
      )
  end

  def create_phones(contact_data)
    Phone.new(
      :phone_type => contact_data.phone_type.downcase,
      :phone_number => contact_data.phone_number.gsub(/[^0-9]/,""),
    )
  end

  def create_emails(contact_data)
    Email.new(
      :email_type => contact_data.email_type.downcase,
      :email_address => contact_data.email_address,
    )
  end
end
