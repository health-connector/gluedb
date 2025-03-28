#!/bin/bash -xe
#set -e
## Global Vars

cd /edidb

if [ -z "$1" ]
then
  DAYS=2
else
  DAYS=$1
fi

export START_DATE=`date --date="$DAYS days ago" +%Y%m%d000000`
export ENV_NAME
export HBX_ID
export EDIDB_DB_HOST
export EDIDB_DB_NAME
export EDIDB_DB_PASSWORD
export B2B_HOST
export B2B_SERVICE_PASSWORD
export SLACK_TOKEN
export SLACK_CHANNEL
export TO_ADDRESSES
export EMAIL_FROM_ADDRESS
export EDIDB_CURL_URL
export RABBITMQ_CURL_URL
export RABBITMQ_USER
export RABBITMQ_PASSWORD
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export REPORT_ZIP_PASSWORD

## notification function
function send_sms_notification
{
cat << EOH > sms_notification.rb
#!/usr/bin/env ruby

require 'active_resource'
require 'json'
require 'aws-sdk'

ses = Aws::SES::Client.new(
  region: 'us-east-1',
  access_key_id: ENV['AWS_ACCESS_KEY_ID'],
  secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
)

date = Time.now.inspect
email_subject = "GlueDB Update $1 \n\n"
email_body = "\n$1 at: \n#{date}\n\n$2"


resp = ses.send_email({
  source: ENV['EMAIL_FROM_ADDRESS'],
  destination: {
    to_addresses: ENV.fetch('TO_ADDRESSES').split(',')
  },
  message: {
    subject: {
      data: email_subject
    },
    body: {
      text: {
        data: email_body
      }
    },
  },
  reply_to_addresses: ENV.fetch('EMAIL_FROM_ADDRESS').split(','),
})

EOH

ruby ./sms_notification.rb

}

## slack message to note the beginning of the glue update
curl -X POST -H "Content-type: application/json; charset=utf-8" -H "Authorization: Bearer ${SLACK_TOKEN}" --data '{"channel": "#SLACK_CHANNEL", "username": "EDI Database Bot", "text": "'\`' ### GlueDB Update Started ### '\`'", "icon_emoji": ":gear:"}' https://slack.com/api/chat.postMessage

cat > script.sh <<'EOL'
#!/bin/bash -xe

##App Server Vars
export PARSER_DIRECTORY='/edidb/ediparser'
export GLUEDB_DIRECTORY='/edidb'
export UPDATER_DIRECTORY='/edidb/hbx_oracle'
export START_DATE

##cleanup files
rm -f ${GLUEDB_DIRECTORY}/todays_data.zip
rm -f ${GLUEDB_DIRECTORY}/db/data/all_json.csv
rm -f ${PARSER_DIRECTORY}/*.csv
rm -f ${UPDATER_DIRECTORY}/*.csv

cat << EOH >  /edidb/gateway_transmissions.sh
unset BUNDLE_APP_CONFIG
unset BUNDLE_BIN
unset BUNDLE_PATH
unset BUNDLER_VERSION
unset GEM_HOME
unset RUBYGEMS_VERSION
PATH=/edidb/jruby-1.7.27/bin:$PATH
GEM_PATH=/edidb/jruby-1.7.27/lib/ruby/gems/shared
cd ${UPDATER_DIRECTORY}
padrino r scripts/gateway_transmissions.rb --start $START_DATE
EOH

chmod 744 /edidb/gateway_transmissions.sh

set +e
batch_handler=$( kubectl get pods | grep edidb-glue-batch | grep Running )
set -e
if [ -z "$batch_handler" ]; then
  kubectl patch cronjobs edidb-glue-batch -p "{\"spec\" : {\"suspend\" : true }}"
  curl -X POST -H "Content-type: application/json; charset=utf-8" -H "Authorization: Bearer ${SLACK_TOKEN}" --data '{"channel": "#'$SLACK_CHANNEL'", "username": "EDI Database Bot", "text": "'\`' ### GlueDB Update Started ### '\`'", "icon_emoji": ":gear:"}' https://slack.com/api/chat.postMessage
else
  exit 5
fi


## bring down the listeners
echo "bringing down listeners: "$(date)
kubectl scale --replicas=0  deployment/edidb-enrollment-validator deployment/edidb-broker-updated-listener \
                            deployment/edidb-policy-id-list-listener deployment/edidb-enrollment-event-listener \
                            deployment/edidb-enrollment-event-handler 
                            #deployment/edidb-enrollment-event-batch-processor
sleep 60
kubectl scale --replicas=0 deployment/edidb-enroll-query-result-handler
sleep 120
kubectl scale --replicas=0 deployment/edidb-employer-workers
sleep 120
kubectl scale --replicas=0 deployment/edidb-legacy-listeners
sleep 180

echo "copying prod databaase: "$(date)
mongo --host $EDIDB_DB_HOST --authenticationDatabase 'admin' -u 'admin' -p $EDIDB_DB_PASSWORD < ~/scripts/prepare_dev.js

sleep 10

/edidb/gateway_transmissions.sh
cp ${UPDATER_DIRECTORY}/b2b_edi.csv ${PARSER_DIRECTORY}
cat ${PARSER_DIRECTORY}/b2b_edi.csv | ${PARSER_DIRECTORY}/dist/build/InterchangeTest/InterchangeTest > ${PARSER_DIRECTORY}/all_json.csv
mkdir -p ${GLUEDB_DIRECTORY}/db/data
cp ${PARSER_DIRECTORY}/all_json.csv ${GLUEDB_DIRECTORY}/db/data/needs_preprocessing_json.csv

cd ${GLUEDB_DIRECTORY}
#echo -e '\ngem "rubycritic"' >> Gemfile
#bundle install
RAILS_ENV=development bundle exec rake edi:import:pre_import_transform 
RAILS_ENV=development bundle exec rake edi:import:all
RAILS_ENV=development rails r script/queries/set_authority_members.rb
#head -n -1 Gemfile > Gemfile.tmp
#mv Gemfile.tmp Gemfile

echo "updating prod database: "$(date)
update=`mongo --host $EDIDB_DB_HOST --authenticationDatabase 'admin' -u 'admin' -p $EDIDB_DB_PASSWORD < ~/scripts/prepare_prod.js`
echo $update
update=$(echo -n ${update#*"db ${EDIDB_DB_NAME}_dev"})
update=$(echo -n ${update%bye*})
update=$(echo -n ${update#*clone})
update_status=`echo $update | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["'ok'"]'`

