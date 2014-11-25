class Income
  include Mongoid::Document
  include Mongoid::Timestamps

  KINDS = %W(
  	alimony_and_maintenance
		american_indian_and_alaskan_native
		capital_gains
		dividend
		employer_funded_disability
		estate_trust
		farming_and_fishing
		foreign
		interest
		lump_sum_amount
		military
		net_self_employment
		other
		pension_retirement_benefits
		permanent_workers_compensation
		prizes_and_awards
		rental_and_royalty
		scholorship_payments
		social_security_benefit
		supplemental_security_income
		tax_exempt_interest
		unemployment_insurance
		wages_and_salaries
	)

  FREQUENCIES = %W(biweekly daily half_yearly monthly quarterly weekly yearly)

  field :amount_in_cents, type: Integer, default: 0
  field :kind, as: :income_type, type: String
  field :frequency, type: String
  field :start_date, type: Date
  field :end_date, type: Date
  field :is_projected, type: Boolean, default: false
  field :submission_date, type: DateTime

  embedded_in :assistance_eligibility, :inverse_of => :incomes

  validates :amount_in_cents, presence: true,
  														numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :kind, presence: true,
  												inclusion: { in: KINDS, message: "%{value} is not a valid income type" }
  validates :frequency, 	presence: true,
 												 	inclusion: { in: FREQUENCIES, message: "%{value} is not a valid frequency" }
#  validates :start_date, presence: true


  def amount_in_dollars=(dollars)
    self.amount_in_cents = Rational(dollars) * Rational(100)
  end

  def amount_in_dollars
    (Rational(amount_in_cents) / Rational(100)).to_f if amount_in_cents
  end

  def same_as?(other)
    amount_in_cents == other.amount_in_cents \
      && kind == other.kind \
      && frequency == other.frequency \
      && start_date == other.start_date \
      && end_date == other.end_date \
      && is_projected == other.is_projected \
      && submission_date == other.submission_date
  end

  def self.from_income_request(income_data)
    income = Income.new(
      amount_in_cents: (income_data[:amount] * 100).to_i,
      kind: income_data[:kind],
      frequency: income_data[:frequency],
      start_date: income_data[:start_date],
      end_date: income_data[:end_date],
      is_projected: income_data[:is_projected],
      submission_date: income_data[:submission_date])

  end

end
