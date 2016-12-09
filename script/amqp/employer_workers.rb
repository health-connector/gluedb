require "multi_forkr"

MultiForkr.run({
Listeners::EmployerEventReducerListener => 1,
Listeners::EmployerUpdatedListener => 1
})
