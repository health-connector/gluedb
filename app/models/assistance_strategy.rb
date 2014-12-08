class AssistanceStrategy
  include Mongoid::Document
  include Mongoid::Timestamps

  field :fiscal_year, type: String
end
