Rails.application.eager_load!
Forkr.new(Listeners::EnrollQueryResultHandler, 2).run
