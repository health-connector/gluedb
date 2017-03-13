class EnrollmentActionIssuesController < ApplicationController
  load_and_authorize_resource(class: "EnrollmentAction::EnrollmentActionIssue")

  def index
    @enrollment_action_issues = EnrollmentAction::EnrollmentActionIssue.default_order
  end

  def show
    @enrollment_action_issue = EnrollmentAction::EnrollmentActionIssue.find(params[:id])
  end
end
