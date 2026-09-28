require 'rails_helper'

describe TradingPartnerTransforms::PackageBuilder, :dbclean => :after_each do

  let(:carrier) { FactoryGirl.create(:carrier, :hbx_carrier_id => "20002", :abbrev => "BCBS") }
  let(:plan) { FactoryGirl.create(:plan, :carrier => carrier, :year => 2026, :coverage_type => "health") }
  let(:policy) { FactoryGirl.create(:shop_policy, :plan => plan, :composite_rating_tier => "urn:openhbx:terms:v1:composite_rating_tier#employee_only").tap { |p| bridge_person_for(p) } }

  # The enrollment_event partial looks up a real Person per enrollee by
  # m_id. FactoryGirl's :policy does not create one, so every policy used
  # to render a real CV needs this bridge, matching the existing pattern
  # in spec/data_migrations/transform_xmls_spec.rb.
  def bridge_person_for(policy)
    # A shop policy needs distinct relationship codes, the cv1 schema
    # rejects two members both marked self.
    policy.enrollees.each_with_index do |en, index|
      en.update_attributes!(:rel_code => "spouse") if index > 0 && en.rel_code == "self"
    end
    policy.enrollees.each do |en|
      person = FactoryGirl.create(:person)
      # :person's default members can coincidentally share an
      # hbx_member_id with this enrollee, since both sequences start
      # at 1. Clear them so authority_member unambiguously resolves
      # to the one member that actually matches this enrollee.
      person.members.destroy_all
      person.members.create!(:hbx_member_id => en.m_id, :gender => "female", :dob => Date.new(1980, 1, 1), :ssn => "123456789")
      person.update_attributes!(:authority_member_id => en.m_id)
    end
    policy.reload
  end

  def entries_for(zip_path)
    entries = {}
    ::Zip::File.open(zip_path) do |zip|
      zip.each { |entry| entries[entry.name] = entry.get_input_stream.read }
    end
    entries
  end

  describe "#build in full mode" do
    subject { described_class.new([policy], "initial") }

    it "produces source xml, x12 and cv1 with no errors" do
      zip_path = subject.build
      begin
        entries = entries_for(zip_path)
        expect(entries.keys).to include("source_xmls/#{policy.eg_id}_initial.xml")
        expect(entries.keys.any? { |k| k.start_with?("transformed_x12s/") }).to be_truthy
        expect(entries.keys.any? { |k| k.start_with?("transformed_cv1s/") }).to be_truthy
        expect(entries).not_to have_key("errors.txt")
        expect(subject.errors).to be_empty
      ensure
        FileUtils.rm_f(zip_path)
      end
    end

    describe "with more than one policy" do
      let(:other_policy) { FactoryGirl.create(:shop_policy, :plan => plan, :composite_rating_tier => "urn:openhbx:terms:v1:composite_rating_tier#employee_only").tap { |p| bridge_person_for(p) } }
      subject { described_class.new([policy, other_policy], "initial") }

      it "produces one source, x12 and cv1 file per policy" do
        zip_path = subject.build
        begin
          entries = entries_for(zip_path)
          expect(entries.keys).to include("source_xmls/#{policy.eg_id}_initial.xml")
          expect(entries.keys).to include("source_xmls/#{other_policy.eg_id}_initial.xml")
          expect(entries.keys.count { |k| k.start_with?("transformed_x12s/") }).to eq 2
          expect(entries.keys.count { |k| k.start_with?("transformed_cv1s/") }).to eq 2
        ensure
          FileUtils.rm_f(zip_path)
        end
      end
    end

    describe "releasing the plan and carrier caches" do
      it "leaves no cache behind for later lookups to accidentally reuse" do
        zip_path = subject.build
        FileUtils.rm_f(zip_path)
        fallback_used = false
        Caches::CustomCache.lookup(Carrier, :cv2_carrier_cache, carrier.id) { fallback_used = true }
        expect(fallback_used).to be_truthy
      end
    end
  end

  describe "#build in source_only mode" do
    subject { described_class.new([policy], "initial", :source_only => true) }

    it "produces only the source xml, skipping x12 and cv1" do
      zip_path = subject.build
      begin
        entries = entries_for(zip_path)
        expect(entries.keys).to eq(["source_xmls/#{policy.eg_id}_initial.xml"])
      ensure
        FileUtils.rm_f(zip_path)
      end
    end
  end

  describe "#build when a policy's carrier is not recognized by the transform pipeline" do
    let(:unrecognized_carrier) { FactoryGirl.create(:carrier) }
    let(:unrecognized_plan) { FactoryGirl.create(:plan, :carrier => unrecognized_carrier, :year => 2026) }
    let(:bad_policy) { FactoryGirl.create(:policy, :plan => unrecognized_plan).tap { |p| bridge_person_for(p) } }
    subject { described_class.new([bad_policy], "initial") }

    it "still writes the source xml, but records a transform error instead of raising" do
      zip_path = subject.build
      begin
        entries = entries_for(zip_path)
        expect(entries.keys).to include("source_xmls/#{bad_policy.eg_id}_initial.xml")
        expect(entries.keys.any? { |k| k.start_with?("transformed_x12s/") }).to be_falsey
        expect(entries["errors.txt"]).to be_present
        expect(subject.errors).not_to be_empty
      ensure
        FileUtils.rm_f(zip_path)
      end
    end
  end

  describe "#build with a mix of a good and a bad policy" do
    let(:unrecognized_carrier) { FactoryGirl.create(:carrier) }
    let(:unrecognized_plan) { FactoryGirl.create(:plan, :carrier => unrecognized_carrier, :year => 2026) }
    let(:bad_policy) { FactoryGirl.create(:policy, :plan => unrecognized_plan).tap { |p| bridge_person_for(p) } }
    subject { described_class.new([policy, bad_policy], "initial") }

    it "transforms the good policy and reports only the bad one in errors" do
      zip_path = subject.build
      begin
        entries = entries_for(zip_path)
        expect(entries.keys).to include("source_xmls/#{policy.eg_id}_initial.xml")
        expect(entries.keys).to include("source_xmls/#{bad_policy.eg_id}_initial.xml")
        expect(entries.keys.count { |k| k.start_with?("transformed_x12s/") }).to eq 1
        expect(entries["errors.txt"]).to include(bad_policy.eg_id)
        expect(entries["errors.txt"]).not_to include(policy.eg_id)
      ensure
        FileUtils.rm_f(zip_path)
      end
    end
  end
end
