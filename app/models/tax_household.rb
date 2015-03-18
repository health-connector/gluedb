class TaxHousehold
  include Mongoid::Document
  include Mongoid::Timestamps
  include HasFamilyMembers

  # A set of applicants, grouped according to IRS and ACA rules, who are considered a single unit
  # when determining eligibility for Insurance Assistance and Medicaid

  embedded_in :household

  auto_increment :hbx_assigned_id, seed: 9999  # Create 'friendly' ID to publish for other systems

  field :allocated_aptc_in_cents, type: Integer, default: 0
  field :is_eligibility_determined, type: Boolean, default: false

  field :effective_start_date, type: Date
  field :effective_end_date, type: Date
  field :submitted_at, type: DateTime
  field :primary_applicant_id, type: Moped::BSON::ObjectId

  index({hbx_assigned_id: 1})

  embeds_many :tax_household_members
  accepts_nested_attributes_for :tax_household_members

  embeds_many :eligibility_determinations


  # *IMP* Check for tax members with financial information missing

  def members_with_financials
    tax_household_members.reject{|m| m.financial_statements.empty? }
  end

  def build_tax_family
    family = {}
    family[:primary] = primary
    family[:spouse] = spouse
    family[:dependents] = dependents
  end

  def associated_policies
    policies = []

    household.hbx_enrollments.each do |enrollment|

      if pol.subscriber.coverage_start > Date.new((date.year - 1),12,31) && pol.subscriber.coverage_start < Date.new(date.year,12,31)
        policy_disposition = PolicyDisposition.new(pol)
        coverages << pol if (policy_disposition.start_date.month..policy_disposition.end_date.month).include?(date.month)
      end
    end
    policies
  end

  def no_tax_filer?
    members_with_financials.detect{|m| m.financial_statements[0].tax_filing_status == 'tax_filer' }.nil?
  end

  # def coverage_as_of(date)
  #   # pols = []
  #   # members_with_financials.select{|m|
  #   #    pols += m.family_member.person.policies
  #   # }
  #   pols = household.hbx_enrollments.select{|x| x.policy }
  #   coverages = []
  #   pols.uniq.select do |pol|
  #     if pol.subscriber.coverage_start > Date.new((date.year - 1),12,31) && pol.subscriber.coverage_start < Date.new(date.year,12,31)
  #       policy_disposition = PolicyDisposition.new(pol)
  #       coverages << pol if (policy_disposition.start_date.month..policy_disposition.end_date.month).include?(date.month)
  #     end
  #   end

  #   coverages.map{|x| x.id}
  # end

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

  def family
    return nil unless household
    household.family
  end

  def is_eligibility_determined?
    if self.elegibility_determinizations.size > 0
      true
    else
      false
    end
  end

  #primary applicant is the tax household member who is the subscriber
  def primary_applicant
    tax_household_members.detect do |tax_household_member|
      tax_household_member.is_subscriber == true
    end
  end
end
