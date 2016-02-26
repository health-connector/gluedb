require 'active_support/core_ext/object/blank'

class PolicyLoopValidator
  def validate(policy_loop, listener)
    carrier_policy_id = policy_loop.id
    if policy_loop.action != :stop
      if(carrier_policy_id.blank?)
        listener.missing_carrier_policy_id
        false
      else
        listener.found_carrier_policy_id(carrier_policy_id)
        true
      end
    end
  end
end
