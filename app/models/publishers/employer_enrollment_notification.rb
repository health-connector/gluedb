module Publishers
  class EmployerEnrollmentNotification

    attr_reader :employer

    def initialize(employer)
      @employer = employer
    end

    def employer_policies

      policies = Policy.where( :employer_id => employer.id,
                               :aasm_state.in => %w[submitted resubmitted effectuated],
                               :enrollees =>
                                   { "$elemMatch" => {"$or" => [
                                       {"coverage_end" => nil},
                                       {"coverage_end" => { "$gt" => Time.now }}]
                                   }
                               })
      policies.select{|pol| (pol.is_active? || pol.future_active?) && pol.carrier.shop_profile.requires_employer_updates_on_enrollments }
    end

    def render_cv(policy)
      affected_members = policy.active_member_ids.map do |a_member_id|
        ::BusinessProcesses::AffectedMember.new({
                                                    :policy => policy,
                                                    :member_id => a_member_id
                                                })
      end
      ApplicationController.new.render_to_string(
          :layout => "enrollment_event",
          :partial => "enrollment_events/enrollment_event",
          :format => :xml,
          :locals => {
              :affected_members => affected_members,
              :policy => policy,
              :enrollees => policy.enrollees.reject { |e| e.canceled? || e.terminated? },
              :event_type => "urn:openhbx:terms:v1:enrollment#initial",
              :transaction_id => transaction_id
          }
      )
    end

    def process_enrollments_for_edi
      return unless employer_policies
      amqp_connection = AmqpConnectionProvider.start_connection
      begin
        employer_policies.each do |policy|
          render_result = render_cv(policy)
          publish_edi(amqp_connection, render_result, policy)
        end
      rescue Exception => e
        e.backtrace.join("\n")
      end
      amqp_connection.close
    end

    def publish_edi(amqp_connection, render_result, policy)
      begin
        publisher = Publishers::TradingPartnerEdi.new(amqp_connection, render_result)
        publish_result = false
        publish_result = publisher.publish
        if publish_result
          publisher2 = Publishers::TradingPartnerLegacyCv.new(amqp_connection, render_result, policy.eg_id, employer.hbx_id)
          unless publisher2.publish
            return [false, publisher2.errors.to_hash]
          end
        end
        [publish_result, publisher.errors.to_hash]
      rescue Exception => e
        e.backtrace.join("\n")
      end
    end

    def transaction_id
      @transcation_id ||= begin
        ran = Random.new
        current_time = Time.now.utc
        reference_number_base = current_time.strftime("%Y%m%d%H%M%S") + current_time.usec.to_s[0..2]
        reference_number_base + sprintf("%05i", ran.rand(65535))
      end
    end
  end
end