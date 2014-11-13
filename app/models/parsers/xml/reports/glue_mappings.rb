module Parsers::Xml::Reports
  class GlueMappings

    def email
      {:type => :email_type}
    end

    def phone
      {:type => :phone_type}
    end

    def address
      {
        :type => :address_type, 
        :address_line_1=>:address_1, 
        :address_line_2=>:address_2, 
        :location_city_name=>:city, 
        :location_state=>:state,
        :location_postal_code=>:zip
      }
    end

    def demographics
      {
        :sex => :gender,
        :birth_date => :dob
      }
    end
  end
end