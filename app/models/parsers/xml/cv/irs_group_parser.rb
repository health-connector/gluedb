module Parsers::Xml::Cv
  class IrsGroupParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'irs_group'
    namespace 'cv'

    element :id, String, tag: 'id'
    has_many :tax_households_ids, String, tag:'tax_households_ids'

    def to_hash
      {
          id: id,
          tax_households_ids: tax_households_ids.map do |tax_households_id|
            tax_households_id.to_hash
          end
      }
    end

  end
end