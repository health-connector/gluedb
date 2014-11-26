module Parsers::Xml::Cv

  class AddressParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'address'
    namespace 'cv'

    element :type, String, tag: "type"
    element :address_line_1, String, tag: "address_line_1"
    element :address_line_2, String, tag: "address_line_2"
    element :location_state, String, tag: "location_state"
    element :location_city_name, String, tag: "location_city_name"
    element :location_state_code, String, tag: "location_state_code"
    element :location_postal_code, String, tag: "location_postal_code"
    element :location_postal_extension_code, String, tag: "location_postal_extension_code"
    element :location_country_name, String, tag: "location_country_name"
    element :location_country_code, String, tag: "location_country_code"
    element :address_full_text, String, tag: "address_full_text"
    element :location, String, tag: "location"

    def request_hash
      {
          type: type,
          address1: address_line_1,
          address2: address_line_2,
          city: location_city_name,
          state: location_state_code,
          zip: location_postal_code,
      }
    end
  end
end