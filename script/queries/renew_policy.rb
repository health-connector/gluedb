require File.join(Rails.root, "script/queries/policy_id_generator")

pols = Policy.where(:eg_id => "844021134486667264")
# raise pols.first.subscriber.full_name

polgen = PolicyIdGenerator.new(1)
pc = Premiums::PolicyCalculator.new

pols.each do |pol|
  sub_person = pol.subscriber.person
  if pol.subscriber.coverage_end.blank?
    if !pol.subscriber.coverage_start.blank?
      if (!sub_person.authority_member.blank?)
        if (sub_person.authority_member.hbx_member_id == pol.subscriber.m_id)
          begin
            r_pol = pol.clone_for_renewal(Date.new(2015,2,1))
            r_pol.applied_aptc = pol.applied_aptc
            pc.apply_calculations(r_pol)
            p_id = polgen.get_id
            out_file = File.open("renewals/#{p_id}.xml", 'w')
            member_ids = r_pol.enrollees.map(&:m_id)
            r_pol.eg_id = p_id.to_s
            ms = CanonicalVocabulary::MaintenanceSerializer.new(r_pol,"change", "renewal", member_ids, member_ids)
            out_file.print(ms.serialize)
            out_file.close
          rescue => e
            puts e.inspect
            puts e.backtrace.inspect
            raise([sub_person.id, pol.id].inspect)
          end
        end
      end
    end
  end
end
