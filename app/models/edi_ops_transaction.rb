class EdiOpsTransaction
  include Mongoid::Document
  include Mongoid::Timestamps
  include AASM

  extend Mongorder

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

  before_save :set_state

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

    event :reopen do
      transitions from: [:open, :resolved, :assigned], to: :open
    end
  end

  def set_state
    if self.assigned_to.present? && (self.open? || self.assigned?)
      self.reopen
      self.assign
    else
      self.reopen
    end

    if self.resolved_by.present?
      self.assigned_to = self.resolved_by unless self.assigned_to.present?
      self.reopen
      self.assign
      self.resolve
    elsif self.assigned_to.present?
      self.reopen
      self.assign
    else
      self.reopen
    end

  end

  def self.default_search_order
    []
  end

  def json_body(opts = {})
    json_obj = nil
    begin
      if (opts[:headers])
        json_obj = Oj.safe_load(headers)
      else
        json_obj = Oj.safe_load(payload)
      end
    rescue Oj::ParseError
    end
    begin
      JSON.pretty_generate(json_obj)
    rescue JSON::GeneratorError
      payload
    end
  end

  def self.search_hash(s_rex)
    search_rex = Regexp.compile(Regexp.escape(s_rex), true)
    {
      "$or" => ([
        {"enrollment_group_uri" => search_rex},
        {"aasm_state" => search_rex},
        {"assigned_to" => search_rex}
      ])
    }
  end
end
