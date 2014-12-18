class UpdatePersonAddressRequest
  def self.from_form(person_id, form, current_user)
    request = {
      person_id: person_id,
      current_user: current_user,
      addresses: []
    }

    form_addresses = form['addresses_attributes']
    form_addresses.each_value do |form_addr|
      request[:addresses] << {
        address_type: form_addr['address_type'],
        address_1: form_addr['address_1'],
        address_2: form_addr['address_2'],
        city: form_addr['city'],
        state: form_addr['state'],
        zip: form_addr['zip']
      }
    end

    # remove blank addresses, because rails assign_attributes removes them as well.
    to_remove = []
    request[:addresses].each do |a|
      if(a.values.all? {|x| x == ""})
        to_remove << a
      end
    end
    to_remove.each { |a| request[:addresses].delete(a) }
    
    request
  end


  def self.from_cv(payload)
    parser = Nokogiri::XML(payload)
    individual = Parsers::Xml::Reports::individual.new(parser.root)

    request = {
      person_id: individual.id,
      current_user: 'trey.evans@dc.gov',
      addresses: []
    }

    request[:addresses] = individual.addressses
    request
  end
end
