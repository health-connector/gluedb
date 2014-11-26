class ImportApplicationGroups

  class PersonImportListener
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
    def initialize
      @people_map = {}
    end

    def register_person(p_uri, person, member)
      @people_map[p_uri] = [person, member]
    end

    def [](uri)
      @people_map[uri]
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
      ig_requests = ag.individual_requests(member_id_generator)
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
    end
  end
end
