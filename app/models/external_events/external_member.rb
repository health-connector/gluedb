module ExternalEvents
  class ExternalMember
    attr_reader :member_node

    # m_node : Openhbx::Cv2::EnrolleeMember
    def initialize(m_node)
      @member_node = m_node
    end

    def persist
      if existing_person
        true
      else
        build_new_person
      end
    end

    def build_new_person
      true
    end

    def existing_person
      @existing_person ||= Person.find_for_member_id(member_id)
    end

    def member_id
      Maybe.new(member_node).id.strip.split("#").last.value
    end
  end
end
