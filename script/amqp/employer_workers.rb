require "multi_forkr"
Rails.application.eager_load!
MultiForkr.new({
# Listeners::EmployerEventReducerListener => 1,
Listeners::EmployerUpdatedListener => 1
}).run
