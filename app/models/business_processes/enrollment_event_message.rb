module BusinessProcesses
  class EnrollmentEventMessage
    attr_accessor :event_xml
    attr_accessor :message_tag
    attr_accessor :amqp_response_channel

    include Handlers::EnrollmentEventXmlHelper

    def hash
      [subscriber_id, coverage_type, employer_fein, plan_active_year].hash
    end

    def enrollment_event_xml
      @enrollment_event_xml ||= enrollment_event_cv_for(event_xml)
    end

    def policy_cv
      @policy_cv ||= extract_policy(enrollment_event_xml)
    end

    def hbx_enrollment_id
      @hbx_enrollment_id ||= Maybe.new(policy_cv).id.value
    end

    def subscriber
      @subscriber ||= extract_subscriber(policy_cv)
    end

    def subscriber_id
      @subscriber_id ||= extract_member_id(subscriber)
    end

    def active_year
      @active_year ||= extract_active_year(policy_cv)
    end

    def employer_fein
      @employer_fein ||= begin
                           if determine_market(enrollment_event_xml) == "individual"
                             nil
                           else
                             Maybe.new(policy_cv).policy.policy_enrollment.shop_market.employer_link.id.strip.split("#").last.value
                           end
                         end
    end

    def coverage_type
      @coverage_type ||= Maybe.new(policy_cv).policy_enrollment.plan.is_dental_only.value
    end

    private

    def initialize_clone(other)
      @event_xml = other.event_xml.clone
      @message_tag = other.message_tag.clone
      @amqp_response_channel = other.amqp_response_channel
    end
  end
end
