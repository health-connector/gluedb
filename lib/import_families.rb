require 'fileutils'
require File.join(Rails.root, 'lib/name_matcher')
require File.join(Rails.root, 'app', 'models', 'person_match_strategies', 'ambiguous_match_error')

class ImportFamilies

  $logger = Logger.new("#{Rails.root}/log/family_#{Time.now.to_s.gsub(' ', '')}.log")
  $error_dir = File.join(Rails.root, "log", "error_xmls_from_curam_#{Time.now.to_s.gsub(' ', '')}")

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
    attr_reader :family_member_map

    def initialize
      @people_map = {}
      @alias_map = {}
      @family_member_map = {}
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
      #puts "\np_uri, person, member #{p_uri}\n"
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

    def register_family_member(person, family_member)
      @family_member_map[person.id] = family_member
    end

    def get_family_member(uri)
      person = self[uri].first
      @family_member_map[person.id]
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
    xml = Nokogiri::XML(File.open(@file_path))

    #puts "Input file:#{@file_path}"

    ags = Parsers::Xml::Cv::FamilyParser.parse(xml.root.canonicalize)

    #puts "Total number of families:#{ags.size}"

    fail_counter = 0

    ags.each do |ag|

      p_tracker = PersonMapper.new

      begin

        #puts "Processing application group e_case_id :#{ag.to_hash[:e_case_id]}"

        ig_requests = ag.individual_requests(member_id_generator, p_tracker)

        ig_requests.each do |ig_request|
          create_or_retain_person = CreateOrRetainPerson.new(ig_request)
          person, member = create_or_retain_person.match

          if person.nil? || member.nil?
            person, member = create_or_retain_person.create
            $logger.info "Created new person and member #{person.id} #{member.id} #{person.name_first} #{person.name_last}"
          end

          p_tracker.register_person(ig_request[:hbx_member_id], person, member)
        end

        family_builder = FamilyBuilder.new(ag.to_hash(p_tracker), p_tracker)

        #applying person objects in person relationships for each family_member.
        ag.family_members.each do |family_member|
          family_member.to_relationships.each do |relationship_hash|
            set_person_relationship(relationship_hash, p_tracker, ag.to_hash[:e_case_id])
          end

          new_family_member = family_builder.add_family_member(family_member.to_hash(p_tracker))
          p_tracker.register_family_member(p_tracker[family_member.id].first, new_family_member)

        end

        family_builder.build

      rescue Exception => e
        fail_counter += 1
        #puts "FAILED e_case_id:#{ag.to_hash[:e_case_id]}"
        $logger.error "ERROR: Family e_case_id:#{ag.to_hash[:e_case_id]}\n" +
                          "message:#{e.message}\n"
        #write_error_file(ag, e.message)
      end
    end

    #puts "Total fails: #{fail_counter}"

  end

  def set_person_relationship(relationship_hash, p_tracker, e_case_id)

    begin
      subject_person_id_uri = "urn:openhbx:hbx:dc0:resources:v1:curam:concern_role##{relationship_hash[:subject_person_id]}"
      object_person_id_uri = "urn:openhbx:hbx:dc0:resources:v1:curam:concern_role##{relationship_hash[:object_person_id]}"

      subject_person = p_tracker[subject_person_id_uri].first
      object_person = p_tracker[object_person_id_uri].first

      #This is a heuristic. If the person was created less than 2 seconds ago, we consider him/her as new person coming from curam
      if (Time.now - subject_person.created_at) < 2.seconds
        relationship = subject_person.person_relationships.build({relative: object_person, kind: relationship_hash[:relationship]})
        relationship.save
      end
    rescue Exception => e
      $logger.error "#{DateTime.now.to_s}" +
                        "WARNING: Family e_case_id:#{e_case_id} could not set relationship\n  " +
                        "message:#{e.message}\n"
    end
  end

  #xml_obj is a happy mapper object
  def write_error_file(xml_obj, error_message)

    begin
      FileUtils.mkdir_p $error_dir

      time_stamp = Time.now.to_i

      xml_path = "#{$error_dir}/#{xml_obj.to_hash[:e_case_id]}_#{time_stamp}.xml"
      error_file_path = "#{$error_dir}/#{xml_obj.to_hash[:e_case_id]}_#{time_stamp}.error"

      File.open(xml_path, "w") do |f|
        f.write(xml_obj.to_xml)
      end

      File.open(error_file_path, "w") do |f|
        f.write(error_message)
      end
    rescue Exception => e
      $logger.error "#{DateTime.now.to_s}" +
                         "write_error_file failed " + "message:#{e.message}\n" +
                         "backtrace:#{e.backtrace.inspect}\n"
    end
  end
end
