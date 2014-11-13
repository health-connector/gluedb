class UpdatePersonRequest
  def from_cv(payload = nil)
    # payload = File.open(Rails.root.to_s + "/individual_test.xml")
    parser = Nokogiri::XML(payload)
    individual = Parsers::Xml::Reports::Individual.new(parser.root)
    @glue_mapping = Parsers::Xml::Reports::GlueMappings.new

    {
      hbx_member_id: individual.hbx_ids[:id],
      person: serialize_person(individual),
      demographics: map_with_glue(individual.demographics, @glue_mapping.demographics)
    }
  end

  def serialize_person(individual)
    person = individual.person
    person[:id] = individual.person[:id]
    person[:phones] = individual.person[:phones].map { |e| map_with_glue(e, @glue_mapping.phone) }
    person[:addresses] = individual.person[:addresses].map { |e| map_with_glue(e, @glue_mapping.address)  }
    person[:emails] = individual.person[:emails].map { |e| map_with_glue(e, @glue_mapping.email) }
    person
  end

  private

  def map_with_glue(properties, mapping)
    properties.inject({}) do |data, (k, v)|
      key = mapping.has_key?(k) ? mapping[k] : k
      data[key] = v
      data
    end
  end
end
