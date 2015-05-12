module Features
  def sign_up_as(user)
    visit new_user_registration_path

    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
#    fill_in 'Confirm password', with: user.password_confirmation
    click_button 'Sign up'
  end

  def sign_in_with(email, password)
    allow(Protocols::X12::TransactionSetEnrollment).to receive(:last).and_return(double(updated_at: Time.now))
    fill_in 'Email', with: email
    fill_in 'Password', with: password
    click_button 'Sign In'
  end
end
