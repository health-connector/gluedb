module HandlePolicyNotification
  # Create or update the 'main' policy in glue to bring the data
  # into line with the changes we are about to transmit.
  class CreatePolicyOrUpdateContinuation
    include Interactor

    # Context requires:
    # - primary_policy_action (a HandlePolicyNotification::PolicyAction)
    def call
      primary_action = context.primary_policy_action
      member_details = primary_action.member_detail_collection
      enrollees = member_details.map do |md|
        Enrollee.new(md.enrollee_attributes)
      end
      Policy.create!(primary_action.new_policy_attributes.merge({

      }))
    end
  end
end
