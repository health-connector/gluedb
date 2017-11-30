def publish_cancel_to_bus(conn, policy)
  hbx_enrollment_ids = policy.hbx_enrollment_ids
  resource_instance_uri = policy.eg_id
  key = "info.events.policy.canceled"
  eb = Amqp::EventBroadcaster.new(conn)
  eb.broadcast(
    {
      :routing_key => key,
      :headers => {
        :resource_instance_uri => resource_instance_uri,
        :hbx_enrollment_ids => JSON.dump(hbx_enrollment_ids)
      }
    },
    ""
  )
end

def publish_term_to_bus(conn, policy, end_date)
  hbx_enrollment_ids = policy.hbx_enrollment_ids
  resource_instance_uri = policy.eg_id
  key = "info.events.policy.terminated"
  eb = Amqp::EventBroadcaster.new(conn)
  eb.broadcast(
    {
      :routing_key => key,
      :headers => {
        :resource_instance_uri => resource_instance_uri,
        :event_effective_date => end_date,
        :hbx_enrollment_ids => JSON.dump(hbx_enrollment_ids)
      }
    },
    ""
  )
end

amqp_conn = AmqpConnectionProvider.start_connection

CSV.open("process_non_payment_results.csv", "w") do |csv|
  csv << ["enrollment_group_id", "result"]
  CSV.foreach("non_pay_terms.csv", :headers => true) do |row|
    fields = row.fields
    enrollment_group_id = fields[1]
    end_date = fields[7]
    action_type = fields[8]
    is_cancel = (action_type.strip.downcase == "cancel") ? true : false
    pol = Policy.where(:eg_id => enrollment_group_id.strip).first
    if pol
      if is_cancel
        publish_cancel_to_bus(amqp_conn, pol)
        csv << [enrollment_group_id, "cancel sent"]
      else
        publish_term_to_bus(amqp_conn, pol, end_date)
        csv << [enrollment_group_id, "term sent"]
      end
    else
      csv << [enrollment_group_id, "not found"]
    end
  end
end

amqp_conn.close
