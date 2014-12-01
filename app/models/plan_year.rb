class PlanYear
  include Mongoid::Document
  include Mongoid::Timestamps
#  include Mongoid::Versioning
  include MergingModel

  field :start_date, type: Date
  field :end_date, type: Date
  field :open_enrollment_start, type: Date
  field :open_enrollment_end, type: Date
  field :fte_count, type: Integer
  field :pte_count, type: Integer

  belongs_to :employer
  belongs_to :broker

  index({:employer_id => 1})
  index({:broker_id => 1})
  index({:start_date => 1})
  index({:end_date => 1})
  index({:employer_id => 1, :start_date => 1, :end_date => 1})
  index({:start_date => 1, :end_date => 1})
  index({:employer_id => 1, :open_enrollment_start => 1, :open_enrollment_end => 1})
  index({:open_enrollment_start => 1, :open_enrollment_end => 1})
  index({:open_enrollment_start => 1})
  index({:open_enrollment_end => 1})

  embeds_many :elected_plans

  has_one :contribution_strategy, :class_name => "EmployerContributions::Strategy", :inverse_of => :plan_year

  def self.make(data)
    plan_year = PlanYear.new
    plan_year.open_enrollment_start = data[:open_enrollment_start]
    plan_year.open_enrollment_end = data[:open_enrollment_end]
    plan_year.start_date = Date.parse(data[:start_date])
    plan_year.end_date = Date.parse(data[:end_date]) unless data[:end_date].blank?
    plan_year.broker = Broker.find_by_npn(data[:broker_npn])
    plan_year.fte_count = data[:fte_count]
    plan_year.pte_count = data[:pte_count]
    e_plans = []

    data[:plans].each do |plan_data|
      plan = Plan.find_by_hios_id_and_year(plan_data[:qhp_id], plan_year.start_date.year)
      raise plan_data[:qhp_id].inspect if plan.nil?
      e_plans << ElectedPlan.new(
        :carrier_id => plan.carrier_id,
        :qhp_id => plan_data[:qhp_id],
        :coverage_type => plan_data[:coverage_type],
        :metal_level => plan.metal_level,
        :hbx_plan_id => plan.hbx_plan_id,
        :original_effective_date => plan_data[:original_effective_date],
        :plan_name => plan.name,
        :carrier_policy_number => plan_data[:policy_number],
        :carrier_employer_group_id => plan_data[:group_id]
      )
    end
    plan_year.elected_plans.concat(e_plans)
    plan_year
  end

  def update_group_ids(carrier_id, g_id)
    plans_to_update = self.elected_plans.select do |ep|
      ep.carrier_id == carrier_id
    end
    plans_to_update.each do |ep|
      ep.carrier_employer_group_id = g_id
      ep.touch
      ep.save!
    end
  end

  def match(other)
    return false if other.nil?
    attrs_to_match = [:start_date, :end_date]
    attrs_to_match.all? { |attr| attribute_matches?(attr, other) }
  end

  def attribute_matches?(attribute, other)
    self[attribute] == other[attribute]
  end
end
