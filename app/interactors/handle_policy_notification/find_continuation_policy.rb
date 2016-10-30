module HandlePolicyNotification
 
  # It is possible that we have a policy which needs to be transmitted to
  # the EDI systems using a different enrollment group ID.
  # For example:
  # - we are given a dependent add
  # - we actually need to treat the enrollment that came over as a continuation
  #   of the previous policy, even though we now have a new enrollment group ID
  # - transmissions to EDI for the enrollment in question need to go out to
  #   other systems with the enrollment group id of this existing policy,
  #   NOT with the new enrollment group ID
  # - Updates should be performed on this existing policy, a new policy should
  #   not be created
  class FindContinuationPolicy
    include Interactor

    # Context requires:
    # - policy_details
    # - member_detail_collection (array of HandlePolicyNotification::MemberDetails)
    # Context outputs:
    # - continuation_policy (either a Policy or nil)
    def call
    end
  end
end
