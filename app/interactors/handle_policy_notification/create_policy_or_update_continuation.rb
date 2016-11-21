module HandlePolicyNotification
  # Create or update the 'main' policy in glue to bring the data
  # into line with the changes we are about to transmit.
  class CreatePolicyOrUpdateContinuation
    include Interactor

    # Context requires:
    # - primary_policy_action (a HandlePolicyNotification::PolicyAction)
    def call
    # Don't build me for now
=begin
      primary_action = context.primary_policy_action
      member_details = primary_action.member_detail_collection
      raise member_details.inspect
      enrollees = member_details.map do |md|
        Enrollee.new(md.enrollee_attributes)
      end
      Policy.create!(primary_action.new_policy_attributes.merge({
        :enrollees => enrollees
      }))
=end
    end
  end
end
