class EdiQueueSetup
  def initialize
    conn = Bunny.new(ExchangeInformation.amqp_uri)
    conn.start
    @ch = conn.create_channel
  end

  def exchange(e_type, name)
    @ch.send(e_type.to_sym, name, {:durable => true})
  end

  def queue(q)
    @ch.queue(q, :durable => true)
  end

  def logging_queue(ec, name)
    q_name = "#{ec.hbx_id}.#{ec.environment}.q.logging.#{name}"
    @ch.queue(q_name, :durable => true)
  end

  def gate_queue(ec, name)
    q_name = "#{ec.hbx_id}.#{ec.environment}.q.gateing.#{name}"
    @ch.queue(q_name, :durable => true)
  end

  def run
    ec = ExchangeInformation
    ev_exchange = exchange(:topic, ec.event_exchange)

    req_exchange = exchange(:direct, ec.request_exchange)

    edi_q = queue(Listeners::EdiQueueListener.queue_name)
    edi_q.bind(ev_exchange, :routing_key => "enrollment.*.sep")
    edi_q.bind(req_exchange, :routing_key => "enrollment.error")
    
    emake_q = queue(Listeners::EnrollmentCreator.queue_name)
    emake_q.bind(req_exchange, :routing_key => "enrollment.create")

    other_queue = logging_queue(ec, "initial_and_renewal")
    other_queue.bind(ev_exchange, {
      :routing_key => "enrollment.*.initial_enrollment"
    })
    other_queue.bind(ev_exchange, {
      :routing_key => "enrollment.*.renewal"
    })

    # Gateing cues for legacy items
    ie_cv_q = gate_queue(ec, "legacy.policy.initial_enrollment")
    ie_cv_q.bind(req_exchange, { :routing_key => "policy.initial_enrollment" })

    ren_cv_q = gate_queue(ec, "legacy.policy.renewals")
    ren_cv_q.bind(req_exchange, { :routing_key => "policy.renewal" })
  end
end

EdiQueueSetup.new.run
