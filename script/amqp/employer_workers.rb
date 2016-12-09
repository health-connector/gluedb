require "multi_forkr"

MultiForkr.new({
Listeners::EmployerEventReducerListener => 1,
Listeners::EmployerUpdatedListener => 1
}).run
