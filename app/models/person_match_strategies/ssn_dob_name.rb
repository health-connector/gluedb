module PersonMatchStrategies
    class SsnDobName < FirstLastDob

    def match(options = {})
      return([nil, nil]) if options[:dob].blank? || options[:name_last].blank? || options[:ssn].blank?

      search_dob = cast_dob(options[:dob], options)

      found_people = Person.where("members.dob" => search_dob).and("members.ssn" => options[:ssn]).to_a.select do |person|
        last_name_match?(options[:name_last], person.name_last) ||
            full_name_match?(options[:name_first] + ' ' + options[:name_last], person.name_first + ' ' + person.name_last) ||
            last_name_subset_match?(options[:name_last], person.name_last)
      end

      if found_people.any?
        if found_people.many?
          raise AmbiguousMatchError.new("Multiple people with same ssn, last, and dob: #{options[:ssn]}, #{options[:name_last]}, #{options[:dob]}")
        else
          select_authority_member(found_people.first, options)
        end
      else
        [nil, nil]
      end
    end

    def normalize(text)
      text.strip.downcase.gsub(/[^a-z ]/i, '').gsub(/ (|jr||sr||i||ii||iii||iv||v|)$/,'').gsub(' ','')
    end

    def tokenize(text)
      text.split(/[- ]/)
    end

    def last_name_match?(test_last_name, glue_last_name)
      normalize(test_last_name).eql? normalize(glue_last_name)
    end

    def full_name_match?(test_full_name, glue_full_name)
      normalize(test_full_name).eql? normalize(glue_full_name)
    end

    def last_name_subset_match?(test_last_name, glue_last_name)
        test_set = tokenize(test_last_name.strip.downcase.gsub(/[^a-z]/i, ' ').strip.gsub(/ (|jr||sr||i||ii||iii||iv||v|)$/,'')).to_set
        glue_set = tokenize(glue_last_name.strip.downcase.gsub(/[^a-z]/i, ' ').strip.gsub(/ (|jr||sr||i||ii||iii||iv||v|)$/,'')).to_set

        glue_set.subset?(test_set) || test_set.subset?(glue_set)
    end
  end
end