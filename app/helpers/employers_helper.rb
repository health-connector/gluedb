module EmployersHelper


  def controls_for_employers(employer)
    # TODO: add roles/filters
    # if current_user.manages?(employer)
    if user_signed_in?
      partial = controls_partial_for_employers(employer)
      contents = render(partial: partial, locals: {employer: employer})
      content_tag(:ul, contents, class: "nav nav-list")
    end
  end

  def controls_partial_for_employers(employer)
    'employers/controls/admin' 
    # if current_user.admin?
    #   'employer/controls/admin'
    # elsif current_user.author?
    #   'employer/controls/author'
    # elsif current_user.editor?
    #   'employer/controls/editor'
    # end
  end

end