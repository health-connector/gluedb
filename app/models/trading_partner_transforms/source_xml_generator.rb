module TradingPartnerTransforms
  # Renders the enrollment event CV ("source xml") for a policy.
  # Extracted from the migrations:transform_xmls rake task (GenerateTransforms)
  # so it can run per-policy without ENV vars or app-root file writes.
  class SourceXmlGenerator

    def initialize(policy, reason_code)
      @policy = policy
      @reason_code = reason_code
    end

    def event_type
      "urn:openhbx:terms:v1:enrollment##{@reason_code}"
    end

    def file_name
      "#{@policy.eg_id}_#{@reason_code}.xml"
    end

    def generate
      affected_members = @policy.enrollees.map do |en|
        BusinessProcesses::AffectedMember.new({:policy => @policy, :member_id => en.m_id})
      end
      ApplicationController.new.render_to_string(
        :layout => "enrollment_event",
        :partial => "enrollment_events/enrollment_event",
        :format => :xml,
        :locals => {
          :affected_members => affected_members,
          :policy => @policy,
          :enrollees => @policy.enrollees,
          :event_type => event_type,
          :transaction_id => transaction_id
        }
      )
    end

    def transaction_id
      @transaction_id ||= TransactionIdGenerator.generate_bgn02_compatible_transaction_id
    end
  end
end
