module ExternalEvents
  class ExternalPolicy
    attr_reader :policy_node
    attr_reader :plan

    # m_node : Openhbx::Cv2::EnrolleeMember
    def initialize(p_node, p_record)
      @policy_node = p_node
      @plan = p_record
    end

    def persist
      true
    end
  end
end
