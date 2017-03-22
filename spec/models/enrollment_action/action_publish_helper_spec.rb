require "rails_helper"

describe EnrollmentAction::ActionPublishHelper, "told to swap premium totals from another event XML" do
  let(:xml_namespace) { { :cv => "http://openhbx.org/api/terms/1.0" } }
  let(:source_premium_total) { "56.78" }
  let(:source_tot_res_amt) { "123.45" }
  let(:source_emp_res_amt) { "98.76" }
  let(:source_ivl_assistance_amount) { "34.21" }

  let(:source_event_xml) { <<-EVENTXML
  <enrollment xmlns="http://openhbx.org/api/terms/1.0">
  <policy>
  <enrollment>
  <individual_market>
    <applied_aptc_amount>#{source_ivl_assistance_amount}</applied_aptc_amount>
  </individual_market>
  <shop_market>
    <total_employer_responsible_amount>#{source_emp_res_amt}</total_employer_responsible_amount>
  </shop_market>
  <premium_total_amount>#{source_premium_total}</premium_total_amount>
  <total_responsible_amount>#{source_tot_res_amt}</total_responsible_amount>
  </enrollment>
  </policy>
  </enrollment>
  EVENTXML
  }
  let(:target_event_xml) { <<-EVENTXML
  <enrollment xmlns="http://openhbx.org/api/terms/1.0">
  <policy>
  <enrollment>
  <individual_market>
    <applied_aptc_amount>0.00</applied_aptc_amount>
  </individual_market>
  <shop_market>
    <total_employer_responsible_amount>0.00</total_employer_responsible_amount>
  </shop_market>
  <premium_total_amount>0.00</premium_total_amount>
  <total_responsible_amount>0.00</total_responsible_amount>
  </enrollment>
  </policy>
  </enrollment>
  EVENTXML
  }

  let(:action_publish_helper) { ::EnrollmentAction::ActionPublishHelper.new(target_event_xml) }

  let(:transformed_target_xml) {
    action_publish_helper.replace_premium_totals(source_event_xml)
    Nokogiri::XML(action_publish_helper.to_xml)
  }

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

    let(:target_xml_premium_total_node) { transformed_target_xml.xpath(premium_total_xpath, xml_namespace).first }
    let(:target_xml_tot_res_amount_node) { transformed_target_xml.xpath(tot_res_amount_xpath, xml_namespace).first }
    let(:target_xml_emp_res_node) { transformed_target_xml.xpath(employer_contribution_xpath, xml_namespace).first }
    let(:target_xml_ivl_assistance_node) { transformed_target_xml.xpath(ivl_assistance_xpath, xml_namespace).first }

    it "sets the premium_total_amount correctly" do
      expect(target_xml_premium_total_node.content).to eql(source_premium_total)
    end

    it "sets the total_responsible_amount correctly" do
      expect(target_xml_tot_res_amount_node.content).to eq(source_tot_res_amt)
    end

    it "sets the employer_responsible_amount correctly" do
      expect(target_xml_emp_res_node.content).to eq(source_emp_res_amt)
    end

    it "sets the ivl assistance amount correctly" do
      expect(target_xml_ivl_assistance_node.content).to eq(source_ivl_assistance_amount)
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

describe EnrollmentAction::ActionPublishHelper, "SHOP: recalculating premium totals after a dependent drop" do
  let(:primary_member_id) { "1000" }
  let(:secondary_member_id) { "1001" }
  let(:dropped_member_id) { "1002" }
  let(:xml_namespace) { { :cv => "http://openhbx.org/api/terms/1.0" } }
  let(:premium_amount) { '100.00' }
  let(:total_employer_responsible_amount) { '185.00' }
  let(:dependent_drop_event) { <<-EVENTXML
    <enrollment xmlns="http://openhbx.org/api/terms/1.0">
      <policy>
        <enrollees>
          <enrollee>
            <member>
              <id>
                <id>urn:openhbx:hbx:dc0:resources:v1:person:hbx_id##{primary_member_id}</id>
              </id>
            </member>
            <benefit>
              <premium_amount>#{premium_amount}</premium_amount>
            </benefit>
          </enrollee>
          <enrollee>
            <member>
              <id>
                <id>urn:openhbx:hbx:dc0:resources:v1:person:hbx_id##{secondary_member_id}</id>
              </id>
            </member>
            <benefit>
              <premium_amount>#{premium_amount}</premium_amount>
            </benefit>
          </enrollee>
          <enrollee>
            <member>
              <id>
                <id>urn:openhbx:hbx:dc0:resources:v1:person:hbx_id##{dropped_member_id}</id>
              </id>
            </member>
            <benefit>
              <premium_amount>#{premium_amount}</premium_amount>
            </benefit>
          </enrollee>
        </enrollees>
      <enrollment>
        <shop_market>
          <total_employer_responsible_amount>#{total_employer_responsible_amount}</total_employer_responsible_amount>
        </shop_market>
        <premium_total_amount>300.00</premium_total_amount>
        <total_responsible_amount>125.00</total_responsible_amount>
      </enrollment>
    </policy>
  </enrollment>
  EVENTXML
  }

  let(:publish_helper) { ::EnrollmentAction::ActionPublishHelper.new(dependent_drop_event) }

  let(:target_xml_doc) {
    publish_helper.recalculate_premium_totals_excluding_dropped_dependents([primary_member_id, secondary_member_id])
    Nokogiri::XML(publish_helper.to_xml)
  }

  let(:premium_total_xpath) { target_xml_doc.xpath("//cv:enrollment/cv:policy/cv:enrollment/cv:premium_total_amount", xml_namespace).first }
  let(:total_responsible_amount_xpath) { target_xml_doc.xpath("//cv:enrollment/cv:policy/cv:enrollment/cv:total_responsible_amount", xml_namespace).first }
  let(:total_employer_responsible_amount_xpath) { target_xml_doc.xpath("//cv:enrollment/cv:policy/cv:enrollment/cv:shop_market/cv:total_employer_responsible_amount", xml_namespace).first }

  it "recalculates the correct total excluding the dropped member" do
    expect(premium_total_xpath.content).to eq("200.0")
  end

  it "recalculates the correct total_responsible_amount" do
    expect(total_responsible_amount_xpath.content).to eq("15.0")
  end

  it "leaves the total employer responsible amount unchanged" do
    expect(total_employer_responsible_amount_xpath.content).to eq("185.00")
  end

  context "with an original employer contribution greater than the adjusted total" do
    let(:total_employer_responsible_amount) { '250.00' }
    it "recalculates the contribution to be no greater than the total premium" do
      expect(total_employer_responsible_amount_xpath.content).to eq("200.0")
    end
    it "sets the correct total_responsible_amount value" do
      expect(total_responsible_amount_xpath.content).to eq('0.0')
    end
  end
