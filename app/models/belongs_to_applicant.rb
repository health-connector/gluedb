module BelongsToApplicant
  def applicant
    return nil unless application_group
    application_group.applicants.detect { |apl| applicant_id == apl._id }
  end

  def applicant=(applicant_instance)
    return unless applicant_instance.is_a? Applicant
    self.applicant_id = applicant_instance._id
  end
end
