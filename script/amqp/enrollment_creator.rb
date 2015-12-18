Rails.application.eager_load!
Forkr.new(Listeners::EnrollmentCreator, 2).run
