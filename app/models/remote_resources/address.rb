module RemoteResources
  class Address
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'address'
    namespace 'cv'

    element :type, String, tag: "type"
    element :address_line_1, String, tag: "address_line_1"
    element :address_line_2, String, tag: "address_line_2"
    element :location_city_name, String, tag: "location_city_name"
    element :location_state_code, String, tag: "location_state_code"
    element :postal_code, String, tag: "postal_code"

    def address_kind
      Maybe.new(type).split("#").last.downcase.value
    end
  end
end
