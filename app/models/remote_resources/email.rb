module RemoteResources
  class Email
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'email'
    namespace 'cv'

    element :type, String, tag: "type"
    element :email_address, String, tag: "email_address"

    def email_type
      email_kind
    end

    def email_kind
      Maybe.new(type).split("#").last.downcase.value
    end

    def [](key)
      self.send(key)
    end

    def to_hash
      {
        :email_type => email_type,
        :email_address => email_address
      }
    end
  end
end
