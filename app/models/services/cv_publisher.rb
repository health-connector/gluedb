module Services
  class CvPublisher
    attr_reader :submitted_by
     
    def initialize(submitter)
      @submitted_by = submitter
    end

    def publish(is_maintenance, file_name, data)
      return if Rails.env.test?
      tag = is_maintenance ? "hbx.maintenance_messages" : "hbx.enrollment_messages"
      conn = AmqpConnectionProvider.start_connection
      ch = conn.create_channel
      x = ch.default_exchange

      x.publish(
        data,
        :routing_key => "hbx.vocab_validator",
        :reply_to => tag,
        :headers => {
          :file_name => name,
          :submitted_by => submitted_by
        }
      )
      conn.close
    end

  end
end
