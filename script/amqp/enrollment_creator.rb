Rails.application.eager_load!
Forkr.new(Listeners::EnrollmentCreator, 4).run
