module ChangeSets
  module SimpleMaintenanceTransmitter
    def notify_policies(op, reason, member_id, policies_to_notify, new_reason)
      policies_to_notify.each do |pol|
        af = ::BusinessProcesses::AffectedMember.new({
          :policy => pol,
          :member_id => member_id
        })
        ict = IdentityChangeTransmitter.new(af, pol, new_reason)
        ict.publish
        if pol.is_shop?
          serializer = ::CanonicalVocabulary::MaintenanceSerializer.new(
            pol, op, reason, [member_id], pol.active_member_ids
          )
          cv = serializer.serialize
          pubber = ::Services::NfpPublisher.new
          pubber.publish(true, "#{pol.eg_id}.xml", cv)
        end
      end
    end
  end
end
