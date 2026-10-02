module TradingPartnerTransforms
  # Builds the downloadable transform package for a set of policies:
  #   source_xmls/       - enrollment event CVs
  #   transformed_x12s/  - X12 834 payloads
  #   transformed_cv1s/  - CV1 payloads
  #   errors.txt         - per-policy failures (only when any occurred)
  # With source_only, only the source XML is included.
  class PackageBuilder
    include BatchEdiTransform

    SOURCE_DIR = "source_xmls".freeze
    X12_DIR = "transformed_x12s".freeze
    CV1_DIR = "transformed_cv1s".freeze

    attr_reader :errors

    def initialize(policies, reason_code, source_only: false)
      @policies = policies
      @reason_code = reason_code
      @source_only = source_only
      @errors = []
    end

    # Returns the zip path. The caller deletes the file.
    def build
      allocate_caches
      begin
        source_files = generate_source_xmls
        return ZipPackager.build(source_files, @errors) if @source_only

        x12_files = transform_source_files(source_files, EdiCodec::X12::BenefitEnrollment, X12_DIR, @errors)
        cv1_files = transform_source_files(source_files, EdiCodec::Cv1::Cv1Builder, CV1_DIR, @errors)
        ZipPackager.build(source_files + x12_files + cv1_files, @errors)
      ensure
        release_caches
      end
    end

    protected

    def generate_source_xmls
      @policies.inject([]) do |acc, policy|
        begin
          generator = SourceXmlGenerator.new(policy, @reason_code)
          acc << [File.join(SOURCE_DIR, generator.file_name), generator.generate]
        rescue StandardError => e
          @errors << "#{policy.eg_id} - source xml generation failed: #{e.message}"
          acc
        end
      end
    end

    # Carrier and plan caches used when rendering CVs.
    def allocate_caches
      carrier_id_map = {}
      Carrier.all.each do |c|
        carrier_id_map[c.id] = c
      end

      plan_id_map = {}
      active_year_hios_map = {}
      Plan.where(:year => {"$gte" => 2017}).each do |p|
        plan_id_map[p.id] = p
        active_year_hios_map[[p.year, p.hios_plan_id]] = p
      end

      Caches::CustomCache.allocate(Carrier, :cv2_carrier_cache, carrier_id_map)
      Caches::CustomCache.allocate(Plan, :cv2_plan_cache, plan_id_map)
      Caches::CustomCache.allocate(Plan, :cv2_hios_active_year_plan_cache, active_year_hios_map)
    end

    def release_caches
      Caches::CustomCache.release(Carrier, :cv2_carrier_cache)
      Caches::CustomCache.release(Plan, :cv2_plan_cache)
      Caches::CustomCache.release(Plan, :cv2_hios_active_year_plan_cache)
    end
  end
end
