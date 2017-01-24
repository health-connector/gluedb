module EnrollmentActionIssuesHelper
  def short_enrollment_action_uri(ea_uri)
    Maybe.new(ea_uri).strip.split("#").last.value
  end
end
