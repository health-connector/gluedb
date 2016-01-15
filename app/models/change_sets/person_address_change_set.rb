module ChangeSets
  class PersonAddressChangeSet
    attr_reader :address_kind

    include ::ChangeSets::SimpleMaintenanceTransmitter

    def initialize(addy_kind)
      @address_kind = addy_kind
    end

    def perform_update(person, person_update, policies_to_notify)
      new_address = person_update.addresses.detect { |au| au.address_type == address_kind }
      update_result = false
      if new_address.nil?
        person.remove_address_of(address_kind)
        update_result = person.save
      else
        person.set_address(Address.new(new_address.to_hash))
        update_result = person.save
      end
      return false unless update_result
      notify_policies("change", edi_change_reason, person_update.hbx_member_id, policies_to_notify)
      true
    end

    def edi_change_reason
      (address_kind == "home") ? "change_of_location" : "personnel_data"
    end
  end
end
