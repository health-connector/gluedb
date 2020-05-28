class TransactionIdGenerator
  def self.generate_bgn02_compatible_transaction_id
    ran = Random.new
    current_time = Time.now.utc
    reference_number_base = current_time.strftime("%Y%m%d%H%M%S") + current_time.usec.to_s[0..2]
    reference_number_base + sprintf("%05i", ran.rand(65535))
  end
end