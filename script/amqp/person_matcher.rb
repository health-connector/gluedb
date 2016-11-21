Rails.application.eager_load!
Forkr.new(Listeners::PersonMatcher, 5).run
