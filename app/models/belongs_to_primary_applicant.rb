module BelongsToPrimaryApplicant
  def primary_applicant=(person_instance)
    self.primary_applicant_id = person_instance._id
  end

  def primary_applicant
    return nil unless application_group
    application_group.applicants.detect { |apl| primary_applicant_id == apl._id }
  end
end
