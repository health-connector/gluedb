class ImportApplicationGroups

  @@logger = Logger.new("#{Rails.root}/log/import_application_groups.log")

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
    attr_reader :applicant_map

    def initialize
      @people_map = {}
      @alias_map = {}
      @applicant_map = {}
    end

    def register_alias(alias_uri, p_uri)
      @alias_map.each_pair do |k, v|
        if (p_uri == k) && (p_uri != v)
          @alias_map[alias_uri] = v
          return
        end
      end
      @alias_map[alias_uri] = p_uri
    end

    def register_person(p_uri, person, member)
      existing_record = nil
      existing_key = nil
      @people_map.each_pair do |k, v|
        existing_person = v.first
        if person.id == existing_person.id
          register_alias(p_uri, k)
          return
        end
      end
      register_alias(p_uri, p_uri)
      @people_map[p_uri] = [person, member]
    end

    def [](uri)
      p_uri = @alias_map[uri]
      @people_map[p_uri]
    end

    def register_applicant(person, applicant)
      @applicant_map[person.id] = applicant
    end

    def get_applicant(uri)
      person = self[uri].first
      @applicant_map[person.id]
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

    ags = Parsers::Xml::Cv::FamilyParser.parse(xml.root.canonicalize)
    puts "PARSING DONE"
    puts "Total number of application groups :#{ags.size}"
    fail_counter = 0
    ags.each do |ag|

      begin

      puts "Processing application group e_case_id :#{ag.to_hash[:e_case_id]}"

      ig_requests = ag.individual_requests(member_id_generator, p_tracker)
      uc = CreateOrUpdatePerson.new
      all_valid = ig_requests.all? do |ig_request|
        listener = PersonImportListener.new(ig_request[:applicant_id], p_tracker)
        value = uc.validate(ig_request, listener)
      end

      @@logger.info "#{DateTime.now.to_s}" + "Family e_case_id:#{application_group_builder.family.e_case_id}" + "message:'CreateOrUpdatePerson did not succees for all'" unless all_valid

      ig_requests.each do |ig_request|
        listener = PersonImportListener.new(ig_request[:applicant_id], p_tracker)
        value = uc.commit(ig_request, listener)
      end

      application_group_builder = ApplicationGroupBuilder.new(ag.to_hash(p_tracker), p_tracker)

      #applying person objects in person relationships for each applicant.
      ag.family_members.each do |applicant|

        applicant.to_relationships.each do |relationship_hash|

          subject_person_id_uri = "urn:openhbx:hbx:dc0:resources:v1:curam:concern_role##{relationship_hash[:subject_person_id]}"
          object_person_id_uri = "urn:openhbx:hbx:dc0:resources:v1:curam:concern_role##{relationship_hash[:object_person_id]}"
          subject_person = p_tracker[subject_person_id_uri].first

          person_relationship = PersonRelationship.new
          person_relationship.relative = p_tracker[object_person_id_uri].first
          person_relationship.kind = relationship_hash[:relationship]

          subject_person.merge_relationship(person_relationship)
        end

        new_applicant = application_group_builder.add_applicant(applicant.to_hash(p_tracker))
        p_tracker.register_applicant(p_tracker[applicant.id].first, new_applicant)

      end


        #application_group_builder.add_irsgroups(ag.irs_groups)

        application_group_builder.add_tax_households(ag.to_hash[:tax_households])

        applicants_params = ag.family_members.map do |applicant|
          applicant.to_hash(p_tracker)
        end

        application_group_builder.add_financial_statements(applicants_params)
        application_group_builder.add_hbx_enrollment
        application_group_builder.add_coverage_household

        application_group_id = application_group_builder.save

        application_group_builder.add_irsgroups

        puts "Saved #{application_group_id}"

      rescue Exception => e
        fail_counter += 1
        puts "FAILED e_case_id:#{ag.to_hash[:e_case_id]}"

        @@logger.info "#{DateTime.now.to_s}" +
                          "Family e_case_id:#{ag.to_hash[:e_case_id]}\n" +
                          "message:#{e.message}\n" +
                          "backtrace:#{e.backtrace.inspect}\n"
      end
    end

    puts "Total fails: #{fail_counter}"

  end
end
