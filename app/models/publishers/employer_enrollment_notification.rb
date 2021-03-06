module Publishers
  class EmployerEnrollmentNotification

    PublishError = Struct.new(:message, :headers)

    attr_reader :employer

    def initialize(employer)
      @employer = employer
    end

    def employer_policies
      policies = Policy.where(:employer_id => employer.id,
                              :carrier_id.in => enrollment_update_required_carrier,
                              :enrollees =>
                                   { "$elemMatch" => {
                                       "rel_code" => 'self',
                                       "coverage_start" => { "$gt" => Date.today - 1.year },
                                       "coverage_end" => nil
                                       }
                                   })

      policies.select{|pol| (pol.is_active? || pol.future_active?)}  # extra check.
    end

    def enrollment_update_required_carrier
       Carrier.all.inject([]) do |carrier_id, carrier|
         if carrier.requires_employer_updates_on_enrollments
           carrier_id << carrier.id
         end
         carrier_id
      end
    end

    def render_cv(policy)
      affected_members = ::BusinessProcesses::AffectedMember.new({
                                                    :policy => policy,
                                                    :member_id => policy.subscriber.m_id
                                                })
      ApplicationController.new.render_to_string(
          :layout => "enrollment_event",
          :partial => "enrollment_events/enrollment_event",
          :format => :xml,
          :locals => {
              :affected_members => [affected_members],
              :policy => policy,
              :enrollees => policy.enrollees.reject { |e| e.canceled? || e.terminated? },
              :event_type => "urn:openhbx:terms:v1:enrollment#change_member_communication_numbers",
              :transaction_id => transaction_id,
              :premium_effective_date => policy.calculated_premium_effective_date
          }
      )
    end

    def process_enrollments_for_edi
      return unless employer_policies
      amqp_connection = AmqpConnectionProvider.start_connection
      begin
        employer_policies.each do |policy|
          render_result = render_cv(policy)
          publish_result, errors = publish_edi(amqp_connection, render_result, policy)
          headers = errors.headers.any? ? errors.headers.merge({:return_status => "500"}) : { :return_status => "200" }
          error_message = errors.headers.any? ? errors.message : nil
          EnrollmentAction::EnrollmentActionIssue.create!({
                                                              :hbx_enrollment_id => policy.eg_id,
                                                              :hbx_enrollment_vocabulary => render_result,
                                                              :enrollment_action_uri => "urn:openhbx:terms:v1:enrollment#sponsor_information_change",
                                                              :error_message => error_message,
                                                              :headers => headers,
                                                              :received_at =>  Time.now
                                                          })
        end
      ensure
        amqp_connection.close
      end
    end

    def publish_edi(amqp_connection, render_result, policy)
      begin
        publisher = Publishers::TradingPartnerEdi.new(amqp_connection, render_result)
        publish_result = false
        publish_result = publisher.publish

        if publish_result
          publisher2 = Publishers::TradingPartnerLegacyCv.new(amqp_connection, render_result, policy.eg_id, employer.hbx_id)
          unless publisher2.publish
            return [false, PublishError.new("CV1 Publish Failed", { :error_message => publisher2.errors[:error_message]})]
          end
        else
          return [false, PublishError.new("EDI Codec CV2 Publish Failed", { :error_message => publisher.errors[:error_message]})]
        end

        [publish_result, PublishError.new("EDI Codec CV2/Leagcy CV1 Published Sucessfully", {})]
      rescue Exception => e
        return [false, PublishError.new("Publish EDI Failed", {:error_message => e.message, :error_type => e.class.name, :backtrace => e.backtrace[0..5].join("\n")})]
      end
    end

    def transaction_id
      @transcation_id ||= TransactionIdGenerator.generate_bgn02_compatible_transaction_id
    end
  end
end