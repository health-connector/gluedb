class PremiumPayment
  include Mongoid::Document

  field :pmt_amt, as: :payment_amount_in_cents, type: Integer
  field :paid_at, as: :check_issue_or_eft_effective_date, type: Date
  field :hbx_payment_type, type: String
	field :coverage_period, type: String

  field :start_date, as: :coverage_start_date, type: Date
  field :end_date, as: :coverage_end_date, type: Date

	belongs_to :employer, index: true  # Carrier-assigned Group ID or FEIN
  belongs_to :policy, index: true
	belongs_to :carrier, index: true
  belongs_to :transaction_set_premium_payment, :class_name => "Protocols::X12::TransactionSetPremiumPayment", index: true

  validates_presence_of :payment_amount_in_cents, :paid_at, :coverage_period, :policy_id, :carrier_id
  validates_inclusion_of :hbx_payment_type, in: ["BAL", "INTPREM", "PREM", "MISC", "NONPAYADJ", "PREMADJ",
"REFUND"]

  index({paid_at: 1})
  index({paid_at: 1, policy_id: 1})

	before_create :parse_coverage_period

  def self.payment_transactions_for(employer)
    c = Carrier.all.inject({}) do |acc, item|
      acc[item.id] = item
      acc
    end
    self.collection.aggregate(
        {"$match" =>{
            :employer_id => employer._id
          }},
        {"$group" =>{
            "_id" => {
            "paid_at" => "$paid_at",
            "carrier" => "$carrier_id"},
            "transaction_set_premium_payment" => {"$addToSet" =>"$transaction_set_premium_payment_id"},
            "payment_amount" => { "$sum" => "$pmt_amt" }
          }}
      ).map do |record|
        record.merge("carrier_name" => c[record["_id"]["carrier"]].name)
      end


  end

  def payment_amount_in_dollars=(dollars)
    self.payment_amount_in_cents = Rational(dollars) * Rational(100)
  end

  def payment_amount_in_dollars
    (Rational(payment_amount_in_cents) / Rational(100)).to_f if payment_amount_in_cents
  end

protected
		def parse_coverage_period
			return if self.coverage_period.empty?

			parts = self.coverage_period.partition("-")
	    self.start_date = parts[0].to_date
	    self.end_date = parts[2].to_date
		end
end
