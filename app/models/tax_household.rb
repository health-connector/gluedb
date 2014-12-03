class TaxHousehold
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :household

  auto_increment :hbx_assigned_id, seed: 9999  # Create 'friendly' ID to publish for other systems

  field :allocated_aptc_in_cents, type: Integer, default: 0
  field :is_eligibility_determined, type: Boolean, default: false

  index({_id: 1})

  embeds_many :tax_household_members
  accepts_nested_attributes_for :tax_household_members


  def allocated_aptc_in_dollars=(dollars)
    self.allocated_aptc_in_cents = (Rational(dollars) * Rational(100)).to_i
  end

  def allocated_aptc_in_dollars
    (Rational(allocated_aptc_in_cents) / Rational(100)).to_f if allocated_aptc_in_cents
  end

  # Income sum of all tax filers in this Household for specified year
  def total_incomes_by_year
    applicant_links.inject({}) do |acc, per|
      p_incomes = per.financial_statements.inject({}) do |acc, ae|
        acc.merge(ae.total_incomes_by_year) { |k, ov, nv| ov + nv }
      end
      acc.merge(p_incomes) { |k, ov, nv| ov + nv }
    end
  end

  #TODO: return count for adults (21-64), children (<21) and total
  def size
    members.size 
  end

  def is_eligibility_determined?
    self.is_eligibility_determined
  end

end
