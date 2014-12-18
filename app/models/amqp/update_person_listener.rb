module Amqp
  class UpdatePersonListener < Client

    def initialize(ch, q, configuration)
      super(ch, q)
      @configuration = configuration
    end

    def on_message(delivery_info, properties, payload)
      individual_uri = properties.headers["individual_uri"]
      person_resource_routing_key = @configuration.person_resource_queue
      delivery_info_response, response_properties, individual_xml = request(
        {:routing_key => person_resource_routing_key, :individual_uri => individual_uri},
        ""
      )

      # Turn individual response payload into a PersonUpdateRequest
      request = UpdatePersonAddressRequest.from_cv(individual_xml)

      # Execute the UpdatePerson use case with that request
      person = Person.find(request[:person_id])
      listener = UpdatePersonErrorCatcher.new(person)
      address_changer = ChangeMemberAddress.new(TransmitPolicyMaintenance.new)
      update_person = UpdatePersonAddress.new(Person, address_changer, ChangeAddressRequest)
      update_person.execute(request, listener)
    end

    def validate(delivery_info, properties, payload)
      # Override me
      if properties.headers["individual_uri"].blank?
        add_error("No individual uri specified!")
      end
    end
  end
end