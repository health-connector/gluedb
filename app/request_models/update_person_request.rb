class UpdatePersonRequest
  def self.from_xml(payload = nil)
    individual = Parsers::Xml::Reports::Individual.new(payload)
    @glue_mapping = Parsers::Xml::Reports::GlueMappings.new

    {
      hbx_member_id: individual.hbx_ids[:id],
      person: serialize_person(individual),
      demographics: map_with_glue(individual.demographics, @glue_mapping.demographics)
    }
  end

  private

  def self.serialize_person(individual)
    person = individual.person
    person[:id] = individual.person[:id]
    person[:phones] = person[:phones].map{|e| map_with_glue(e, @glue_mapping.phone)} if person[:phones]
    person[:addresses] = person[:addresses].map{|e| map_with_glue(e, @glue_mapping.address)} if person[:addresses]
    person[:emails] = person[:emails].map{|e| map_with_glue(e, @glue_mapping.email)} if person[:emails]
    person
  end

  def self.map_with_glue(properties, mapping)
    properties.inject({}) do |data, (k, v)|
      key = mapping.has_key?(k) ? mapping[k] : k
      data[key] = v
      data
    end
  end
end
