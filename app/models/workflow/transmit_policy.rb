module Workflow
  module TransmitPolicy
    def serialize(pol, operation, reason)
      member_ids = pol.enrollees.map(&:m_id)
      serializer = CanonicalVocabulary::MaintenanceSerializer.new(
        pol,
        operation,
        reason,
        member_ids,
        member_ids
      )
      serializer.serialize
    end

    def with_channel
      session = AmqpConnectionProvider.start_connection
      chan = session.create_channel
      chan.prefetch(1)
      yield chan
      session.close
    end
  end
end
