class EnrollmentEventProcessingClient < Middleware::Builder
  def initialize
    super do |b|
      b.use Handlers::EnrollmentEventReduceHandler
    end
  end

  def stack
    super
  end
end
