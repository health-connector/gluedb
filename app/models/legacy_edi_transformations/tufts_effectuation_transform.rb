module LegacyEdiTransformations
  class TuftsEffectuationTransform

    def apply(csv_row)
      wpu = csv_row["WIREPAYLOADUNPACKED"]
      new_row = csv_row.dup
      json_structure = JSON.parse(wpu)
      transform_gs(json_structure)
      process_834_loops(json_structure)
      new_row["WIREPAYLOADUNPACKED"] = JSON.dump(json_structure)
      new_row
    end

    protected

    def transform_gs(json_structure)
      gs_seg = json_structure["GS"]
      return nil if gs_seg.blank?
      return nil if gs_seg[2].blank?
      json_structure["GS"][2] = "SHP"
    end

    def process_834_loops(json_structure)
      return nil if json_structure["L834s"].blank?
      new_834_structures = json_structure["L834s"].flat_map do |l834|
        span_834(l834)
      end
      new_834_structures.each_with_index do |sub_and_l834, index|
        sub_info, l834 = sub_and_l834
        bump_sequences(l834, index)
        add_policy_info(sub_info, l834)
      end
      json_structure["L834s"] = new_834_structures.map(&:last)
    end

    def span_834(doc_834)
      sub_info = extract_subscribers(doc_834)
      all_people = doc_834["L2000s"]
      doc_834.delete("L2000s")
      l834s = Array.new
      sub_info.inject(all_people) do |rem_people, sub|
        choose_my_people(doc_834, sub, rem_people, l834s)
      end
      l834s
    end

    def extract_subscribers(l834)
      return [] if l834["L2000s"].blank?
      l_2000s = l834["L2000s"]
      sub_l2000s = l_2000s.select do |l2000|
        subscriber_l2000?(l2000)
      end
      sub_info = sub_l2000s.map do |sl2000|
        extract_subscriber_matching_info(sl2000)
      end.compact
      sub_info
    end

    def subscriber_l2000?(l2000)
      return false if l2000["INS"].blank?
      return false if l2000["INS"][2].blank?
      "18" == l2000["INS"][2].strip
    end

    def extract_subscriber_matching_info(sub_l2000)
      sub_start_date = nil
      refs = sub_l2000["REFs"]
      return nil if refs.blank?
      car_assigned_pol_id_ref = refs.detect do |ref|
        ref[1] == "23"
      end
      capi_str = car_assigned_pol_id_ref[2]
      return nil if capi_str.blank?
      capi_parts = capi_str.split(/\s+/)
      capi = capi_parts[0..-2].join(" ")
      sub_id_ref = refs.detect do |ref|
        ref[1] == "0F"
      end
      return nil if sub_id_ref.blank?
      sub_id = sub_id_ref[2]
      return nil if sub_id.blank?
      l2300s = sub_l2000["L2300s"]
      return nil if l2300s.blank?
      return nil if l2300s.first.blank?
      l2300_refs = l2300s.first["REFs"]
      return nil if l2300_refs.blank?
      hios_ref = l2300_refs.detect do |ref|
        ref[1] == "CE"
      end
      l2300_dtps = l2300s.first["DTPs"]
      if l2300_dtps.present?
        dtp_348 = l2300_dtps.detect do |dtp|
          dtp[1] == "348"
        end
        if dtp_348.present?
          sub_start_date = dtp_348[3]
        end
      end
      return nil if hios_ref.blank?
      hios_id = hios_ref[2]
      TuftsSubscriberInfo.new(sub_id,hios_id,capi, sub_start_date)
    end

    def choose_my_people(l834, sub_info, rem_people, the_834s)
      match, dont_match = rem_people.partition do |rp|
        person_matches?(sub_info, rp)
      end
      new_834 = l834.deep_dup
      new_834["ST"] = new_834["ST"].dup
      new_834["SE"] = new_834["SE"].dup
      new_834["BGN"] = new_834["BGN"].dup
      new_834["L2000s"] = match
      match.each do |m|
        move_supergroup_id(m)
      end
      the_834s << [sub_info, new_834]
      dont_match
    end

    def person_matches?(sub_info, remaining_person)
      refs = remaining_person["REFs"]
      return false if refs.blank?
      car_assigned_pol_id_ref = refs.detect do |ref|
        ref[1] == "23"
      end
      capi_str = car_assigned_pol_id_ref[2]
      return false if capi_str.blank?
      capi_parts = capi_str.split(/\s+/)
      capi = capi_parts[0..-2].join(" ")
      sub_id_ref = refs.detect do |ref|
        ref[1] == "0F"
      end
      return false if sub_id_ref.blank?
      sub_id = sub_id_ref[2]
      return false if sub_id.blank?
      l2300s = remaining_person["L2300s"]
      return false if l2300s.blank?
      l2300_refs = l2300s.first["REFs"]
      return false if l2300_refs.blank?
      hios_ref = l2300_refs.detect do |ref|
        ref[1] == "CE"
      end
      return false if hios_ref.blank?
      hios_id = hios_ref[2]
      (sub_info.subscriber_id == sub_id) &&
        (sub_info.hios_id == hios_id) &&
        (sub_info.carrier_assigned_policy_id == capi)
    end

    def bump_sequences(l834, index_number)
      index = index_number.to_s.rjust(5, "0")
      if l834["ST"].present?
        if l834["ST"][2].present?
          l834["ST"][2] = l834["ST"][2] + "_" + index.to_s
        end
      end
      if l834["SE"].present?
        if l834["SE"][2].present?
          l834["SE"][2] = l834["SE"][2] + "_" + index.to_s
        end
      end
      return nil if l834["BGN"].blank?
      return nil if l834["BGN"][2].blank?
      l834["BGN"][2] = l834["BGN"][2] + "_" + index.to_s
      advance_bgn_time(l834)
    end

    def advance_bgn_time(l834)
      the_date = l834["BGN"][3]
      the_time = l834["BGN"][4]
      return nil if l834["BGN"][4].length < 4
      year = the_date[0..3]
      month = the_date[4..5]
      day = the_date[6..7]
      hour = the_time[0..1]
      rest = the_time[2..-1]
      time = Time.mktime(
        year,
        month,
        day,
        hour,
        0,
        0
      )
      corrected_time = time + 4.hours
      l834["BGN"][3] = corrected_time.strftime("%Y%m%d")
      l834["BGN"][4] = corrected_time.strftime("%H") + rest
      l834["BGN"][5] = "UT"
    rescue Exception # rubocop:disable Lint/RescueException
      bgn = l834["BGN"]
      Rails.logger.error "[Tufts Effectuation Transform] Date Parsing Error: #{bgn.inspect}"
    end

    def move_supergroup_id(loop_2000)
      l_2300s = loop_2000["L2300s"]
      return nil if l_2300s.blank?
      l_2300s.each do |l2300|
        l2300_refs = l2300["REFs"]
        next if l2300_refs.blank?
        l2300_refs.each do |ref|
          if ref[1] == "1L"
            ref[1] = "PID"
          end
        end
      end
    end

    def add_policy_info(sub_info, l834)
      p_info = sub_info.locate_policy_information
      return nil if p_info.blank?
      pol_id, employer_name, employer_fein = p_info
      apply_policy_ids(l834, pol_id)
      apply_employer_information(l834, employer_name, employer_fein)
    end

    def apply_policy_ids(l834, pol_id)
      l2000s = l834["L2000s"]
      return nil if l2000s.blank?
      l2000s.each do |loop_2000|
        l_2300s = loop_2000["L2300s"]
        return nil if l_2300s.blank?
        l_2300s.each do |l2300|
          l2300_refs = l2300["REFs"]
          if l2300_refs.blank?
            l2300["REFs"] = [
              [
                -1,
                "1L",
                pol_id
              ]
            ]
          else
            l2300_refs << [
              -1,
              "1L",
              pol_id
            ]
          end
        end
      end
    end

    def apply_employer_information(l834, employer_name, employer_fein)
      return nil if employer_name.blank?
      return nil if employer_fein.blank?
      l1000a = l834["L1000A"]
      return nil if l1000a.blank?
      l1000a_update = l1000a.dup
      n1 = l1000a["N1"]
      return nil if n1.blank?
      new_n1 = [n1[0], "P5", employer_name, "FI", employer_fein]
      l1000a_update["N1"] = new_n1
      l834["L1000A"] = l1000a_update
    end
  end
end
