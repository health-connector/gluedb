module PersonMatchStrategies
  class FirstLastEmail
    def match(options)
      if (!options[:email].blank?)
        name_first_regex = Regexp.compile(Regexp.escape(options[:name_first].to_s.strip.downcase), true)
        name_last_regex = Regexp.compile(Regexp.escape(options[:name_last].to_s.strip.downcase), true)
        found_people = Person.where({"name_first" => name_first_regex, "name_last" => name_last_regex, "emails.email_address" => options[:email]})
        if found_people.any?
          if found_people.many?
            raise AmbiguousMatchError.new("Multiple people with same first, last, and email: #{options[:name_first]}, #{options[:name_last]}, #{options[:email]}")
          else
            return select_authority_member(found_people.first, options)
          end
        end
      end
      [nil, nil]
    end

    def select_authority_member(person, options)
      if !person.authority_member.present?
        if person.members.length > 0
          raise AmbiguousMatchError.new("No authority member for person with first, last, and email: #{options[:name_first]}, #{options[:name_last]}, #{options[:email]}")
        end
        return [person, nil]
      end
      [person, person.authority_member]
    end
  end
end
