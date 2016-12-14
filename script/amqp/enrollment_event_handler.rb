Rails.application.eager_load!
Forkr.new(Listeners::EnrollmentEventHandler, 3).run
