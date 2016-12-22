require "multi_forkr"
Rails.application.eager_load!
MultiForkr.new({
  Listeners::IndividualEventListener => 1,
  Listeners::EnrollmentCreator => 4,
  Listeners::PersonMatcher => 5
}).run
