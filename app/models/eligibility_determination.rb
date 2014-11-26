class EligibilityDetermination
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :application_group

  field :e_pdc_id, type: String
  field :household_state, type: String
  field :benchmark_plan_id, type: Moped::BSON::ObjectId

  # Premium tax credit assistance eligibility.  
  # Available to household with income between 100% and 400% of the Federal Poverty Level (FPL)
  field :max_aptc_in_cents, type: Integer, default: 0

  # Cost-sharing reduction assistance eligibility for co-pays, etc.  
  # Available to households with income between 100-250% of FPL and enrolled in Silver plan.
  field :csr_percent_as_integer, type: Integer, default: 0  #values in DC: 0, 73, 87, 94

  field :determination_date, type: DateTime
  include ApplicantGrouping

  validates_presence_of :determination_date, :max_aptc_in_cents, :csr_percent_as_integer
  validates :csr_percent_as_integer,
              allow_nil: true, 
              numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def parent
    raise "undefined parent ApplicationGroup" unless application_group? 
    self.application_group
  end

  # embedded has_many :hbx_enrollments
  def hbx_enrollments
    parent.hbx_enrollments.where(:eligibility_determination_id => self.id)
  end

  # embedded has_many :financial_statement
  def financial_statements
    parent.financial_statements.where(:eligibility_determination_id => self.id)
  end

  def benchmark_plan=(benchmark_plan_instance)
    return unless benchmark_plan_instance.is_a? Plan
    self.benchmark_plan_instance_id = benchmark_plan_instance._id
  end

  def benchmark_plan
    Plan.find(self.benchmark_plan_instance_id) unless self.benchmark_plan_instance_id.blank?
  end

  def max_aptc_in_dollars=(dollars)
    self.max_aptc_in_cents = Rational(dollars) * Rational(100)
  end

  def max_aptc_in_dollars
    (Rational(max_aptc_in_cents) / Rational(100)).to_f if max_aptc_in_cents
  end

  def csr_percent=(value)
    raise "value out of range" if (value < 0 || value > 1)
    self.csr_percent_as_integer = Rational(value) * Rational(100)
  end

  def csr_percent
    (Rational(csr_percent_as_integer) / Rational(100)).to_f
  end

end
