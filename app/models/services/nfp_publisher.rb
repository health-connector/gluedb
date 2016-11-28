module Services
  class NfpPublisher
    attr_reader :submitted_by
     
    def initialize(submitter = "trey.evans@dc.gov")
      @submitted_by = submitter
    end

    def publish(is_maintenance, file_name, data)
      return if Rails.env.test?
      tag = "hbx.payment_processor_updates"
      conn = AmqpConnectionProvider.start_connection
      ch = conn.create_channel
      ch.confirm_select
      x = ch.default_exchange

      x.publish(
        data,
        {
          :routing_key => tag,
          :headers => {
            :file_name => file_name,
            :submitted_by => submitted_by
          }
        }
      )
      ch.wait_for_confirms
      conn.close
    end

  end
end
