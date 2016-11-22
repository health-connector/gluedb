module BusinessProcesses
  class EnrollmentEventMessage
    attr_accessor :event_xml
    attr_accessor :message_tag

    private

    def initialize_clone(other)
      @event_xml = other.event_xml.clone
      @message_tag = other.message_tag.clone
    end
  end
end
