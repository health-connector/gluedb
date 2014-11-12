class UpdatePersonRequest
  def from_cv(payload = nil)
    # payload = File.open(Rails.root.to_s + "/individual_test.xml")
    parser = Nokogiri::XML(payload)
    individual = Parsers::Xml::Reports::Individual.new(parser.root)
    @mapping = Parsers::Xml::Reports::GlueMappings.new

    request = {
      member_id: strip_uri(individual.member_ids.id),
      person: serialize_person(individual),
      demographics: serialize_demographics(individual)
    }
        
    request
  end

  def serialize_person(individual)
    person_name = individual.person[:person_name]
    person = {
      name_pfx: person_name.person_name_prefix_text,
      name_first: person_name.person_given_name,
      name_middle: person_name.person_middle_name,
      name_last: person_name.person_surname,
      name_sfx: person_name.person_name_suffix_text,
      name_full: person_name.person_full_name,
      alternate_name: person_name.person_alternate_name
    }

    person[:phones] = individual.person[:phones].map { |e| e.marshal_dump }
    person[:addresses] = individual.person[:addresses].map { |e| map_with_glue(e.marshal_dump)  }
    person[:emails] = individual.person[:emails].map { |e| e.marshal_dump }
    person[:relationships] = individual.relationships.map { |e| e.marshal_dump  }

    person[:id] = strip_uri(individual.person[:id].id)
    person
  end

  def map_with_glue(properties)
    glue_properties = {}
    properties.each do |k, v|
      glue_properties[@mapping.individual[k]] = v
    end
    glue_properties
  end

  def serialize_demographics(individual)
    {
      ssn: individual.demographics.ssn,
      gender: strip_uri(individual.demographics.sex),
      dob: individual.demographics.birth_date,
      ethnicity: individual.demographics.ethnicity,
      race: individual.demographics.race,
      birth_location: individual.demographics.birth_location,
      citizen_status: strip_uri(individual.demographics.citizen_status),
      is_state_resident: individual.demographics.is_state_resident,
      is_incarcerated: individual.demographics.is_incarcerated
    }
  end

  private

  def strip_uri(text)
    text.split('#')[1]
  end
end
