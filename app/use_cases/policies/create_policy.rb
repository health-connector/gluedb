module Policies
  class CreatePolicy

    def initialize(policy_factory = Policy)
      @policy_factory = policy_factory
    end

    # TODO: Introduce premium validations and employers!
    def validate(request, listener)
      failed = false
      eg_id = request[:enrollment_group_id]
      hios_id = request[:hios_id]
      plan_year = request[:plan_year]
      broker_npn = request[:broker_npn]
      enrollees = request[:enrollees]
      existing_policy = @policy_factory.find_for_group_and_hios(eg_id, hios_id)
      if !existing_policy.blank?
        listener.policy_already_exists({
          :enrollment_group_id => eg_id,
          :hios_id => hios_id
        })
        fail = true
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
        policy.enrollees.each do |en|
          if !en.valid?
            listener.invalid_enrollee(en.errors.to_hash)
          end
        end
        fail = true
      end
      if enrollees.blank?
        listener.no_enrollees
        fail = true
      end
      !fail
    end

    # TODO: Cancel the policies we should be cancelling
    def commit(request, listener)
      hios_id = request[:hios_id]
      plan_year = request[:plan_year]
      broker_npn = request[:broker_npn]

      plan = Plan.find_by_hios_id_and_year(hios_id, plan_year)
      broker = nil
      if !broker_npn.blank?
        broker = Broker.find_by_npn(broker_npn)
      end

      policy = @policy_factory.create!(request.merge({
        :plan => plan,
        :carrier => plan.carrier,
        :broker => broker
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
