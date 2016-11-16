class EnrollmentEventClient
  attr_reader :stack

  delegate :call, :to => :stack

  def initialize
    @stack =  Middleware::Builder.new do |b|
      b.use Handlers::ReducerHandler
      b.use Handlers::EnricherHandler
      b.use Handlers::PersistanceHandler
      b.use Handlers::PublisherHandler
    end
  end

  def steps
    # This is ugly, but it's really the only way to expose the stack
    # for testing - I'd prefer it were public.
    @stack.instance_eval do
      stack
    end
  end
end