sleep 60

if [ "$update_status" -eq 1 ]; then

  #curl -X POST -H "Content-type: application/json; charset=utf-8" -H "Authorization: Bearer ${SLACK_TOKEN}" --data '{"channel": "#'$SLACK_CHANNEL'", "username": "EDI Database Bot", "text": "'\`' ### GlueDB Update Completed :: Running Reports Before Starting Listeners ### '\`'", "icon_emoji": ":gear:"}' https://slack.com/api/chat.postMessage

  #cp /etc/reports/glue_enrollment_report.sh /edidb/glue_enrollment_report.sh && chmod 744 /edidb/glue_enrollment_report.sh
  #cp /etc/reports/glue_enrollment_report.json.template /edidb/glue_enrollment_report.json.template
  #/edidb/glue_enrollment_report.sh > glue_enrollment_report.log
  #tail -30 glue_enrollment_report.log

  #cp /etc/reports/policies_missing_transmissions.sh /edidb/policies_missing_transmissions.sh && chmod 744 /edidb/policies_missing_transmissions.sh
  #cp /etc/reports/policies_missing_transmissions.json.template /edidb/policies_missing_transmissions.json.template
  #/edidb/policies_missing_transmissions.sh > policies_missing_transmissions.log
  #tail -10 policies_missing_transmissions.log

  kubectl scale --replicas=1 deployment/edidb-legacy-listeners
  messages=1
  while [ $messages -gt 0 ]
  do
    sleep 120
    messages=$( curl --user $RABBITMQ_USER:$RABBITMQ_PASSWORD $RABBITMQ_CURL_URL/api/queues/%2F/$HBX_ID.$ENV_NAME.q.glue.individual_updated_listener | jq .messages | tail -1 )
  done
  kubectl scale --replicas=1 deployment/edidb-employer-workers
  sleep 120
  kubectl scale --replicas=2 deployment/edidb-enroll-query-result-handler
  sleep 120
  kubectl scale --replicas=2 deployment/edidb-enrollment-validator deployment/edidb-broker-updated-listener \
                             deployment/edidb-policy-id-list-listener deployment/edidb-enrollment-event-listener \
                             deployment/edidb-enrollment-event-handler 
                             #deployment/edidb-enrollment-event-batch-processor
  sleep 120
  kubectl patch cronjobs edidb-glue-batch -p "{\"spec\" : {\"suspend\" : false }}"
  kubectl rollout restart deployment edidb-$ENV_NAME
else
  exit 1
fi

EOL

chmod +x script.sh
set +e
./script.sh
update_status=$?
set -e
sleep 120

curlTestCmd="curl -sLk -w "%{http_code}" -o /dev/null ${EDIDB_CURL_URL}/accounts/sign_in"
curlTest=`eval $curlTestCmd`

if [ "$update_status" -eq 0 ]
then
  if [ "$curlTest" == "200" ]
  then
    curl -X POST -H "Content-type: application/json; charset=utf-8" -H "Authorization: Bearer ${SLACK_TOKEN}" --data '{"channel": "#'$SLACK_CHANNEL'", "username": "EDI Database Bot", "text": "'\`' ### GlueDB Update Completed :: Listeners Are Up ### '\`'", "icon_emoji": ":gear:"}' https://slack.com/api/chat.postMessage
    send_sms_notification Success
    exit 0
  else
    curl -X POST -H "Content-type: application/json; charset=utf-8" -H "Authorization: Bearer ${SLACK_TOKEN}" --data '{"channel": "#'$SLACK_CHANNEL'", "username": "EDI Database Bot", "text": "'\`' ### GlueDB Update Completed :: But Restart Failed ### '\`'", "icon_emoji": ":gear:"}' https://slack.com/api/chat.postMessage
    send_sms_notification "Restart Failed"
    exit 1
  fi
elif [ "$update_status" -eq 5 ]
then
  curl -X POST -H "Content-type: application/json; charset=utf-8" -H "Authorization: Bearer ${SLACK_TOKEN}" --data '{"channel": "#'$SLACK_CHANNEL'", "username": "EDI Database Bot", "text": "<!channel> '\`' ### GlueDB Update Did Not Start -- Batch Handler Is Running ### '\`'", "icon_emoji": ":gear:"}' https://slack.com/api/chat.postMessage
  send_sms_notification "Did Not Start" "The batch handler is running!"
  exit 1
else
  curl -X POST -H "Content-type: application/json; charset=utf-8" -H "Authorization: Bearer ${SLACK_TOKEN}" --data '{"channel": "#'$SLACK_CHANNEL'", "username": "EDI Database Bot", "text": "<!channel> '\`' ### GlueDB Update Failed ### '\`'", "icon_emoji": ":gear:"}' https://slack.com/api/chat.postMessage
  send_sms_notification Failed "Please check GlueDB Update job in ${ENV_NAME}"
  exit 1
fi
