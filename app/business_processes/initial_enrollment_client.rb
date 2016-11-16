class InitialEnrollmentClient
  attr_reader :stack

  def initialize
    @stack =  Middleware::Builder.new do |b|
      b.use TransformAndEmitEnrollment, :initial_enrollment
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
