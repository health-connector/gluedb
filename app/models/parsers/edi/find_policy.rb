module Parsers
  module Edi
    class FindPolicy
      def initialize(listener)
        @listener = listener
      end

      def by_subkeys(subkeys)
        policy = Policy.find_for_group_and_hios(subkeys[:eg_id], subkeys[:hios_plan_id])

        if(policy)
          @listener.policy_found(policy)
          policy
        else
          @listener.policy_not_found(subkeys)
          nil
        end
      end
    end
  end
end
