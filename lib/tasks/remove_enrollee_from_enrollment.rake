require File.join(Rails.root,"app","data_migrations","remove_enrollee_from_enrollment")

# This rake tasks removes enrollees from Enrollments.
# RAILS_ENV=production bundle exec rake migrations:remove_enrollee_from_enrollment eg_id='123456' m_id='4624327'

namespace :migrations do 
  desc "Remove Enrollee from Enrollment"
  RemoveEnrolleeFromEnrollment.define_task :remove_enrollee_from_enrollment => :environment
end