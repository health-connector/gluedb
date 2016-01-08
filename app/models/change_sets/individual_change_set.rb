module ChangeSets
  class IndividualChangeSet
    def initialize(remote_resource)
      @individual_resource = remote_resource
    end

    def individual_exists?
      @individual_resource.exists?
    end

    def create_individual_resource
    end

    def full_error_messages
    end

    def any_changes?
    end

    def dob_changed?
    end

    def multiple_changes?
    end

    def has_active_policies?
    end

    def update_individual_record
    end

    def process_first_edi_change
    end
  end
end
