module HasApplicants
  def applicants
    return [] unless application_group
    application_group.applicants.select { |apl| applicant_ids.include?(apl._id) }
  end

  def people
    applicants.map(&:person)
  end
end
