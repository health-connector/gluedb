module ChangeSets
  class PersonSsnChangeSet
    def perform_update(member, person_resource, policies_to_notify)
      old_values_hash = old_name_values(person_resource.hbx_member_id, member, person_resource)
      update_value = member.update_attributes(name_update_hash(person_resource))
      return false unless update_value
      policies_to_notify.each do |pol|
        serializer = ::CanonicalVocabulary::IdInfoSerializer.new(
          pol, "change", "change_in_identifying_data_elements", [person_resource.hbx_member_id], pol.active_member_ids, old_values_hash
        )
        cv = serializer.serialize
        pubber = ::Services::CvPublisher.new
        pubber.publish(true, "#{pol.eg_id}.xml", cv)
      end
      true
    end

    def name_update_hash(person_resource)
      name_hash = {}
      name_hash["ssn"] = person_resource.ssn.blank? ? nil : person_resource.ssn
      name_hash
    end

    def old_name_values(member_id, member, person_resource)
      [{
        "member_id" => member_id,
        "ssn" => member.ssn
      }]
    end
  end
end
