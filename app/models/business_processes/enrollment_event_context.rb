module BusinessProcesses
  class EnrollmentEventContext
    attr_accessor :raw_event_xml
    attr_accessor :enrollment_event_errors
    attr_accessor :business_process_history
    attr_accessor :amqp_connection
    attr_accessor :event_list
    attr_accessor :errors

    def initialize
      @errors = ::BusinessProcesses::EnrollmentEventErrors.new
    end

    private

    def initialize_clone(other)
      @errors = other.errors.clone
      if other.business_process_history.present?
        @business_process_history = other.business_process_history.clone
      end
      if other.amqp_connection.present?
        @amqp_connection = other.amqp_connection
      end
      if other.raw_event_xml.present?
        @raw_event_xml = other.raw_event_xml.clone
      end
    end
  end
end
