class UpdatePersonRequest
  def from_cv(payload = nil)
    # payload = File.open(Rails.root.to_s + "/individual_test.xml")
    parser = Nokogiri::XML(payload)
    individual = Parsers::Xml::Reports::Individual.new(parser.root)
    @glue_mapping = Parsers::Xml::Reports::GlueMappings.new

    request = {
      hbx_member_id: individual.member_ids.id,
      person: serialize_person(individual),
      demographics: map_with_glue(individual.demographics, @glue_mapping.demographics)
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

    person[:phones] = individual.person[:phones].map { |e| map_with_glue(e.marshal_dump, @glue_mapping.phone) }
    person[:addresses] = individual.person[:addresses].map { |e| map_with_glue(e.marshal_dump, @glue_mapping.address)  }
    person[:emails] = individual.person[:emails].map { |e| map_with_glue(e.marshal_dump, @glue_mapping.email) }
    person[:relationships] = individual.relationships.map { |e| e.marshal_dump  }

    person[:id] = individual.person[:id].id
    person
  end

  def map_with_glue(properties, mapping)
    properties.inject({}) do |data, (k, v)|
      data[mapping[k]] = v
      data
    end
  end
end
