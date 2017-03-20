require "rails_helper"

describe EnrollmentAction::ActionPublishHelper, "told to swap premium totals from another event XML" do
  let(:xml_namespace) { { :cv => "http://openhbx.org/api/terms/1.0" } }
  let(:event_xml) { double }
  let(:event_doc) { double }
  subject { ::EnrollmentAction::ActionPublishHelper.new(event_xml) }

  before :each do
    allow(Nokogiri).to receive(:XML).with(event_xml).and_return(event_doc)
  end

    let(:premium_total_xpath) {
      "//cv:policy/cv:enrollment/cv:premium_total_amount"
    }
    let(:tot_res_amount_xpath) {
      "//cv:policy/cv:enrollment/cv:total_responsible_amount"
    }

    let(:employer_contribution_xpath) {
      "//cv:policy/cv:enrollment/cv:shop_market/cv:total_employer_responsible_amount"
    }

    let(:ivl_assistance_xpath) {
      "//cv:policy/cv:enrollment/cv:individual_market/cv:applied_aptc_amount"
    }

    let(:source_event_xml) { double }
    let(:source_event_doc) { double }

    let(:other_pre_amt_tot) { double }
    let(:other_tot_res_amt) { double }
    let(:other_emp_res_amt) { double }
    let(:other_ivl_assistance_amount) { double }

    let(:target_xml_premium_total_node) { double }
    let(:source_xml_premium_total_node) { double(:content => other_pre_amt_tot) }
    let(:target_xml_tot_res_amount_node) { double }
    let(:source_xml_tot_res_amount_node) { double(:content => other_tot_res_amt) }
    let(:target_xml_emp_res_node) { double }
    let(:source_xml_emp_res_node) { double(:content => other_emp_res_amt) }
    let(:target_xml_ivl_assistance_node) { double }
    let(:source_xml_ivl_assistance_node) { double(:content => other_ivl_assistance_amount) }

    before :each do
      allow(Nokogiri).to receive(:XML).with(source_event_xml).and_return(source_event_doc)
      allow(event_doc).to receive(:xpath).with(premium_total_xpath, xml_namespace).and_return([target_xml_premium_total_node])
      allow(event_doc).to receive(:xpath).with(tot_res_amount_xpath, xml_namespace).and_return([target_xml_tot_res_amount_node])
      allow(event_doc).to receive(:xpath).with(employer_contribution_xpath, xml_namespace).and_return([target_xml_emp_res_node])
      allow(event_doc).to receive(:xpath).with(ivl_assistance_xpath, xml_namespace).and_return([target_xml_ivl_assistance_node])
      allow(source_event_doc).to receive(:xpath).with(premium_total_xpath, xml_namespace).and_return([source_xml_premium_total_node])
      allow(source_event_doc).to receive(:xpath).with(tot_res_amount_xpath, xml_namespace).and_return([source_xml_tot_res_amount_node])
      allow(source_event_doc).to receive(:xpath).with(employer_contribution_xpath, xml_namespace).and_return([source_xml_emp_res_node])
      allow(source_event_doc).to receive(:xpath).with(ivl_assistance_xpath, xml_namespace).and_return([source_xml_ivl_assistance_node])
      allow(target_xml_premium_total_node).to receive(:content=).with(other_pre_amt_tot)
      allow(target_xml_tot_res_amount_node).to receive(:content=).with(other_tot_res_amt)
      allow(target_xml_emp_res_node).to receive(:content=).with(other_emp_res_amt)
      allow(target_xml_ivl_assistance_node).to receive(:content=).with(other_ivl_assistance_amount)
    end

    it "sets the premium_total_amount correctly" do
      expect(target_xml_premium_total_node).to receive(:content=).with(other_pre_amt_tot)
      subject.replace_premium_totals(source_event_xml)
    end

    it "sets the total_responsible_amount correctly" do
      expect(target_xml_tot_res_amount_node).to receive(:content=).with(other_tot_res_amt)
      subject.replace_premium_totals(source_event_xml)
    end

    it "sets the employer_responsible_amount correctly" do
      expect(target_xml_emp_res_node).to receive(:content=).with(other_emp_res_amt)
      subject.replace_premium_totals(source_event_xml)
    end

    it "sets the ivl assistance amount correctly" do
      expect(target_xml_ivl_assistance_node).to receive(:content=).with(other_ivl_assistance_amount)
      subject.replace_premium_totals(source_event_xml)
    end
end

describe EnrollmentAction::ActionPublishHelper, "told to swap the qualifying event from another event XML" do
  let(:source_event_type) { "urn:dc0:terms:v1:qualifying_life_event#new_eligibility_member" }
  let(:source_event_date) { "20170309" }

  let(:source_event_xml) { <<-EVENTXML
  <enrollment xmlns="http://openhbx.org/api/terms/1.0">
  <policy>
  <eligibility_event>
  <event_kind>#{source_event_type}</event_kind>
  <event_date>#{source_event_date}</event_date>
  </eligibility_event>
  </policy>
  </enrollment>
  EVENTXML
  }
  let(:target_event_xml) { <<-EVENTXML
  <enrollment xmlns="http://openhbx.org/api/terms/1.0">
  <policy>
  <eligibility_event>
  <event_kind>urn:dc0:terms:v1:qualifying_life_event#new_hire</event_kind>
  <event_date>20140201</event_date>
  </eligibility_event>
  </policy>
  </enrollment>
  EVENTXML
  }

  let(:xml_namespace) { { :cv => "http://openhbx.org/api/terms/1.0" } }

  let(:publish_helper) { ::EnrollmentAction::ActionPublishHelper.new(target_event_xml) }

  let(:target_xml_doc) {
    publish_helper.swap_qualifying_event(source_event_xml)
    Nokogiri::XML(publish_helper.to_xml)
  }

  let(:qualifying_event_type_node) {
    target_xml_doc.xpath("//cv:enrollment/cv:policy/cv:eligibility_event/cv:event_kind", xml_namespace).first
  }

  let(:qualifying_event_date_node) {
    target_xml_doc.xpath("//cv:enrollment/cv:policy/cv:eligibility_event/cv:event_date", xml_namespace).first
  }

  it "sets the qualifying event type" do
    expect(qualifying_event_type_node.content).to eq(source_event_type)
  end

  it "sets the qualifying event date" do
    expect(qualifying_event_date_node.content).to eq(source_event_date)
  end
end
