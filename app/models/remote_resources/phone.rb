module RemoteResources
  class Phone
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'phone'
    namespace 'cv'

    element :type, String, tag: "type"
    element :full_phone_number, String, tag: "full_phone_number"

    def phone_type
      phone_kind
    end

    def phone_number
      full_phone_number
    end

    def phone_kind
      Maybe.new(type).split("#").last.downcase.value
    end

    def ignored?
      !::Phone::TYPES.include?(phone_kind)
    end

    def [](key)
      self.send(key)
    end

    def to_hash
      {
        :phone_type => phone_type,
        :phone_number => phone_number
      }
    end
  end
end
