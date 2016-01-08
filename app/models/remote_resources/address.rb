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

    def address_1
      address_line_1
    end

    def address_2
      address_line_2
    end

    def city
      location_city_name
    end

    def state
      location_state_code
    end

    def zip
      postal_code
    end

    def address_type
      address_kind
    end

    def address_kind
      Maybe.new(type).split("#").last.downcase.value
    end
  end
end
