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
    index({received_at: -1, batch_id: -1, batch_index: -1, "headers.return_status" => 1}, {name: "default_order_index"})
    # Performance indexes for enrollment action batch processing and error tracking
    index({hbx_enrollment_id: 1})
    index({aasm_state: 1, received_at: -1})
    index({"headers.return_status" => 1, received_at: -1})
    index({batch_id: 1, aasm_state: 1})

    scope :default_order, ->{ where({"headers.return_status" => {"$ne" => "200"}}).desc(:received_at, :batch_id, :batch_index)  }

    aasm do
      state :new, initial: true
      state :resolved
      state :in_progress
    end
  end
end
