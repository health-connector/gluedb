module Parsers
  module Edi
    class PersonLoopValidator
      def validate(person_loop, listener, policy)
        valid = true
        carrier_member_id = person_loop.carrier_member_id
        if policy
          enrollee = policy.enrollee_for_member_id(person_loop.member_id)
          if enrollee.blank?
            listener.no_such_member(person_loop.member_id)
            valid = false
          end
        end
        policy_loop = person_loop.policy_loops.first
        if policy_loop
          is_stop = policy_loop.action == :stop
          if !is_stop
            if(carrier_member_id.blank?)
              listener.missing_carrier_member_id(person_loop)
              valid = false
            else
              listener.found_carrier_member_id(carrier_member_id)
            end
          end
          if policy
            if is_stop
               enrollee = policy.enrollee_for_member_id(person_loop.member_id)
               coverage_end_date = Date.strptime(policy_loop.coverage_end,"%Y%m%d") rescue nil
               if enrollee
                 if (enrollee.coverage_start > coverage_end_date)
                   listener.coverage_end_before_coverage_start(
                     :coverage_end => policy_loop.coverage_end,
                     :coverage_start => enrollee.coverage_start.strftime("%Y%m%d"),
                     :member_id => person_loop.member_id
                   )
                   valid = false
                 end
               end
            end
          end
        end
        return false unless valid
        if policy
          is_stop = policy_loop.action == :stop
          if !policy.is_shop?
            enrollee = policy.enrollee_for_member_id(person_loop.member_id)
            if (enrollee.coverage_start < Date.new(2015, 1, 1)) && is_stop
              listener.term_or_cancel_for_2014_individual(:member_id => person_loop.member_id, :date => policy_loop.coverage_end)
              valid = false
            end
          end
          if !is_stop
            enrollee = policy.enrollee_for_member_id(person_loop.member_id)
            if enrollee.coverage_start.present?
              effectuation_coverage_start = policy_loop.coverage_start
              policy_coverage_start = enrollee.coverage_start.strftime("%Y%m%d")
              if effectuation_coverage_start != policy_coverage_start
                listener.effectuation_date_mismatch(:policy => policy_coverage_start, :effectuation => effectuation_coverage_start, :member_id => person_loop.member_id)
                valid = false
              end
            end
          end
        end
        valid
      end
    end
  end
end
