class ExchangeInformation

  class MissingKeyError < StandardError
    def initialize(key)
      super("Missing required key: #{key}") 
    end
  end

  include Singleton

  REQUIRED_KEYS = [
    'receiver_id',
    'invalid_argument_queue',
    'processing_failure_queue',
    'request_exchange',
    'event_exchange',
    'event_publish_exchange',
    'environment',
    'hbx_id',
    'file_storage_uri'
  ]

  attr_reader :config, :amqp_connection_settings

  # TODO: I have a feeling we may be using this pattern
  #       A LOT.  Look into extracting it if we repeat.
  def initialize
    @config = YAML.load(ERB.new(File.read(File.join(Rails.root,'config', 'exchange.yml'))).result)
    ensure_configuration_values(@config)
    encode_amqp_connection_settings
  end

  def ensure_configuration_values(conf)
    REQUIRED_KEYS.each do |k|
      if @config[k].blank?
        raise MissingKeyError.new(k)
      end
    end
  end

  def self.define_key(key)
    define_method(key.to_sym) do
      config[key.to_s]
    end
    self.instance_eval(<<-RUBYCODE)
      def self.#{key.to_s}
        self.instance.#{key.to_s}
      end
    RUBYCODE
  end

  REQUIRED_KEYS.each do |k|
    define_key k
  end

  def self.amqp_connection_settings
    self.instance.amqp_connection_settings
  end

  def encode_amqp_connection_settings
    raise MissingKeyError.new(":amqp_uri OR :amqp_cluster") if config['amqp_cluster'].blank? && config['amqp_uri'].blank?
    if config['amqp_cluster']
      @amqp_connection_settings = config['amqp_cluster'].symbolize_keys.merge({
        :heartbeat => 10
      })
    else
        uri = URI.parse(config['amqp_uri'])
        port_value = uri.port.blank? ? 5672 : uri.port
        user_value = uri.user.blank? ? "guest" : uri.user
        password_value = uri.password.blank? ? "guest" : uri.password
        @amqp_connection_settings = {
          :host => uri.host,
          :port => port_value,
          :username => user_value,
          :password => password_value,
          :heartbeat => 10
        }
    end
  end
end
