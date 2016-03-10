module CanonicalVocabulary
  class IdInfoSerializer 

    CV_XMLNS = {
      "xmlns:pln" => "http://dchealthlink.com/vocabularies/1/plan",
      "xmlns:ins" => "http://dchealthlink.com/vocabularies/1/insured",
      "xmlns:car" => "http://dchealthlink.com/vocabularies/1/carrier",
      "xmlns:con" => "http://dchealthlink.com/vocabularies/1/contact",
      "xmlns:bt" => "http://dchealthlink.com/vocabularies/1/base_types",
      "xmlns:emp" => "http://dchealthlink.com/vocabularies/1/employer",
      "xmlns:proc" => "http://dchealthlink.com/vocabularies/1/process",
      "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
      "xsi:schemaLocation" =>"http://dchealthlink.com/vocabularies/1/process process.xsd      http://dchealthlink.com/vocabularies/1/insured insured.xsd      http://dchealthlink.com/vocabularies/1/plan plan.xsd      http://dchealthlink.com/vocabularies/1/employer employer.xsd     http://dchealthlink.com/vocabularies/1/carrier carrier.xsd     http://dchealthlink.com/vocabularies/1/contact contacts.xsd     http://dchealthlink.com/vocabularies/1/base_types.xsd base_types.xsd"
    }

    def initialize(policy, op, reas, m_ids, include_m_ids, old_id_data, opts={})
      @options = opts
      @operation = op
      @policy = policy
      @reason = reas
      @member_ids = m_ids
      @included_members_ids = include_m_ids
      @old_id_data = old_id_data
    end

    def serialize
      en_ser = CanonicalVocabulary::EnrollmentSerializer.new(@policy, @included_members_ids, @options)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml['proc'].Operation(CV_XMLNS) do |xml|
          xml['proc'].operation do |xml|
            xml['proc'].type(@operation)
            xml['proc'].reason(@reason)
            xml['proc'].affected_members do |xml|
              @member_ids.each do |m|
                xml['proc'].member_id(m)
              end
            end
          end
          xml['proc'].payload do |xml|
            en_ser.builder(xml)
            xml['proc'].previous_records do |xml|
              @old_id_data.each do |data|
                build_previous_record(xml, data)
              end
            end
          end
        end
      end
      builder.to_xml(:indent => 2)
    end

    def build_previous_record(xml, data)
      xml['proc'].previous_record do |xml|
        xml['proc'].member_id(data["member_id"])
        build_previous_name(xml, data)
        if !data["dob"].blank?
          xml['proc'].previous_DOB(data["dob"])
        end
        if !data["ssn"].blank?
          xml['proc'].previous_SSN(data["ssn"])
        end
        if !data["gender"].blank?
          xml['proc'].previous_gender_code(data["gender"])
        end
      end
    end

    def build_previous_name(xml, data)
      has_name_pfx = !data["name_pfx"].blank?
      has_name_sfx = !data["name_sfx"].blank?
      has_name_first = !data["name_first"].blank?
      has_name_last = !data["name_last"].blank?
      has_name_middle = !data["name_middle"].blank?
      has_names = has_name_pfx || has_name_sfx || has_name_first || has_name_middle || has_name_last
      if has_names
        xml['proc'].previous_name do |xml|
          if has_name_first?
            xml['proc'].name_first(data["name_first"])
          end
          if has_name_middle
            xml['proc'].name_middle(data["name_middle"])
          end
          if has_name_last?
            xml['proc'].name_last(data["name_last"])
          end
          if has_name_pfx
            xml['proc'].name_pfx(data["name_pfx"])
          end
          if has_name_sfx
            xml['proc'].name_sfx(data["name_sfx"])
          end
        end
      end
    end
  end
end
