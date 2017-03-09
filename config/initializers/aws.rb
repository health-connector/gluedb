#This assumes you have stored the parameters in environment variables

key_id=ENV['AWS_ACCESS_KEY_ID']
secret=ENV['AWS_SECRET_ACCESS_KEY']
region=ENV['AWS_REGION']

Aws.config.update({region: region,
                   credentials: Aws::Credentials.new(key_id, secret)})
