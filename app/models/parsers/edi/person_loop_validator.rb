module Parsers
  module Edi
    class PersonLoopValidator
      def validate(person_loop, listener, policy)
        carrier_member_id = person_loop.carrier_member_id
        if(carrier_member_id.blank?)
          listener.missing_carrier_member_id(person_loop)
          false
        else
          listener.found_carrier_member_id(carrier_member_id)
          true
        end
        if policy
           enrollee = policy.enrollee_for_member_id(person_loop.member_id)
           if enrollee.blank?
             listener.no_such_member(person_loop.member_id)
          end
        end
      end
  end
end
