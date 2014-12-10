module Policies
  class CreatePolicy

    def initialize(policy_factory = Policy, premium_validator = Premiums::PolicyRequestValidator.new)
      @policy_factory = policy_factory
      @premium_validator = premium_validator
    end

    # TODO: Introduce premium validations and employers!
    def validate(request, listener)
      failed = false
      eg_id = request[:enrollment_group_id]
      hios_id = request[:hios_id]
      plan_year = request[:plan_year]
      broker_npn = request[:broker_npn]
      enrollees = request[:enrollees].dup.map { |val| val.reject { |k,v| k == :member } }
      employer_fein = request[:employer_fein]
      existing_policy = @policy_factory.find_for_group_and_hios(eg_id, hios_id)
      if !existing_policy.blank?
        listener.policy_already_exists({
          :enrollment_group_id => eg_id,
          :hios_id => hios_id
        })
        fail = true
      end
      if !employer_fein.blank?
        employer = Employer.find_for_fein(employer_fein)
        if employer.blank?
          listener.employer_not_found(:fein => employer_fein)
          fail = true
        end
      end
      if !broker_npn.blank?
        broker = Broker.find_by_npn(broker_npn)
        if broker.blank?
          listener.broker_not_found(:npn => broker_npn)
          fail = true
        end
      end
      plan = Plan.find_by_hios_id_and_year(hios_id, plan_year)
      if plan.blank?
        listener.plan_not_found(:hios_id => hios_id, :plan_year => plan_year)
        return false
      end
      policy = @policy_factory.new(request.merge({:plan => plan, :carrier => plan.carrier}))
      if !policy.valid?
        listener.invalid_policy(policy.errors.to_hash)
        fail = true
      end
      if enrollees.blank?
        listener.no_enrollees
        fail = true
      end
      return false if fail
      @premium_validator.validate(request, listener)
    end

    # TODO: Cancel the policies we should be cancelling
    def commit(request, listener)
      hios_id = request[:hios_id]
      plan_year = request[:plan_year]
      broker_npn = request[:broker_npn]
      employer_fein = request[:employer_fein]

      plan = Plan.find_by_hios_id_and_year(hios_id, plan_year)
      broker = nil
      employer = nil
      if !broker_npn.blank?
        broker = Broker.find_by_npn(broker_npn)
      end
      if !employer_fein.blank?
        employer = Employer.find_for_fein(employer_fein)
      end

      policy = @policy_factory.create!(request.merge({
        :plan => plan,
        :carrier => plan.carrier,
        :broker => broker,
        :employer => employer
      }))
      listener.policy_created(policy.id)
      cancel_others(policy, listener)
    end

    def cancel_others(policy, listener)
      sub = policy.subscriber
      sub_person = sub.person
      coverage_start = sub.coverage_start
      cancel_policies = sub_person.policies.select do |pol|
        (pol.coverage_type == policy.coverage_type) &&
          (pol.policy_start == coverage_start) &&
          pol.active_as_of?(coverage_start) &&
          (pol.id != policy.id)
      end
      cancel_policies.each do |cpol|
        cpol.cancel_via_hbx!
        listener.policy_canceled(cpol.id)
      end
    end
  end
end
