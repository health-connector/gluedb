class AptcMaximum
  include Mongoid::Document

  field :start_on, type: Date
  field :end_on, type: Date
  field :max_aptc, type: BigDecimal, default: 0.00
  field :aptc_percent, type: BigDecimal, default: 0.00

  embedded_in :policy
end