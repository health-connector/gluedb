module ControllerMacros
  def login_user
    before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      user = create :user, :edi_ops
      sign_in user
    end
  end
end
