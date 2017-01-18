module ExternalEvents
  class ExternalPolicy
    attr_reader :policy_node

    # m_node : Openhbx::Cv2::EnrolleeMember
    def initialize(p_node)
      @policy_node = p_node
    end

    def persist
      true
    end
  end
end
