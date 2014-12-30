module PersonMatchStrategies
  class FirstLastDob
    def match(options = {})
      name_first_regex = Regexp.compile(Regexp.escape(options[:name_first].to_s.strip.downcase), true)
      name_last_regex = Regexp.compile(Regexp.escape(options[:name_last].to_s.strip.downcase), true)
      found_people = Person.where({"members.dob" => options[:dob], "name_first" => name_first_regex, "name_last" => name_last_regex})
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

    def select_authority_member(person, options)
      if !person.authority_member.present?
        raise AmbiguousMatchError.new("No authority member for person with first, last, and dob: #{options[:name_first]}, #{options[:name_last]}, #{options[:dob]}")
      end
      [person, person.authority_member]
    end
  end
end