end

describe EnrollmentAction::ActionPublishHelper, "IVL: recalculating premium totals after a dependent drop" do
  let(:primary_member_id) { "1000" }
  let(:secondary_member_id) { "1001" }
  let(:dropped_member_id) { "1002" }
  let(:xml_namespace) { { :cv => "http://openhbx.org/api/terms/1.0" } }
  let(:premium_amount) { '100.00' }
  let(:applied_aptc_amount) { '150.00' }

  let(:dependent_drop_event) { <<-EVENTXML
    <enrollment xmlns="http://openhbx.org/api/terms/1.0">
      <policy>
        <enrollees>
          <enrollee>
            <member>
              <id>
                <id>urn:openhbx:hbx:dc0:resources:v1:person:hbx_id##{primary_member_id}</id>
              </id>
            </member>
            <benefit>
              <premium_amount>#{premium_amount}</premium_amount>
            </benefit>
          </enrollee>
          <enrollee>
            <member>
              <id>
                <id>urn:openhbx:hbx:dc0:resources:v1:person:hbx_id##{secondary_member_id}</id>
              </id>
            </member>
            <benefit>
              <premium_amount>#{premium_amount}</premium_amount>
            </benefit>
          </enrollee>
          <enrollee>
            <member>
              <id>
                <id>urn:openhbx:hbx:dc0:resources:v1:person:hbx_id##{dropped_member_id}</id>
              </id>
            </member>
            <benefit>
              <premium_amount>#{premium_amount}</premium_amount>
            </benefit>
          </enrollee>
        </enrollees>
      <enrollment>
        <individual_market>
          <is_carrier_to_bill>true</is_carrier_to_bill>
          <applied_aptc_amount>#{applied_aptc_amount}</applied_aptc_amount>
        </individual_market>
        <premium_total_amount>300.00</premium_total_amount>
        <total_responsible_amount>150.00</total_responsible_amount>
      </enrollment>
    </policy>
  </enrollment>
  EVENTXML
  }

  let(:publish_helper) { ::EnrollmentAction::ActionPublishHelper.new(dependent_drop_event) }

  let(:target_xml_doc) {
    publish_helper.recalculate_premium_totals_excluding_dropped_dependents([primary_member_id, secondary_member_id])
    Nokogiri::XML(publish_helper.to_xml)
  }

  let(:premium_total_xpath) { target_xml_doc.xpath("//cv:enrollment/cv:policy/cv:enrollment/cv:premium_total_amount", xml_namespace).first }
  let(:total_responsible_amount_xpath) { target_xml_doc.xpath("//cv:enrollment/cv:policy/cv:enrollment/cv:total_responsible_amount", xml_namespace).first }
  let(:applied_aptc_amount_xpath) { target_xml_doc.xpath("//cv:enrollment/cv:policy/cv:enrollment/cv:individual_market/cv:applied_aptc_amount", xml_namespace).first }

  it "recalculates the correct total excluding the dropped member" do
    expect(premium_total_xpath.content).to eq("200.0")
  end

  it "recalculates the correct total_responsible_amount" do
    expect(total_responsible_amount_xpath.content).to eq("50.0")
  end

  context "with an original aptc amount greater than the adjusted total" do
    let(:applied_aptc_amount) { '250.00' }
    it "recalculates the contribution to be no greater than the total premium" do
      expect(applied_aptc_amount_xpath.content).to eq("200.0")
    end
    it "sets the correct total_responsible_amount value" do
      expect(total_responsible_amount_xpath.content).to eq('0.0')
    end
  end
end
