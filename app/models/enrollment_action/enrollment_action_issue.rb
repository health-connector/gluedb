module EnrollmentAction
  class EnrollmentActionIssue
    include Mongoid::Document
    include Mongoid::Timestamps
    include AASM

    field :error_message, type: String
    field :enrollment_action_uri, type: String
    field :hbx_enrollment_id, type: String
    field :received_at, type: Time
    field :hbx_enrollment_vocabulary, type: String
    field :headers, type: Hash
    field :aasm_state, type: String

    aasm do
      state :new, initial: true
      state :resolved
      state :in_progress
    end
  end
end
