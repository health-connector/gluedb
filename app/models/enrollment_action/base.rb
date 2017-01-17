module EnrollmentAction
  class Base
    attr_reader :action
    attr_reader :termination

    def initialize(term, init)
      @termination = term
      @action = init
    end

    def update_business_process_history(entry)
      if @termination
        @termination.update_business_process_history(entry)
      end
      if @action
        @action.update_business_process_history(entry)
      end
    end

    def self.select_action_for(chunk)
      selected_action = [
        ::EnrollmentAction::PassiveRenewal,
        ::EnrollmentAction::ActiveRenewal,
        ::EnrollmentAction::CarrierSwitch,
        ::EnrollmentAction::CarrierSwitchRenewal,
        ::EnrollmentAction::DependentAdd,
        ::EnrollmentAction::DependentDrop,
        ::EnrollmentAction::InitialEnrollment,
        ::EnrollmentAction::PlanChange,
        ::EnrollmentAction::PlanChangeDependentAdd,
        ::EnrollmentAction::PlanChangeDependentDrop,
        ::EnrollmentAction::RenewalDependentAdd,
        ::EnrollmentAction::RenewalDependentDrop,
        ::EnrollmentAction::Termination
      ].detect { |kls| kls.qualifies?(chunk) }
      
      if selected_action
        selected_action.construct(chunk)
      else
        puts "====== NO EVENT FOUND ====="
        puts "Chunk length: #{chunk.length}"
        chunk.each do |c|
          puts c.hbx_enrollment_id
          puts c.event_xml
        end
        raise "NO MATCH EVENT FOUND"
      end
    end

    def self.construct(chunk)
      term = chunk.detect { |c| c.is_termination? }
      action = chunk.detect { |c| !c.is_termination? }
      self.new(term, action)
    end

    # When implemented in a subclass, return true on successful persistance of
    # the action - otherwise return false.
    def persist
      raise NotImplementedError, "subclass responsibility"
    end

    # Performing publishing.  On failure, use the enrollment event
    # notifications to log the errors.
    def publish
      raise NotImplementedError, "subclass responsibility"
    end

    def drop_not_yet_implemented!
      if @termination
        @termination.drop_not_yet_implemented!(self.class.name.to_s)
      end
      if @action
        @action.drop_not_yet_implemented!(self.class.name.to_s)
      end
    end
  end
end
