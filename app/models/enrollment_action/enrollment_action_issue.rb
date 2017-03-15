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
    field :batch_id, type: String, default: ->{ SecureRandom.uuid }
    field :batch_index, type: String, default: 0

    index({received_at: 1, batch_id: 1, batch_index: 1, error_message: 1, "headers.return_status" => 1})

    scope :default_order, ->{ where({"headers.return_status" => {"$ne" => "200"}}).desc(:received_at, :batch_id, :batch_index)  }

    aasm do
      state :new, initial: true
      state :resolved
      state :in_progress
    end
  end
end
