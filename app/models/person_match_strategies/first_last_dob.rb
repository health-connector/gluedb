module PersonMatchStrategies
  class FirstLastDob
    def match(options = {})
      name_first_regex = Regexp.compile(Regexp.escape(options[:name_first].to_s.strip.downcase), true)
      name_last_regex = Regexp.compile(Regexp.escape(options[:name_last].to_s.strip.downcase), true)
      search_dob = cast_dob(options[:dob])
      found_people = Person.where({"members.dob" => search_dob, "name_first" => name_first_regex, "name_last" => name_last_regex})
      if found_people.any?
        if found_people.many?
          raise AmbiguousMatchError.new("Multiple people with same first, last, and dob: #{options[:name_first]}, #{options[:name_last]}, #{options[:dob]}")
        else
          select_authority_member(found_people.first, options)
        end
      else
        [nil, nil]
      end
    end

    def cast_dob(dob)
      if dob.kind_of?(Date)
        return dob
      elsif dob.kind_of?(DateTime)
        return dob
      end
      Date.parse(dob)
    end

    def select_authority_member(person, options)
      if !person.authority_member.present?
        raise AmbiguousMatchError.new("No authority member for person with first, last, and dob: #{options[:name_first]}, #{options[:name_last]}, #{options[:dob]}")
      end
      [person, person.authority_member]
    end
  end
end
