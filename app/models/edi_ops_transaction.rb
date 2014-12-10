class EdiOpsTransaction
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM


  field :qualifying_reason_uri, type: String
  field :enrollment_group_uri, type: String
  field :submitted_timestamp, type: DateTime
  field :event_key, type: String
  field :event_name, type: String
  field :return_status, type: Integer
  field :headers, type: String
  field :payload, type: String

  field :assigned_to, type: String
  field :resolved_by, type: String

  field :aasm_state, type: String

  embeds_many :comments, cascade_callbacks: true
  accepts_nested_attributes_for :comments, reject_if: proc { |attribs| attribs['content'].blank? }, allow_destroy: true

  index({aasm_state:  1})

  aasm do
    state :open, initial: true
    state :assigned
    state :resolved

    event :assign do
      transitions from: :open, to: :assigned
    end

    event :resolve do
      transitions from: :assigned, to: :resolved
    end
  end
end
