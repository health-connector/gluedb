module ChangeSets
  module SimpleMaintenanceTransmitter
    def notify_policies(op, reason, member_id, policies_to_notify)
      policies_to_notify.each do |pol|
        serializer = ::CanonicalVocabulary::MaintenanceSerializer.new(
          pol, op, reason, [member_id], pol.active_member_ids
        )
        cv = serializer.serialize
        pubber = ::Services::CvPublisher.new
        pubber.publish(true, "#{pol.eg_id}.xml", cv)
      end
    end
  end
end
