class VocabularyRequest
  attr_accessor :submitted_by
  attr_accessor :enrollment_group_list

  ALLOWED_ATTRIBUTES = [:enrollment_group_list, :submitted_by]

  include ActiveModel::Validations
  include ActiveModel::Conversion
  include ActiveModel::Naming

  validates_presence_of :submitted_by
  validates_presence_of :enrollment_group_list

  def initialize(options={})
    options.each_pair do |k,v|
      if ALLOWED_ATTRIBUTES.include?(k.to_sym)
        self.send("#{k}=", v)
      end
    end
  end

  def save
    return(false) unless self.valid?
    submit_request(self.submitted_by, self.enrollment_group_list)
  end

  def submit_request(email, data)
    return if Rails.env.test?
    conn = AmqpConnectionProvider.start_connection
    ch = conn.create_channel
    x = ch.default_exchange
    x.publish(
      data,
      :routing_key => "hbx.vocabulary_request_batch",
      :headers => {
        :submitted_by => email
      }
    )
    conn.close
  end

  def persisted?
    false
  end
end
