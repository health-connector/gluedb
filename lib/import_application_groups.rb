class ImportApplicationGroups

  class PersonImportListener

    attr_reader :errors

    def initialize(person_id, person_tracker)
      @person_id = person_id
      @errors = {}
      @registered_people = {}
      @person_tracker = person_tracker
    end

    def success
    end

    def fail
    end

    def invalid_person(details)
      details.each_pair do |k, v|
        add_person_error(k, v)
      end
    end

    def invalid_member(details)
      details.each_pair do |k, v|
        add_person_error(k, v)
      end
    end

    def person_match_error(error_message)
      add_person_error(:person_match_failure, error_message)
    end

    def add_person_error(property, message)
      @errors[:individuals] ||= {}
      @errors[:individuals][property] ||= []
      @errors[:individuals][property] = @errors[:individuals][property] + [message]
    end

    def register_person(member_id, person, member)
      @person_tracker.register_person(@person_id, person, member)
    end
  end

  class PersonMapper

    attr_reader :people_map
    attr_reader :alias_map

    def initialize
      @people_map = {}
      @alias_map = {}
    end

    def register_alias(alias_uri, p_uri)
      @alias_map[alias_uri] = p_uri
    end

    def register_person(p_uri, person, member)
      register_alias(p_uri, p_uri)
      @people_map[p_uri] = [person, member]
    end

    def [](uri)
      p_uri = @alias_map[uri]
      @people_map[p_uri]
    end
  end

  class MemberIdGen
    def initialize(starting_id)
      @next_id = starting_id
    end

    def generate_member_id
      @next_id = @next_id + 1
      (@next_id - 1).to_s
    end
  end

  def initialize(f_path)
    @file_path = f_path
  end

  def run
    member_id_generator = MemberIdGen.new(20000000)
    p_tracker = PersonMapper.new
    xml = Nokogiri::XML(File.open(@file_path))
    puts "PARSING START"

    ags = Parsers::Xml::Cv::ApplicationGroup.parse(xml.root.canonicalize)
    puts "PARSING DONE"
    ags.each do |ag|

      application_group_builder = ApplicationGroupBuilder.new(ag.to_hash)
      ig_requests = ag.individual_requests(member_id_generator, p_tracker)
      uc = CreateOrUpdatePerson.new
      all_valid = ig_requests.all? do |ig_request|
          listener = PersonImportListener.new(ig_request[:applicant_id], p_tracker)
          uc.validate(ig_request, listener)
      end
      next unless all_valid
      ig_requests.each do |ig_request|
          listener = PersonImportListener.new(ig_request[:applicant_id], p_tracker)
          uc.commit(ig_request, listener)
      end

      #applying person objects in person relationships for each applicant.
      ag.applicants.each do |applicant|

        applicant.to_relationships.each do |relationship_hash|

          subject_person_id_uri = "urn:openhbx:hbx:dc0:resources:v1:curam:concern_role##{relationship_hash[:subject_person_id]}"
          object_person_id_uri = "urn:openhbx:hbx:dc0:resources:v1:curam:concern_role##{relationship_hash[:object_person_id]}"
          subject_person = p_tracker[subject_person_id_uri].first

          person_relationship = PersonRelationship.new
          person_relationship.relative = p_tracker[object_person_id_uri].first
          person_relationship.kind = relationship_hash[:relationship]

          subject_person.merge_relationship(person_relationship)

          new_applicant = Applicant.new(applicant.to_hash)
          new_applicant.person = subject_person
          new_applicant.person_id = subject_person.id
          application_group_builder.add_applicant(new_applicant)
        end

        #application_group_builder.add_irsgroups(ag.irs_groups)
        application_group_builder.add_tax_households(ag.to_hash[:tax_households])
        application_group_builder.application_group.save!

        application_group_builder.application_group.households.each do |household|
          household.tax_households.each do |tax_household|
            puts tax_household.inspect
          end
        end
      end
    end


  end
end
