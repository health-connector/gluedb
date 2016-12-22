module Handlers
  class TransmitNfpXmlHandler < Base
    def call(context)
      if context.terminations.any?
        context.terminations.each do |term|
          if term.policy.is_shop? && term.transmit?
            serializer = ::CanonicalVocabulary::MaintenanceSerializer.new(
              term.policy, "terminate", "termination_of_benefits", term.affected_member_ids, term.member_ids
            )
            cv = serializer.serialize
            pubber = ::Services::NfpPublisher.new
            pubber.publish(true, "#{term.policy.eg_id}.xml", cv)
          end
        end
      end
      if context.cancellations.any?
        context.cancellations.each do |term|
          if term.policy.is_shop? && term.transmit?
            serializer = ::CanonicalVocabulary::MaintenanceSerializer.new(
              term.policy, "cancel", "termination_of_benefits", term.affected_member_ids, term.member_ids
            )
            cv = serializer.serialize
            pubber = ::Services::NfpPublisher.new
            pubber.publish(true, "#{term.policy.eg_id}.xml", cv)
          end
        end
      end
      @app.call(context)
    end
  end
end
