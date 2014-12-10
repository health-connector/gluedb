class ImportApplicationGroups

  @@logger = Logger.new("#{Rails.root}/log/soap.log")

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
      @alias_map.each_pair do |k,v|
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
      @people_map.each_pair do |k,v|
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

    ags = Parsers::Xml::Cv::ApplicationGroup.parse(xml.root.canonicalize)
    puts "PARSING DONE"
    ags.each do |ag|

      application_group_builder = ApplicationGroupBuilder.new(ag.to_hash, p_tracker)
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

          #new_applicant = Applicant.new(applicant.to_hash)
          #new_applicant.person = subject_person
          #new_applicant.person_id = subject_person.id
          #application_group_builder.add_applicant(new_applicant)
        end

        #new_applicant = Applicant.new(applicant.to_hash(p_tracker))
        new_applicant = application_group_builder.add_applicant(applicant.to_hash(p_tracker))
        p_tracker.register_applicant(p_tracker[applicant.id].first, new_applicant)

      end

      #application_group_builder.add_irsgroups(ag.irs_groups)
      application_group_builder.add_tax_households(ag.to_hash[:tax_households], ag.to_hash[:eligibility_determinations])
      application_group_builder.application_group.save!

      applicants_params = ag.applicants.map do |applicant|
        applicant.to_hash(p_tracker)
      end
      application_group_builder.add_financial_statements(applicants_params)
      begin
        application_group_builder.application_group.save!
      rescue Exception=>e
        puts e.message
        puts e.backtrace.inspect
      end

      puts "We saved #{application_group_builder.application_group.id}"
=begin
      puts "\n\n #{application_group_builder.application_group.inspect}"
      puts "\n\n #{application_group_builder.application_group.households.flat_map(&:tax_households).inspect}"
      puts "\n\n #{application_group_builder.application_group.households.flat_map(&:tax_households).flat_map(&:tax_household_members).inspect}"
      puts "\n\n #{application_group_builder.application_group.households.flat_map(&:tax_households).flat_map(&:tax_household_members).flat_map(&:financial_statements).inspect}"
      puts "\n\n #{application_group_builder.application_group.households.flat_map(&:tax_households).flat_map(&:tax_household_members).flat_map(&:financial_statements).flat_map(&:incomes).inspect}"
      puts "\n\n #{application_group_builder.application_group.households.flat_map(&:tax_households).flat_map(&:tax_household_members).flat_map(&:financial_statements).flat_map(&:deductions).inspect}"
=end

    end


  end
end
