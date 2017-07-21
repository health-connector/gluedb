require 'set'

module EmployerEvents
  class EnrollmentEventTrigger
    attr_reader :initial_employer_ids, :renewal_employer_ids

    def initialize
      @initial_employer_ids = Set.new
      @renewal_employer_ids = Set.new
    end

    def add(enrollment_event)
      if enrollment_event.event_name == ::EmployerEvents::EventNames::FIRST_TIME_EMPLOYER_EVENT_NAME
        @initial_employer_ids.add(enrollment_event.employer_id)
      elsif enrollment_event.event_name == ::EmployerEvents::EventNames::RENEWAL_SUCCESSFUL_EVENT
        @renewal_employer_ids.add(enrollment_event.employer_id)
      elsif enrollment_event.event_name == ::EmployerEvents::EventNames::RENEWAL_CARRIER_CHANGE_EVENT
        @renewal_employer_ids.add(enrollment_event.employer_id)
      end
      self
    end

    def publish(connection)
      @initial_employer_ids.each do |ieid|
        employer = Employer.by_hbx_id(ieid).first
        if employer
          publish_employer(connection, employer, "binder_enrollments_transmission_authorized")
        end
      end
      @renewal_employer_ids.each do |reid|
        employer = Employer.by_hbx_id(reid).first
        if employer
          publish_employer(connection, employer, "renewal_transmission_authorized")
        end
      end
    end

    protected

    def publish_employer(connection, employer, event_name)
      last_plan_year = employer.plan_years.sort_by(&:start_date).last
      if last_plan_year
        effective_on = last_plan_year.start_date
        effective_on_date = effective_on.strftime("%Y-%m-%d")
        ec = ExchangeInformation
        Amqp::ConfirmedPublisher.with_confirmed_channel(connection) do |chan|
          ex = chan.fanout(ec.event_publish_exchange, {:durable => true})
          ex.publish(
            "",
            {
              routing_key: "info.events.employer.#{event_name}",
              headers: {
                "fein" => employer.fein,
                "effective_on" => effective_on_date
              }
            }
          )
        end
      end
    end
  end
end
