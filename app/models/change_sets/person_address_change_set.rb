module ChangeSets
  class PersonAddressChangeSet
    attr_reader :address_kind

    def initialize(addy_kind)
      @address_kind = addy_kind
    end

    def perform_update(person, person_update, policies_to_notify)
      new_address = person_update.addresses.detect { |au| au.address_type == address_kind }
      person.set_address(Address.new(new_address.to_hash))
      update_result = person.save
      return false unless update_result
      policies_to_notify.each do |pol|
        serializer = ::CanonicalVocabulary::MaintenanceSerializer.new(
          pol, "change", edi_change_reason, [person_update.hbx_member_id], pol.active_member_ids
        )
        cv = serializer.serialize
        pubber = ::Services::CvPublisher.new
        pubber.publish(true, "#{pol.eg_id}.xml", cv)
      end
      true
    end

    def edi_change_reason
      (address_kind == "home") ? "change_of_location" : "personnel_data"
    end
  end
end
