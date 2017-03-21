require "rails_helper"

describe EnrollmentAction::ActionPublishHelper do
  let(:xml_namespace) { { :cv => "http://openhbx.org/api/terms/1.0" } }
  let(:event_xml) { double }
  let(:event_doc) { double }
  subject { ::EnrollmentAction::ActionPublishHelper.new(event_xml) }

  before :each do
    allow(Nokogiri).to receive(:XML).with(event_xml).and_return(event_doc)
  end

  describe "told to swap premium totals from another event XML" do
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
end
