module ChangeSets
  class PersonDobChangeSet
    include Handlers::EnrollmentEventXmlHelper

    @@logger = Logger.new("#{Rails.root}/log/person_dob_change_set.log")
    def perform_update(member, person_resource, policies_to_notify, transmit = true)
      @@logger.info("Starting perform_update")
      old_values_hash = old_dob_values(person_resource.hbx_member_id, member, person_resource)
      update_value = member.update_attributes(dob_update_hash(person_resource))
      return false unless update_value

      update_enrollments_for(policies_to_notify)

      policies_to_notify.each do |pol|
        af = ::BusinessProcesses::AffectedMember.new({
          :policy => pol
        }.merge(old_values_hash.first))
        ict = IdentityChangeTransmitter.new(af, pol, "urn:openhbx:terms:v1:enrollment#change_member_name_or_demographic")
        ict.publish
        if pol.is_shop?
          serializer = ::CanonicalVocabulary::IdInfoSerializer.new(
            pol, "change", "change_in_identifying_data_elements", [person_resource.hbx_member_id], pol.active_member_ids, old_values_hash
          )
          cv = serializer.serialize
          pubber = ::Services::NfpPublisher.new
          pubber.publish(true, "#{pol.eg_id}.xml", cv)
        end
      end
      @@logger.info("Ending perform_update")
      true
    end

    def update_enrollments_for(policies_to_notify)
      @@logger.info("Starting update_enrollments_for")
      amqp = Amqp::Requestor.default

      policies_to_notify.each do |policy|
        enrollments = policy.hbx_enrollment_ids.map do |id|
          get_enrollment(id, amqp)
        end.compact.sort_by do |enrollment|
          enrollment.header.submitted_timestamp
        end

        latest_enrollment = enrollments.last
        next if latest_enrollment.blank?

        policy_node = extract_policy(latest_enrollment)

        policy.enrollees.each do |enrollee|
          policy_node_enrollee = policy_node.enrollees.find { |enrollee_node| enrollee_node.member.id == enrollee.m_id }
          if policy_node_enrollee
            enrollee.update_attributes!({pre_amt: BigDecimal(policy_node_enrollee.benefit.premium_amount || 0.00)})
          end
        end

        policy.tot_res_amt = policy_node.policy_enrollment.total_responsible_amount
        policy.pre_amt_tot = policy_node.policy_enrollment.premium_total_amount

        if policy_node.policy_enrollment.shop_market
          policy.tot_emp_res_amt = Maybe.new(policy_node).policy_enrollment.shop_market.total_employer_responsible_amount.strip.value || 0.00
        else
          policy.applied_aptc = Maybe.new(policy_node).policy_enrollment.individual_market.applied_aptc_amount.strip.value || 0.00
        end

        policy.save!
      end
      @@logger.info("Ending update_enrollments_for")
    end

    def get_enrollment(id, amqp, retry_count=0)
      @@logger.info("Starting get_enrollments")
      return nil if retry_count > 2
      rcode, payload = RemoteResources::EnrollmentEventResource.retrieve(amqp, id.to_s)
      @@logger.info("Ending get_enrollments")
      case rcode
      when '200'
        enrollment_event_cv_for payload.body
      when '503'
        get_enrollment(id, amqp, retry_count + 1)
      else
        nil
      end
    end

    def dob_update_hash(person_resource)
      dob_hash = {}
      dob_hash["dob"] = person_resource.dob.blank? ? nil : person_resource.dob
      dob_hash
    end

    def old_dob_values(member_id, member, person_resource)
      [{
        "member_id" => member_id,
        "dob" => member.dob
      }]
    end
  end
end
