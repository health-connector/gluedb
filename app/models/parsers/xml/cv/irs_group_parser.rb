module Parsers::Xml::Cv
  class IrsGroupParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'irs_group'
    namespace 'cv'

    element :id, String, tag: 'id'
    has_many :tax_households_ids, String, tag:'tax_households_ids'

  end
end