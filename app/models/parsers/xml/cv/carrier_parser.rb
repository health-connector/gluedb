module Parsers::Xml::Cv

  class CarrierParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'carrier'
    namespace 'cv'

    element :id, String, tag: "id/cv:id"
    element :name, String, tag: "name"
    element :is_active, String, tag: "is_active"

    def to_hash
      {
          id: id,
          name: name,
          is_active: is_active
      }
    end
  end
end