class CostSharingVariant
  include Mongoid::Document

  field :start_on, type: Date
  field :end_on, type: Date
  field :percent, type: BigDecimal, default: 0.00
  field :percent, type: BigDecimal, default: 0.00

  embedded_in :policy
end