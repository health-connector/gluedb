class ProcessAudits
  def self.execute(active_start, active_end, term_start, term_end, other_params, out_directory)
    active_audits = Policy.find_active_and_unterminated_in_range(active_start, active_end, other_params).no_timeout
    term_audits = Policy.find_terminated_in_range(term_start, term_end, other_params).no_timeout

    audit_ids = []
    member_ids = []

    active_audits.each do |aud|
      audit_ids << aud.id
      aud.enrollees.each do |en|
        member_ids << en.m_id
      end
    end

    term_audits.each do |aud|
      audit_ids << aud.id
      aud.enrollees.each do |en|
        member_ids << en.m_id
      end
    end

    audit_ids.uniq!
    member_ids.uniq!

    audits = Policy.where("id" => {"$in" => audit_ids}).no_timeout
    m_cache = Caches::MemberCache.new(member_ids)
    Caches::MongoidCache.with_cache_for(Carrier, Plan, Employer) do

      audits.each do |term|
        # TODO: Exclude all policies where the subscriber has a 
        #       authority_member_id, but the policy has a different member id
        subscriber_id = term.subscriber.m_id
        subscriber_member = m_cache.lookup(subscriber_id)
        auth_subscriber_id = subscriber_member.person.authority_member_id

        if !auth_subscriber_id.blank?
          if subscriber_id != auth_subscriber_id
            next
          end
        end

        enrollee_list = term.enrollees.reject { |en| en.canceled? }
        enrollee_list = enrollee_list.reject do |en|
          !en.coverage_end.blank? && (en.coverage_end < term_start) 
        end
        all_ids = enrollee_list.map(&:m_id) | [subscriber_id]
        out_f = File.open(File.join(out_directory, "#{term._id}_audit.xml"), 'w')
        ser = CanonicalVocabulary::MaintenanceSerializer.new(
          term,
          "audit",
          "notification_only",
          all_ids,
          all_ids,
          { :term_boundry => active_end,
            :member_repo => m_cache }
        )
        out_f.write(ser.serialize)
        out_f.close
      end
    end
  end
end
