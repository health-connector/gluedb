module ChangeSets
  class MemberRelationshipChangeSet
    attr_writer :applicable_policies

    include ::ChangeSets::SimpleMaintenanceTransmitter

    def applicable?(member, resource, now_or_future_active_policies)
      return false if member.blank?
      return false if resource.relationships.empty?
      # Put a check here to see if there even ARE relationship entries on the
      # resource
      !select_applicable_policies(member, resource, now_or_future_active_policies).empty?
    end

    def perform_update(member, resource, now_or_future_active_policies)
      policies_to_transmit = select_applicable_policies(member, resource, now_or_future_active_policies)
      relationship_mapping = member_relationship_mapping(member, resource)

      policies_to_transmit.each do |pol|
        member_ids_to_search = pol.active_member_ids
        updated_member_id = nil
        pol.enrollees.each do |en|
          if !en.subscriber?
            if member_ids_to_search.include?(en.m_id)
              if relationship_mapping.has_key?(en.m_id)
                if relationship_mapping[en.m_id] != en.rel_code
                  en.update_attributes!({:rel_code => relationship_mapping[en.m_id]})
                  notify_policies("change", "personnel_data", en.m_id, [pol], "urn:openhbx:terms:v1:enrollment#change_relationship")
                end
              end
            end
          end
        end
      end
      true
    end

    def member_relationship_mapping(member, resource)
      relationship_mapping = {}
      resource.relationships.each do |rel|
        if (member.hbx_member_id == rel.object_individual_member_id)
          relationship_mapping[rel.subject_individual_member_id] = rel.glue_relationship
        end
      end
      relationship_mapping
    end

    # Find applicable policies to be updated due to relationship change. Only supports IVL market
    # Return array of applicable policies. Return empty array if no relationship changed.
    def select_applicable_policies(member, resource, policy_list)
      return @applicable_policies if @applicable_policies
      @applicable_policies = []
      relationship_mapping = member_relationship_mapping(member, resource)
      has_dependent_policies = policy_list.select do |pol|
        (pol.active_member_ids.count > 1) && (pol.subscriber.m_id == member.hbx_member_id) && (!pol.is_shop?)
      end
      return [] if has_dependent_policies.empty?
      has_dependent_policies.each do |pol|
        pol.enrollees.each do |en|
          unless en.subscriber?
            if relationship_mapping.has_key?(en.m_id)
               if (en.rel_code != relationship_mapping[en.m_id])
                 @applicable_policies << pol
                 break
               end
            end
          end
        end
      end
      @applicable_policies
    end #end select_applicable_policies


  end
end
