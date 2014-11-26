class Deduction
  include Mongoid::Document
  include Mongoid::Timestamps

  FREQUENCIES = %W(biweekly daily half_yearly monthly quarterly weekly yearly)

  KINDS = %W(
	  	alimony_paid
	  	deductable_part_of_self_employment_taxes
	  	domestic_production_activities
	  	penalty_on_early_withdrawel_of_savings
	  	educator_expenses
	  	rent_or_royalties
	  	self_employment_sep_simple_and_qualified_plans
	  	self_employed_health_insurance
	  	moving_expenses
	  	health_savings_account
	  	reservists_performing_artists_and_fee_basis_government_official_expenses
		)

  field :amount_in_cents, type: Integer, default: 0
  field :kind, as: :deduction_type, type: String
  field :frequency, type: String
  field :start_date, type: Date
  field :end_date, type: Date
  field :submission_date, type: DateTime

  embedded_in :financial_statement, inverse_of: :deductions

  validates :amount_in_cents, presence: true,
  														numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :kind, presence: true,
  												inclusion: { in: KINDS, message: "%{value} is not a valid deduction type" }
  validates :frequency, 	presence: true,
 												 	inclusion: { in: FREQUENCIES, message: "%{value} is not a valid frequency" }
#  validates :start_date, presence: true


  def amount_in_dollars=(dollars)
    self.amount_in_cents = Rational(dollars) * Rational(100)
  end

  def amount_in_dollars
    (Rational(amount_in_cents) / Rational(100)).to_f if amount_in_cents
  end


end
