class AptcCredit
  include Mongoid::Document

  field :start_on, type: Date
  field :end_on, type: Date
  field :aptc, type: BigDecimal, default: 0.00
  field :pre_amt_tot, type: BigDecimal, default: 0.00
  field :tot_res_amt, type: BigDecimal, default: 0.00

  validates_presence_of :start_on, :end_on

  embedded_in :policy
end
