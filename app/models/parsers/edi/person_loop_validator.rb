module Parsers
  module Edi
    class PersonLoopValidator
      def validate(person_loop, listener, policy)
        valid = true
        carrier_member_id = person_loop.carrier_member_id
        if(carrier_member_id.blank?)
          listener.missing_carrier_member_id(person_loop)
          valid = false
        else
          listener.found_carrier_member_id(carrier_member_id)
        end
        if policy
          enrollee = policy.enrollee_for_member_id(person_loop.member_id)
          if enrollee.blank?
            listener.no_such_member(person_loop.member_id)
            valid = false
          end
        end
        valid
      end
    end
  end
end
