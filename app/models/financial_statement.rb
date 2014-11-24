require 'active_support/time'

class FinancialStatement
  include Mongoid::Document
  include Mongoid::Timestamps

  TAX_FILING_STATUS_TYPES = %W(tax_filer tax_dependent non_filer)

  embedded_in :application_group

  field :tax_filing_status, type: String
  field :is_tax_filing_together, type: Boolean

  field :eligibility_determination_id, type: Moped::BSON::ObjectId
  field :applicant_link_id, type: Moped::BSON::ObjectId


  # Has access to employer-sponsored coverage that meets ACA minimum standard value and 
  #   employee responsible premium amount is <= 9.5% of Household income
  field :is_enrolled_for_es_coverage, type: Boolean, default: false
  field :is_without_assistance, type: Boolean, default: true
  field :submitted_date, type: DateTime

  index({submitted_date:  1})

  embeds_many :incomes
  accepts_nested_attributes_for :incomes

  embeds_many :deductions
  accepts_nested_attributes_for :deductions

  embeds_many :alternate_benefits
  accepts_nested_attributes_for :alternate_benefits

  validates :tax_filing_status,
    inclusion: { in: TAX_FILING_STATUS_TYPES, message: "%{value} is not a valid tax filing status" },
    allow_blank: true

  def parent
    raise "undefined parent ApplicationGroup" unless application_group? 
    self.application_group
  end

  def applicant_link=(al_instance)
    return unless al_instance.is_a? Applicantlink
    self.applicant_link_id = al_instance._id
  end

  def applicant_link
    parent.applicant_links.find(self.applicant_link_id) unless self.applicant_link_id.blank?
  end

  def eligibility_determination=(ed_instance)
    return unless ed_instance.is_a? EligibilityDetermination
    self.eligibility_determination_id = ed_instance._id
  end

  def eligibility_determination
    parent.eligibility_determination.find(self.eligibility_determination_id) unless self.eligibility_determination_id.blank?
  end

  # Evaluate if receiving Alternative Benefits this year
  def is_receiving_benefit?
    return_value = false

    alternate_benefits.each do |alternate_benefit|
      return_value = is_receiving_benefits_this_year?(alternate_benefit)
      break if return_value
    end

    return return_value
  end

  def compute_yearwise(incomes_or_deductions)
    income_deduction_per_year = Hash.new(0)

    incomes_or_deductions.each do |income_deduction|
      working_days_in_year = Float(52*5)
      daily_income = 0

      case income_deduction.frequency
        when "daily"
          daily_income = income_deduction.amount_in_cents
        when "weekly"
          daily_income = income_deduction.amount_in_cents / (working_days_in_year/52)
        when "biweekly"
          daily_income = income_deduction.amount_in_cents / (working_days_in_year/26)
        when "monthly"
          daily_income = income_deduction.amount_in_cents / (working_days_in_year/12)
        when "quarterly"
          daily_income = income_deduction.amount_in_cents / (working_days_in_year/4)
        when "half_yearly"
          daily_income = income_deduction.amount_in_cents / (working_days_in_year/2)
        when "yearly"
          daily_income = income_deduction.amount_in_cents / (working_days_in_year)
      end

      income_deduction.start_date = Date.today.beginning_of_year if income_deduction.start_date.to_s.eql? "01-01-0001" or income_deduction.start_date.blank?
      income_deduction.end_date   = Date.today.end_of_year if income_deduction.end_date.to_s.eql? "01-01-0001" or income_deduction.end_date.blank?
      years = (income_deduction.start_date.year..income_deduction.end_date.year)

      years.to_a.each do |year|
        actual_days_worked = compute_actual_days_worked(year, income_deduction.start_date, income_deduction.end_date)
        income_deduction_per_year[year] += actual_days_worked * daily_income
      end
    end

    income_deduction_per_year
  end

  # Compute the actual days a person worked during one year
  def compute_actual_days_worked(year, start_date, end_date)
    working_days_in_year = Float(52*5)

    if Date.new(year, 1, 1) < start_date
      start_date_to_consider = start_date
    else
      start_date_to_consider = Date.new(year, 1, 1)
    end

    if Date.new(year, 1, 1).end_of_year < end_date
      end_date_to_consider = Date.new(year, 1, 1).end_of_year
    else
      end_date_to_consider = end_date
    end

    # we have to add one to include last day of work. We multiply by working_days_in_year/365 to remove weekends.
    ((end_date_to_consider - start_date_to_consider + 1).to_i * (working_days_in_year/365)).to_i #actual days worked in 'year'
  end

  def is_receiving_benefits_this_year?(alternate_benefit)
    alternate_benefit.start_date = Date.today.beginning_of_year if alternate_benefit.start_date.blank?
    alternate_benefit.end_date =   Date.today.end_of_year if alternate_benefit.end_date.blank?
    (alternate_benefit.start_date.year..alternate_benefit.end_date.year).include? Date.today.year
  end

  def total_incomes_by_year
    incomes_by_year = compute_yearwise(incomes)
    deductions_by_year = compute_yearwise(deductions)

    years = incomes_by_year.keys | deductions_by_year.keys

    total_incomes = {}

    years.each do |y|
      income_this_year = incomes_by_year[y] || 0
      deductions_this_year = deductions_by_year[y] || 0
      total_incomes[y] = (income_this_year - deductions_this_year) * 0.01
    end
    total_incomes
  end

end
