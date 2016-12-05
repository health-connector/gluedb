module BusinessProcesses
  class AffectedMember
    attr_accessor :policy
    attr_accessor :member_id

    FROM_PERSON = [
      :name_first,
      :name_last,
      :name_middle,
      :name_pfx,
      :name_sfx]

    FROM_MEMBER = [
      :gender,
      :ssn,
      :dob]

    FROM_PERSON.each do |prop|
      class_eval(<<-RUBY_CODE)
        attr_reader :#{prop.to_s}

        def #{prop.to_s}=(val)
          @old_names_set = true
          @#{prop.to_s} = val
        end
      RUBY_CODE
    end

    FROM_MEMBER.each do |prop|
      class_eval(<<-RUBY_CODE)
        attr_reader :#{prop.to_s}

        def #{prop.to_s}=(val)
          @old_#{prop.to_s}_set = true
          @#{prop.to_s} = val
        end
      RUBY_CODE
    end

    FROM_PERSON.each do |prop|
      class_eval(<<-RUBY_CODE)
        def old_#{prop.to_s}
          if @old_names_set
            return #{prop.to_s}
          end
          enrollee.person.#{prop.to_s}
        end
      RUBY_CODE
    end

    FROM_MEMBER.each do |prop|
      class_eval(<<-RUBY_CODE)
        def old_#{prop.to_s}
          if @old_#{prop.to_s}_set
            return #{prop.to_s}
          end
          enrollee.person.authority_member.#{prop.to_s}
        end
      RUBY_CODE
    end

    def initialize(props = {})
      props.each_pair do |k, v|
        send("#{k.to_s}=".to_sym, v)
      end
    end

    def enrollee
      @enrollee ||= policy.enrollees.detect { |en| en.m_id == member_id }
    end
  end
end
