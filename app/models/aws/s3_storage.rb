module Aws
  class S3Storage
    ENV_LIST = ['local', 'prod', 'preprod', 'uat', 'cte', 'ctf']

    def initialize
      setup
    end

    # If success, return URI which has the s3 bucket key
    # else return nil
    # raises exception if exception occurs
    def save(file_path:, bucket_name:, key:SecureRandom.uuid, options: {})
      bucket_name = fetch_bucket(bucket_name, options)
      uri = "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket_name}##{key}"
      begin
        object = get_object(bucket_name, key)
        if object.upload_file(file_path, :server_side_encryption => 'AES256')
          uri
        else
          nil
        end
      rescue Exception => e
        raise e
      end
    end

    def fetch_bucket(bucket_name, args_items)
      if args_items[:internal_artifact]
        bucket_name
      else
        env_bucket_name(bucket_name)
      end
    end

    # If success, return URI which has the s3 bucket key
    # else return nil
    def self.save(file_path:, bucket_name:, key: SecureRandom.uuid, options: {})
      Aws::S3Storage.new.save(file_path: file_path, bucket_name: bucket_name, key: key, options: options)
    end

    # Here's an option to publish to SFTP.
    def publish_to_sftp(filename, transport_process, uri)
      conn = AmqpConnectionProvider.start_connection
      eb = Amqp::EventBroadcaster.new(conn)
      aws_key = uri.split("#").last
      props = {:headers => {:aws_uri => aws_key, :file_name => filename, :artifact_key => transport_process}}
      eb.broadcast(props, "payload")
      conn.close
    end

    # The uri has information about the bucket name and key
    # e.g. "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket_name}##{key}"
    # The returned object can be streamed by controller
    # e.g. send_data Aws::S3Storage.find(uri), :stream => true, :buffer_size => ‘4096’
    def find(uri)
      begin
        bucket_and_key = uri.split(':').last
        bucket_name, key = bucket_and_key.split('#')
        env_bucket_name = set_correct_env_bucket_name(bucket_name)
        object = get_object(env_bucket_name, key)
        read_object(object)
      rescue Exception => e
        nil
      end
    end

    # The param uri is present in Document model. Document.identifier
    # The uri has information about the bucket name and key
    # e.g. "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket_name}##{key}"
    # The returned object can be streamed by controller
    # e.g. send_data Aws::S3Storage.find(uri), :stream => true, :buffer_size => ‘4096’
    def self.find(uri)
      Aws::S3Storage.new.find(uri)
    end

    private
    def read_object(object)
      object.get.body.read
    end

    def get_object(bucket_name, key)
      @resource.bucket(bucket_name).object(key)
    end

    def set_correct_env_bucket_name(bucket_name)
      bucket_name_segment = bucket_name.split('-')
      if ENV_LIST.include? bucket_name_segment.last && bucket_name_segment.last == aws_env
        return bucket_name
      else
        bucket_name_segment[bucket_name_segment.length - 1] = aws_env
        return bucket_name_segment.join('-')
      end
    end

    def aws_env
      ENV['AWS_ENV'] || "local"
    end

    def env_bucket_name(bucket_name)
      "#{Settings.abbrev}-gluedb-#{bucket_name}-#{aws_env}"
    end

    def env_bucket_for_glue_report
      "#{Settings.abbrev}-#{aws_env}-aca-internal-artifact-transport"
    end

    def setup
      client=Aws::S3::Client.new
      @resource=Aws::S3::Resource.new(client: client)
    end

  end
end
