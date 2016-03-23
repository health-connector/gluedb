require 'csv'

timestamp = Time.now.strftime('%Y%m%d%H%M')

def user_state(approved, last_sign_in_at)
  return "active" if approved
  last_sign_in_at.blank? ? "never active" : "disabled"
end

CSV.open("all_glue_users_#{timestamp}.csv","w") do |csv|
	csv << ["User","Role", "Status", "Inactive Date (if applicable)"]
	User.all.each do |user|
		user_email = user.email
		user_approval_status = user.approved
		user_role = user.role
    user_status = user_state(user.approved, user.last_sign_in_at)
    deactivation_date = (user_status == "disabled") ? user.last_sign_in_at.strftime("%Y-%m-%dT%l:%M:%S%z"): nil 
		csv << [user_email,user_role,user_status,deactivation_date]
	end
end
