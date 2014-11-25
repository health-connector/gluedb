module Queries
  class PersonMatch
    def self.find(options)
      found_person = nil

      if (!options[:member_id].blank?)
        found_person = Person.find_by_member_id(options[:member_id])
        return found_person if found_person
      end
      found_people = Person.where({"members.ssn" => options[:ssn]})
      if (found_people.length > 0)
        if (!options[:name_last].nil?)
          filtered = found_people.select { |per| per.name_last.downcase == options[:name_last].downcase }
          found_person = more_than_one_is_none(filtered)
        else
          found_person = more_than_one_is_none(found_people)
        end
      end
      if (found_person.nil?)
        name_first_regex = Regexp.compile(Regexp.escape(options[:name_first].to_s.strip.downcase), true)
        name_last_regex = Regexp.compile(Regexp.escape(options[:name_last].to_s.strip.downcase), true)
        found_people = Person.where({"members.dob" => options[:dob], "name_first" => name_first_regex, "name_last" => name_last_regex})
        found_person = more_than_one_is_none(found_people)
      end

      if(found_person.nil?)
        if (!options[:email].blank?)
          name_first_regex = Regexp.compile(Regexp.escape(options[:name_first].to_s.strip.downcase), true)
          name_last_regex = Regexp.compile(Regexp.escape(options[:name_last].to_s.strip.downcase), true)
          found_people = Person.where({"name_first" => name_first_regex, "name_last" => name_last_regex, "emails.email_address" => options[:email]})
          found_person = more_than_one_is_none(found_people)
        end
      end
      
      found_person
    end

    def self.more_than_one_is_none(col)
      col.many? ? nil : col.first
    end
  end
end
