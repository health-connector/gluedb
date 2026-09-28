require 'rails_helper'

describe TradingPartnerTransformsController, :dbclean => :after_each do
  login_user

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

  def zip_entries(body)
    tmp = Tempfile.new("controller_spec_zip")
    tmp.binmode
    tmp.write(body)
    tmp.close
    entries = {}
    ::Zip::File.open(tmp.path) do |zip|
      zip.each { |entry| entries[entry.name] = entry.get_input_stream.read }
    end
    entries
  ensure
    FileUtils.rm_f(tmp.path) if tmp
  end

  def uploaded_file(filename, content, content_type = "text/xml")
    tempfile = Tempfile.new(["upload", File.extname(filename)])
    tempfile.binmode
    tempfile.write(content)
    tempfile.rewind
    ActionDispatch::Http::UploadedFile.new(:tempfile => tempfile, :filename => filename, :type => content_type)
  end

  describe "GET new" do
    it "assigns a blank transform_request when no eg_ids are given" do
      get :new
      expect(assigns(:transform_request).eg_ids).to be_nil
      expect(response).to render_template :new
    end

    it "pre-fills eg_ids from the query param" do
      get :new, :eg_ids => "100001,100002"
      expect(assigns(:transform_request).eg_ids).to eq "100001,100002"
    end
  end

  describe "POST create (Generate and Download)" do
    describe "with valid params" do
      before { post :create, :trading_partner_transform_request => { :eg_ids => policy.eg_id, :reason_code => "initial" } }

      it "downloads a zip named after the reason code" do
        expect(response.headers["Content-Disposition"]).to include "initial_transform_xmls.zip"
      end

      it "contains source xml, x12 and cv1" do
        entries = zip_entries(response.body)
        expect(entries.keys).to include("source_xmls/#{policy.eg_id}_initial.xml")
        expect(entries.keys.any? { |k| k.start_with?("transformed_x12s/") }).to be_truthy
        expect(entries.keys.any? { |k| k.start_with?("transformed_cv1s/") }).to be_truthy
      end

      it "does not change the policy" do
        original_state = policy.aasm_state
        expect(policy.reload.aasm_state).to eq original_state
      end
    end

    describe "with a ticket number" do
      before { post :create, :trading_partner_transform_request => { :ticket_number => "CCAOM-297", :eg_ids => policy.eg_id, :reason_code => "initial" } }

      it "prefixes the zip name with the ticket" do
        expect(response.headers["Content-Disposition"]).to include "CCAOM-297_initial_transform_xmls.zip"
      end
    end

    describe "with a cancel reason code" do
      before { post :create, :trading_partner_transform_request => { :eg_ids => policy.eg_id, :reason_code => "cancel" } }

      it "names the zip cancel while still running the terminate pipeline underneath" do
        expect(response.headers["Content-Disposition"]).to include "cancel_transform_xmls.zip"
      end
    end

    describe "with blank eg_ids" do
      before { post :create, :trading_partner_transform_request => { :eg_ids => "", :reason_code => "initial" } }

      it "redirects back to new with an error and produces no zip" do
        expect(response).to be_redirect
        expect(flash[:error]).to be_present
        expect(response.headers["Content-Disposition"]).to be_nil
      end
    end

    describe "with eg_ids that do not resolve to any policy" do
      before { post :create, :trading_partner_transform_request => { :eg_ids => "bogus_eg_id", :reason_code => "initial" } }

      it "redirects with a message naming the missing eg_id" do
        expect(flash[:error]).to include("bogus_eg_id")
      end
    end

    describe "with an invalid reason code" do
      before { post :create, :trading_partner_transform_request => { :eg_ids => policy.eg_id, :reason_code => "bogus_reason" } }

      it "redirects with a message about the reason code" do
        expect(flash[:error]).to include("reason code")
      end
    end
  end

  describe "POST generate_source_only" do
    describe "with valid params" do
      before { post :generate_source_only, :trading_partner_transform_request => { :eg_ids => policy.eg_id, :reason_code => "initial" } }

      it "downloads a zip named after the reason code with the source only suffix" do
        expect(response.headers["Content-Disposition"]).to include "initial_source_xml.zip"
      end

      it "contains only the source xml, no x12 or cv1" do
        entries = zip_entries(response.body)
        expect(entries.keys).to eq(["source_xmls/#{policy.eg_id}_initial.xml"])
      end
    end

    describe "with invalid params" do
      before { post :generate_source_only, :trading_partner_transform_request => { :eg_ids => "", :reason_code => "initial" } }

      it "redirects with an error" do
        expect(response).to be_redirect
        expect(flash[:error]).to be_present
      end
    end
  end

  describe "POST transform_uploaded_xmls" do
    let(:real_xml) { TradingPartnerTransforms::SourceXmlGenerator.new(policy, "initial").generate }

    describe "with one valid xml file and no ticket number" do
      before { post :transform_uploaded_xmls, :source_xml_files => [uploaded_file("dep_add_source.xml", real_xml)] }

      it "names the zip after the uploaded file" do
        expect(response.headers["Content-Disposition"]).to include "dep_add_source_transform_xmls.zip"
      end

      it "contains the echoed source xml plus x12 and cv1" do
        entries = zip_entries(response.body)
        expect(entries.keys).to include("source_xmls/dep_add_source.xml")
        expect(entries.keys.any? { |k| k.start_with?("transformed_x12s/") }).to be_truthy
        expect(entries.keys.any? { |k| k.start_with?("transformed_cv1s/") }).to be_truthy
      end
    end

    describe "with a ticket number" do
      before do
        post :transform_uploaded_xmls,
             :trading_partner_transform_request => { :ticket_number => "CCAOM-500" },
             :source_xml_files => [uploaded_file("dep_add_source.xml", real_xml)]
      end

      it "names the zip after the ticket instead of the file" do
        expect(response.headers["Content-Disposition"]).to include "CCAOM-500_transform_xmls.zip"
      end
    end

    describe "with multiple files and no ticket number" do
      let(:other_policy) { FactoryGirl.create(:shop_policy, :plan => plan, :composite_rating_tier => "urn:openhbx:terms:v1:composite_rating_tier#employee_only").tap { |p| bridge_person_for(p) } }
      let(:other_xml) { TradingPartnerTransforms::SourceXmlGenerator.new(other_policy, "initial").generate }

      before do
        post :transform_uploaded_xmls, :source_xml_files => [uploaded_file("a.xml", real_xml), uploaded_file("b.xml", other_xml)]
      end

      it "falls back to a generic zip name" do
        expect(response.headers["Content-Disposition"]).to include "uploaded_source_xml_transforms.zip"
      end

      it "transforms every uploaded file" do
        entries = zip_entries(response.body)
        expect(entries.keys.count { |k| k.start_with?("transformed_x12s/") }).to eq 2
      end
    end

    describe "with no files chosen" do
      before { post :transform_uploaded_xmls }

      it "redirects with an error asking for a file" do
        expect(response).to be_redirect
        expect(flash[:error]).to include("Choose one or more")
      end
    end

    describe "with a non xml file mixed in" do
      before do
        post :transform_uploaded_xmls, :source_xml_files => [uploaded_file("dep_add_source.xml", real_xml), uploaded_file("notes.txt", "hello", "text/plain")]
      end

      it "redirects with an error naming the rejected file" do
        expect(response).to be_redirect
        expect(flash[:error]).to include("notes.txt")
      end
    end
  end

  describe "POST apply_data_changes" do
    describe "not yet confirmed" do
      before do
        policy.update_attributes!(:cobra_eligibility_date => Date.new(2026, 1, 1))
        post :apply_data_changes, :trading_partner_transform_request => { :eg_ids => policy.eg_id, :end_date_action => "remove_cobra" }
      end

      it "renders the confirmation screen" do
        expect(response).to render_template :confirm
      end

      it "does not change the policy yet" do
        expect(policy.reload.cobra_eligibility_date).to eq Date.new(2026, 1, 1)
      end
    end

    describe "confirmed, remove_cobra" do
      before do
        policy.update_attributes!(:cobra_eligibility_date => Date.new(2026, 1, 1))
        post :apply_data_changes, :confirmed => "true", :trading_partner_transform_request => { :eg_ids => policy.eg_id, :end_date_action => "remove_cobra" }
      end

      it "applies the change" do
        expect(policy.reload.cobra_eligibility_date).to be_nil
      end

      it "redirects back to new with eg_ids preserved and a success flash" do
        expect(response).to redirect_to new_trading_partner_transform_path(:eg_ids => policy.eg_id)
        expect(flash[:success]).to be_present
      end
    end

    describe "confirmed, change / terminate" do
      let(:end_date) { policy.policy_start + 2.months }

      before do
        post :apply_data_changes, :confirmed => "true", :trading_partner_transform_request => {
          :eg_ids => policy.eg_id, :end_date_action => "change", :change_mode => "terminate", :end_date => end_date.strftime('%m/%d/%Y')
        }
      end

      it "terminates the policy with the entered end date" do
        policy.reload
        expect(policy.aasm_state).to eq "terminated"
        expect(policy.enrollees.map(&:coverage_end).uniq).to eq [end_date]
      end
    end

    describe "confirmed, change / cancel" do
      before do
        post :apply_data_changes, :confirmed => "true", :trading_partner_transform_request => {
          :eg_ids => policy.eg_id, :end_date_action => "change", :change_mode => "cancel"
        }
      end

      it "cancels the policy using its own start date" do
        policy.reload
        expect(policy.aasm_state).to eq "canceled"
        expect(policy.enrollees.map(&:coverage_end).uniq).to eq [policy.policy_start]
      end
    end

    describe "confirmed, remove" do
      let(:policy) { FactoryGirl.create(:terminated_policy) }

      before do
        post :apply_data_changes, :confirmed => "true", :trading_partner_transform_request => {
          :eg_ids => policy.eg_id, :end_date_action => "remove", :aasm_state => "resubmitted", :benefit_status => "cobra"
        }
      end

      it "restores the requested state and benefit status" do
        policy.reload
        expect(policy.aasm_state).to eq "resubmitted"
        expect(policy.enrollees.map(&:ben_stat).uniq).to eq ["cobra"]
      end
    end

    describe "with invalid params" do
      before do
        post :apply_data_changes, :trading_partner_transform_request => { :eg_ids => policy.eg_id, :end_date_action => "remove", :aasm_state => "bogus_state" }
      end

      it "redirects with an error and does not touch the policy" do
        original_state = policy.aasm_state
        expect(response).to be_redirect
        expect(flash[:error]).to be_present
        expect(policy.reload.aasm_state).to eq original_state
      end
    end

    describe "with none selected" do
      before { post :apply_data_changes, :trading_partner_transform_request => { :eg_ids => policy.eg_id, :end_date_action => "none" } }

      it "redirects with an error asking for an action" do
        expect(flash[:error]).to include("selected")
      end
    end
  end

  describe "as an unauthorized role" do
    before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      user = FactoryGirl.create(:user, :role => "user")
      sign_in user
      bypass_rescue
    end

    it "denies access to new" do
      expect { get :new }.to raise_error(CanCan::AccessDenied)
    end

    it "denies access to create" do
      expect do
        post :create, :trading_partner_transform_request => { :eg_ids => policy.eg_id, :reason_code => "initial" }
      end.to raise_error(CanCan::AccessDenied)
    end

    it "denies access to generate_source_only" do
      expect do
        post :generate_source_only, :trading_partner_transform_request => { :eg_ids => policy.eg_id, :reason_code => "initial" }
      end.to raise_error(CanCan::AccessDenied)
    end

    it "denies access to transform_uploaded_xmls" do
      expect { post :transform_uploaded_xmls }.to raise_error(CanCan::AccessDenied)
    end

    it "denies access to apply_data_changes" do
      expect do
        post :apply_data_changes, :trading_partner_transform_request => { :eg_ids => policy.eg_id, :end_date_action => "remove_cobra" }
      end.to raise_error(CanCan::AccessDenied)
    end
  end
end
