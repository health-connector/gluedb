class PolicyIdGenerator
  P_ID_URL = "http://10.83.85.127:8080/sequences/policy_id"

  def initialize(size = 1)
    @b_size = size
    @buffer = []
  end

  def new_batch_of(count = 1)
    JSON.parse(Net::HTTP.get(URI.parse(P_ID_URL + "?count=#{count}")))
  end

  def get_id
    pack_buffer if empty_buffer?
    @buffer.shift
  end

  def empty_buffer?
    @buffer.empty?
  end

  protected
  def pack_buffer
    @buffer = new_batch_of(@b_size).dup
  end
end
