class Email
  include Mongoid::Document

  include MergingModel

  TYPES = %W(home work)

  field :email_type, type: String
  field :email_address, type: String

  validates_presence_of  :email_address
  validates_presence_of  :email_type, message: "Choose a type"
  validates_inclusion_of :email_type, in: TYPES, message: "Invalid type"

  embedded_in :person, :inverse_of => :emails
  embedded_in :employer, :inverse_of => :emails
  embedded_in :broker, :inverse_of => :emails

  def match(another_email)
    return false if another_email.nil?
    attrs_to_match = [:email_type, :email_address]
    attrs_to_match.all? { |attr| attribute_matches?(attr, another_email) }
  end

  def attribute_matches?(attribute, other)
    return(true) if (self[attribute].blank? && other[attribute].blank?)
    self[attribute] == other[attribute]
  end

  def merge_update(m_email)
    merge_with_overwrite(
      m_email,
      :email_address
    )
  end

  def self.make(data)
    email = Email.new
    email.email_type = data[:email_type]
    email.email_address = data[:email_address]
    email
  end
end
