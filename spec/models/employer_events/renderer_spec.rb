require "rails_helper"

describe EmployerEvents::Renderer, "given an xml, from which it selects carrier plan years" do
  let(:event_time) { double }

  let(:carrier) { instance_double(Carrier, :hbx_carrier_id => hbx_carrier_id) }

  let(:source_document) do
		<<-XMLCODE
		<plan_years xmlns="http://openhbx.org/api/terms/1.0">
			<plan_year>
				<plan_year_start>20151201</plan_year_start>
				<plan_year_end>20161130</plan_year_end>
				<open_enrollment_start>20151013</open_enrollment_start>
				<open_enrollment_end>20151110</open_enrollment_end>
				<benefit_groups>
					<benefit_group>
						<name>Health Insurance</name>
						<elected_plans>
							<elected_plan>
								<id>
									<id>A HIOS ID</id>
								</id>
								<name>A PLAN NAME</name>
								<active_year>2015</active_year>
								<is_dental_only>false</is_dental_only>
								<carrier>
									<id>
										<id>SOME CARRIER ID</id>
									</id>
									<name>A CARRIER NAME</name>
								</carrier>
							</elected_plan>
						</elected_plans>
					</benefit_group>
				</benefit_groups>
       </plan_year>
     </plan_years>
		XMLCODE
  end

  let(:employer_event) { instance_double(EmployerEvent, {:event_time => event_time, :resource_body => source_document}) }

  subject do
     EmployerEvents::Renderer.new(employer_event)
  end

  let(:carrier_plan_years) { subject.carrier_plan_years(carrier) }

  describe "with plan years for the specified carrier" do
    let(:hbx_carrier_id) { "SOME CARRIER ID" }

    it "finds plan years for the carrier" do
      expect(carrier_plan_years).not_to be_empty
    end

    it "has the correct element in scope" do
      element_name = carrier_plan_years.to_a.map(&:name)
    end
  end

  describe "with no plan years for the specified carrier" do
    let(:hbx_carrier_id) { "A DIFFERENT CARRIER ID" }

    it "finds plan years for the carrier" do
      expect(carrier_plan_years).to be_empty
    end
  end
end

describe EmployerEvents::Renderer, "given an xml, with an event type of benefit_coverage_renewal_carrier_dropped" do
  let(:event_time) { double }
  let(:employer_event) { instance_double(EmployerEvent, {:event_time => event_time, :event_name => EmployerEvents::EventNames::RENEWAL_CARRIER_CHANGE_EVENT, :resource_body => source_document}) }

  let(:carrier) { instance_double(Carrier, :hbx_carrier_id => hbx_carrier_id) }
  let(:plan_year_start) { Date.today + 1.day } 

  let(:plan_year_end) { plan_year_start + 1.year - 1.day }

  let(:source_document) do
		<<-XMLCODE
		<plan_years xmlns="http://openhbx.org/api/terms/1.0">
			<plan_year>
				<plan_year_start>#{plan_year_start.strftime("%Y%m%d")}</plan_year_start>
				<plan_year_end>#{plan_year_end.strftime("%Y%m%d")}</plan_year_end>
				<open_enrollment_start>20151013</open_enrollment_start>
				<open_enrollment_end>20151110</open_enrollment_end>
				<benefit_groups>
					<benefit_group>
						<name>Health Insurance</name>
						<elected_plans>
							<elected_plan>
								<id>
									<id>A HIOS ID</id>
								</id>
								<name>A PLAN NAME</name>
								<active_year>2015</active_year>
								<is_dental_only>false</is_dental_only>
								<carrier>
									<id>
										<id>SOME CARRIER ID</id>
									</id>
									<name>A CARRIER NAME</name>
								</carrier>
							</elected_plan>
						</elected_plans>
					</benefit_group>
				</benefit_groups>
       </plan_year>
     </plan_years>
		XMLCODE
  end

  subject do
     EmployerEvents::Renderer.new(employer_event)
  end

  describe "with plan years for the specified carrier, in the future" do
    let(:hbx_carrier_id) { "SOME CARRIER ID" }
    let(:plan_year_start) { Date.today + 1.day } 

    it "is an invalid carrier drop event" do
      expect(subject.drop_and_has_future_plan_year?(carrier)).to be_truthy
    end

    it "is not an invalid renewal event" do
      expect(subject.renewal_and_no_future_plan_year?(carrier)).to be_falsey
    end
  end

  describe "with plan years for the specified carrier, in the past" do
    let(:hbx_carrier_id) { "SOME CARRIER ID" }
    let(:plan_year_start) { Date.today - 1.day } 

    it "is NOT an invalid carrier drop event" do
      expect(subject.drop_and_has_future_plan_year?(carrier)).to be_falsey
    end

    it "is not an invalid renewal event" do
      expect(subject.renewal_and_no_future_plan_year?(carrier)).to be_falsey
    end
  end
end

describe EmployerEvents::Renderer, "given an xml, with an event type of benefit_coverage_renewal_application_eligible" do
  let(:event_time) { double }
  let(:employer_event) { instance_double(EmployerEvent, {:event_time => event_time, :event_name => EmployerEvents::EventNames::RENEWAL_SUCCESSFUL_EVENT, :resource_body => source_document}) }

  let(:carrier) { instance_double(Carrier, :hbx_carrier_id => hbx_carrier_id) }

  let(:plan_year_end) { plan_year_start + 1.year - 1.day }

  let(:source_document) do
		<<-XMLCODE
		<plan_years xmlns="http://openhbx.org/api/terms/1.0">
			<plan_year>
				<plan_year_start>#{plan_year_start.strftime("%Y%m%d")}</plan_year_start>
				<plan_year_end>#{plan_year_end.strftime("%Y%m%d")}</plan_year_end>
				<open_enrollment_start>20151013</open_enrollment_start>
				<open_enrollment_end>20151110</open_enrollment_end>
				<benefit_groups>
					<benefit_group>
						<name>Health Insurance</name>
						<elected_plans>
							<elected_plan>
								<id>
									<id>A HIOS ID</id>
								</id>
								<name>A PLAN NAME</name>
								<active_year>2015</active_year>
								<is_dental_only>false</is_dental_only>
								<carrier>
									<id>
										<id>SOME CARRIER ID</id>
									</id>
									<name>A CARRIER NAME</name>
								</carrier>
							</elected_plan>
						</elected_plans>
					</benefit_group>
				</benefit_groups>
       </plan_year>
     </plan_years>
		XMLCODE
  end

  subject do
     EmployerEvents::Renderer.new(employer_event)
  end

  describe "with plan years for the specified carrier, in the future" do
    let(:hbx_carrier_id) { "SOME CARRIER ID" }
    let(:plan_year_start) { Date.today + 1.day } 

    it "is NOT an invalid carrier drop event" do
      expect(subject.drop_and_has_future_plan_year?(carrier)).to be_false
    end

    it "is not an invalid renewal event" do
      expect(subject.renewal_and_no_future_plan_year?(carrier)).to be_falsey
    end
  end

  describe "with plan years for the specified carrier, in the past" do
    let(:hbx_carrier_id) { "SOME CARRIER ID" }
    let(:plan_year_start) { Date.today - 1.day } 

    it "is an invalid renewal event" do
      expect(subject.renewal_and_no_future_plan_year?(carrier)).to be_truthy
    end

    it "is NOT an invalid carrier drop event" do
      expect(subject.drop_and_has_future_plan_year?(carrier)).to be_false
    end
  end
end

describe EmployerEvents::Renderer, "given an xml" do
  let(:event_time) { double }
  let(:employer_event) { instance_double(EmployerEvent, {:event_time => event_time, :event_name => EmployerEvents::EventNames::RENEWAL_SUCCESSFUL_EVENT, :resource_body => source_document}) }

  let(:carrier) { instance_double(Carrier, :hbx_carrier_id => hbx_carrier_id) }

  let(:plan_year_end) { plan_year_start + 1.year - 1.day }

  let(:source_document) do
		<<-XMLCODE
		<plan_years xmlns="http://openhbx.org/api/terms/1.0">
			<plan_year>
				<plan_year_start>#{plan_year_start.strftime("%Y%m%d")}</plan_year_start>
				<plan_year_end>#{plan_year_end.strftime("%Y%m%d")}</plan_year_end>
				<open_enrollment_start>20151013</open_enrollment_start>
				<open_enrollment_end>20151110</open_enrollment_end>
				<benefit_groups>
					<benefit_group>
						<name>Health Insurance</name>
						<elected_plans>
							<elected_plan>
								<id>
									<id>A HIOS ID</id>
								</id>
								<name>A PLAN NAME</name>
								<active_year>2015</active_year>
								<is_dental_only>false</is_dental_only>
								<carrier>
									<id>
										<id>SOME CARRIER ID</id>
									</id>
									<name>A CARRIER NAME</name>
								</carrier>
							</elected_plan>
						</elected_plans>
					</benefit_group>
				</benefit_groups>
       </plan_year>
     </plan_years>
		XMLCODE
  end

  subject do
     EmployerEvents::Renderer.new(employer_event)
  end

  describe "with plan years for the specified carrier, which starts in the future" do
    let(:hbx_carrier_id) { "SOME CARRIER ID" }
    let(:plan_year_start) { Date.today + 1.day } 

    it "has a current or future plan year" do
      expect(subject.has_current_or_future_plan_year?(carrier)).to be_true
    end
  end

  describe "with plan years for the specified carrier, which starts today" do
    let(:hbx_carrier_id) { "SOME CARRIER ID" }
    let(:plan_year_start) { Date.today } 

    it "has a current or future plan year" do
      expect(subject.has_current_or_future_plan_year?(carrier)).to be_true
    end
  end

  describe "with plan years for the specified carrier, which ends in the future" do
    let(:hbx_carrier_id) { "SOME CARRIER ID" }
    let(:plan_year_start) { Date.today - 1.year + 2.days } 
    let(:plan_year_end) { Date.today + 1.day } 

    it "has a current or future plan year" do
      expect(subject.has_current_or_future_plan_year?(carrier)).to be_true
    end
  end

  describe "with plan years for the specified carrier, which ends today" do
    let(:hbx_carrier_id) { "SOME CARRIER ID" }
    let(:plan_year_start) { Date.today - 1.year + 1.day } 
    let(:plan_year_end) { Date.today } 

    it "has a current plan or future plan year" do
      expect(subject.has_current_or_future_plan_year?(carrier)).to be_true
    end
  end

  describe "with plan years for the specified carrier, which ends in the past" do
    let(:hbx_carrier_id) { "SOME CARRIER ID" }
    let(:plan_year_start) { Date.today - 1.year } 
    let(:plan_year_end) { Date.today - 1.day } 

    it "has no current plan or future plan year" do
      expect(subject.has_current_or_future_plan_year?(carrier)).to be_false
    end
  end

  describe "with plan years for a different carrier, which starts in the future" do
    let(:hbx_carrier_id) { "SOME OTHER CARRIER ID" }
    let(:plan_year_start) { Date.today + 1.day } 

    it "has no current or future plan year" do
      expect(subject.has_current_or_future_plan_year?(carrier)).to be_false
    end
  end
end

describe EmployerEvents::Renderer, "given an xml, from which it selects carrier plan years", :dbclean => :after_each do
  let(:event_time) { double }
  let(:start_date) { "20151201" }
  let(:end_date) {  "20161130"}
  let(:previous_start_date) { "20141201" }
  let(:previous_end_date) {  "20151130"}
  let(:hbx_id) {  "123456"}
  let(:formatted_start_date) {Date.strptime(start_date, "%Y%m%d")}
  let(:formatted_end_date) {Date.strptime(end_date, "%Y%m%d")}



  let(:employer) { instance_double(Employer, :hbx_id => '123456') }
  let(:carrier) { instance_double(Carrier, :id => "111111",:hbx_carrier_id => hbx_carrier_id, :uses_issuer_centric_sponsor_cycles => true) }
  let!(:plan_year) { instance_double(PlanYear, issuer_ids: [carrier.id], start_date: formatted_start_date, end_date: formatted_end_date, employer: employer)}
  let!(:old_plan_year) { instance_double(PlanYear, issuer_ids: [carrier.id], start_date: "12/1/2014", end_date: "11/30/2015", employer: employer)}
  let!(:plan_years) { [plan_year,old_plan_year]}

  let(:source_document) do
		<<-XMLCODE
    <organization xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://openhbx.org/api/terms/1.0" xsi:type="EmployerOrganizationType">
      <id>
        <id>234025</id>
      </id>
     <name>SEARCH BEYOND ADVENTURES INC</name>
      <fein>411444593</fein>
      <office_locations>
        <office_location>
          <id>
            <id>5b46cfafaea91a66a346fd4c</id>
          </id>
          <primary>true</primary>
          <address>
           <type>urn:openhbx:terms:v1:address_type#work</type>
            <address_line_1>245 E OLD STURBRIDGE RD</address_line_1>
            <location_city_name>BRIMFIELD</location_city_name>
            <location_county_name>Hampden</location_county_name>
            <location_state>urn:openhbx:terms:v1:us_state#massachusetts</location_state>
            <location_state_code>MA</location_state_code>
            <postal_code>01010</postal_code>
            <location_country_name/>
            <address_full_text>245 E OLD STURBRIDGE RD  BRIMFIELD, MA 01010</address_full_text>
          </address>
          <phone>
            <type>urn:openhbx:terms:v1:phone_type#work</type>
            <area_code>413</area_code>
            <phone_number>2453100</phone_number>
            <full_phone_number>4132453100</full_phone_number>
            <is_preferred>false</is_preferred>
          </phone>
        </office_location>
      </office_locations>
      <is_active>true</is_active>
      <employer_profile>
        <business_entity_kind>urn:openhbx:terms:v1:employers#s_corporation</business_entity_kind>
        <sic_code>4725</sic_code>
        <plan_years>
          <plan_year>
            <plan_year_start>#{start_date}</plan_year_start>
            <plan_year_end>#{end_date}</plan_year_end>
            <fte_count>2</fte_count>
            <pte_count>0</pte_count>
            <open_enrollment_start>20180201</open_enrollment_start>
            <open_enrollment_end>20180320</open_enrollment_end>
            <benefit_groups>
              <benefit_group>
                  <id>
                    <id>5b46d3ddaea91a38fa64aebf</id>
                  </id>
                  <name>Standard</name>
                  <group_size>1</group_size>
                  <participation_rate>0.01</participation_rate>
                  <rating_area>R-MA001</rating_area>
                  <elected_plans>
                    <elected_plan>
                      <id>
                        <id>59763MA0030011-01</id>
                      </id>
                      <name>Direct Gold 1000</name>
                      <active_year>2018</active_year>
                      <is_dental_only>false</is_dental_only>
                      <carrier>
                        <id>
                          <id>SOME CARRIER ID</id>
                        </id>
                        <name>Tufts Health Direct</name>
                        <is_active>true</is_active>
                      </carrier>
                      <metal_level>urn:openhbx:terms:v1:plan_metal_level#gold</metal_level>
                      <coverage_type>urn:openhbx:terms:v1:qhp_benefit_coverage#health</coverage_type>
                      <ehb_percent>99.5</ehb_percent>
                    </elected_plan>
                  </elected_plans>
              </benefit_group>
            </benefit_groups>
            <created_at>2018-07-12T04:06:53Z</created_at>
            <modified_at>2018-07-12T04:06:53Z</modified_at>
          </plan_year>
          <plan_year>
            <plan_year_start>#{previous_start_date}</plan_year_start>
            <plan_year_end>#{previous_end_date}</plan_year_end>
            <fte_count>2</fte_count>
            <pte_count>0</pte_count>
            <open_enrollment_start>20180201</open_enrollment_start>
            <open_enrollment_end>20180320</open_enrollment_end>
            <benefit_groups>
              <benefit_group>
                <id>
                  <id>5b46d3ddaea91a38fa64aebf</id>
                </id>
                <name>Standard</name>
                <group_size>1</group_size>
                <participation_rate>0.01</participation_rate>
                <rating_area>R-MA001</rating_area>
                <elected_plans>
                  <elected_plan>
                    <id>
                      <id>59763MA0030011-01</id>
                    </id>
                    <name>Direct Gold 1000</name>
                    <active_year>2018</active_year>
                    <is_dental_only>false</is_dental_only>
                      <carrier>
                        <id>
                          <id>SOME CARRIER ID</id>
                        </id>
                        <name>Tufts Health Direct</name>
                        <is_active>true</is_active>
                      </carrier>
                    <metal_level>urn:openhbx:terms:v1:plan_metal_level#gold</metal_level>
                    <coverage_type>urn:openhbx:terms:v1:qhp_benefit_coverage#health</coverage_type>
                    <ehb_percent>99.5</ehb_percent>
                    </elected_plan>
                </elected_plans>
              </benefit_group>
            </benefit_groups>
            <created_at>2018-07-12T04:06:53Z</created_at>
            <modified_at>2018-07-12T04:06:53Z</modified_at>
          </plan_year>
        </plan_years>
      </employer_profile>
      <created_at>2018-07-12T03:49:03Z</created_at>
      <modified_at>2019-02-25T22:09:12Z</modified_at>
    </organization>
		XMLCODE
  end

  let(:employer_event) { instance_double(EmployerEvent, {:event_time => event_time, :event_name => EmployerEvents::EventNames::RENEWAL_SUCCESSFUL_EVENT, :resource_body => source_document}) }
  let(:renewal_carrier_change_employer_event) { instance_double(EmployerEvent, {:event_time => event_time, :event_name => EmployerEvents::EventNames::RENEWAL_CARRIER_CHANGE_EVENT, :resource_body => source_document}) }
  let(:first_time_employer_event) { instance_double(EmployerEvent, {:event_time => event_time, :event_name => EmployerEvents::EventNames::FIRST_TIME_EMPLOYER_EVENT_NAME, :resource_body => first_time_employer_source_document}) }

  let!(:doc)  {Nokogiri::XML(employer_event.resource_body)}


  subject do
     EmployerEvents::Renderer.new(employer_event)
  end


  describe "with plan years for the specified carrier" do
    let(:hbx_carrier_id) { "SOME CARRIER ID" }

    it "finds updates the event if there is a previous plan year" do
      allow(employer_event).to receive(:event_name=).with(EmployerEvents::EventNames::RENEWAL_SUCCESSFUL_EVENT).and_return(employer_event)
      allow(renewal_carrier_change_employer_event).to receive(:event_name=).with(EmployerEvents::EventNames::RENEWAL_CARRIER_CHANGE_EVENT).and_return(renewal_carrier_change_employer_event)
      allow(employer_event).to receive(:employer_id).and_return(employer.hbx_id)
      allow(renewal_carrier_change_employer_event).to receive(:employer_id).and_return(employer.hbx_id)
      allow(Employer).to receive(:where).with(:hbx_id => hbx_id).and_return([employer])
      allow(plan_years).to receive(:detect).and_return(plan_year)
      allow(plan_years).to receive(:detect).with(:end_date => (Date.strptime(start_date, "%Y%m%d")-1.day)).and_return([plan_year])
      allow(employer).to receive(:plan_years).and_return(plan_years)
      allow(employer).to receive(:id).and_return(hbx_id)
      allow(PlanYear).to receive(:where).with(employer_id: employer.id, start_date: Date.strptime(start_date, "%Y%m%d"), end_date: Date.strptime(end_date, "%Y%m%d")).and_return([plan_year])
      allow(PlanYear).to receive(:first).and_return(plan_year)
      allow(PlanYear).to receive(:where).with(employer_id: employer.id, end_date: Date.strptime(start_date , "%Y%m%d")-1.day).and_return([plan_year])

      allow(carrier).to receive(:id).and_return(carrier.id)

      expect(subject.update_event_name(carrier, employer_event)).to eq EmployerEvents::EventNames::RENEWAL_SUCCESSFUL_EVENT
      expect(subject.update_event_name(carrier, renewal_carrier_change_employer_event)).to eq EmployerEvents::EventNames::RENEWAL_CARRIER_CHANGE_EVENT
      # expect(subject.update_event_name(carrier, first_time_employer_event)).to eq EmployerEvents::EventNames::FIRST_TIME_EMPLOYER_EVENT_NAME

    end

  end

  describe EmployerEvents::Renderer, "given an xml, from which it selects carrier plan years", :dbclean => :after_each do
    let(:event_time) { double }
    let(:start_date) { "20151201" }
    let(:end_date) {  "20161130"}
    let(:previous_start_date) { "20141201" }
    let(:previous_end_date) {  "20151130"}
    let(:old_plan_year_start_date) {  "20151025"}
    let(:old_plan_year_end_date) {  "20161024"}

    let(:hbx_id) {  "123456"}
    let(:formatted_start_date) {Date.strptime(old_plan_year_start_date, "%Y%m%d")}
    let(:formatted_end_date) {Date.strptime(old_plan_year_end_date, "%Y%m%d")}
    let(:employer) { instance_double(Employer, :hbx_id => '123456') }
    let(:carrier) { instance_double(Carrier, :id => "111111",:hbx_carrier_id => hbx_carrier_id, :uses_issuer_centric_sponsor_cycles => true) }
    let!(:plan_year) { instance_double(PlanYear, issuer_ids: [carrier.id], start_date: formatted_start_date, end_date: formatted_end_date, employer: employer)}
    let!(:old_plan_year) { instance_double(PlanYear, issuer_ids: [carrier.id], start_date: "12/1/2014", end_date: "11/30/2015", employer: employer)}
    let!(:plan_years) { [plan_year,old_plan_year]}
  
    let(:first_time_employer_source_document) do
      <<-XMLCODE
      <organization xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://openhbx.org/api/terms/1.0" xsi:type="EmployerOrganizationType">
        <id>
          <id>234025</id>
        </id>
       <name>SEARCH BEYOND ADVENTURES INC</name>
        <fein>411444593</fein>
        <office_locations>
          <office_location>
            <id>
              <id>5b46cfafaea91a66a346fd4c</id>
            </id>
            <primary>true</primary>
            <address>
             <type>urn:openhbx:terms:v1:address_type#work</type>
              <address_line_1>245 E OLD STURBRIDGE RD</address_line_1>
              <location_city_name>BRIMFIELD</location_city_name>
              <location_county_name>Hampden</location_county_name>
              <location_state>urn:openhbx:terms:v1:us_state#massachusetts</location_state>
              <location_state_code>MA</location_state_code>
              <postal_code>01010</postal_code>
              <location_country_name/>
              <address_full_text>245 E OLD STURBRIDGE RD  BRIMFIELD, MA 01010</address_full_text>
            </address>
            <phone>
              <type>urn:openhbx:terms:v1:phone_type#work</type>
              <area_code>413</area_code>
              <phone_number>2453100</phone_number>
              <full_phone_number>4132453100</full_phone_number>
              <is_preferred>false</is_preferred>
            </phone>
          </office_location>
        </office_locations>
        <is_active>true</is_active>
        <employer_profile>
          <business_entity_kind>urn:openhbx:terms:v1:employers#s_corporation</business_entity_kind>
          <sic_code>4725</sic_code>
          <plan_years>
            <plan_year>
              <plan_year_start>#{old_plan_year_start_date}</plan_year_start>
              <plan_year_end>#{old_plan_year_end_date}</plan_year_end>
              <fte_count>2</fte_count>
              <pte_count>0</pte_count>
              <open_enrollment_start>20180201</open_enrollment_start>
              <open_enrollment_end>20180320</open_enrollment_end>
              <benefit_groups>
                <benefit_group>
                    <id>
                      <id>5b46d3ddaea91a38fa64aebf</id>
                    </id>
                    <name>Standard</name>
                    <group_size>1</group_size>
                    <participation_rate>0.01</participation_rate>
                    <rating_area>R-MA001</rating_area>
                    <elected_plans>
                      <elected_plan>
                        <id>
                          <id>59763MA0030011-01</id>
                        </id>
                        <name>Direct Gold 1000</name>
                        <active_year>2018</active_year>
                        <is_dental_only>false</is_dental_only>
                        <carrier>
                          <id>
                            <id>SOME CARRIER ID</id>
                          </id>
                          <name>Tufts Health Direct</name>
                          <is_active>true</is_active>
                        </carrier>
                        <metal_level>urn:openhbx:terms:v1:plan_metal_level#gold</metal_level>
                        <coverage_type>urn:openhbx:terms:v1:qhp_benefit_coverage#health</coverage_type>
                        <ehb_percent>99.5</ehb_percent>
                      </elected_plan>
                    </elected_plans>
                </benefit_group>
              </benefit_groups>
              <created_at>2018-07-12T04:06:53Z</created_at>
              <modified_at>2018-07-12T04:06:53Z</modified_at>
            </plan_year>
          </plan_years>
        </employer_profile>
        <created_at>2018-07-12T03:49:03Z</created_at>
        <modified_at>2019-02-25T22:09:12Z</modified_at>
      </organization>
      XMLCODE
    end
  
    let(:first_time_employer_event) { instance_double(EmployerEvent, {:event_time => event_time, :event_name => EmployerEvents::EventNames::FIRST_TIME_EMPLOYER_EVENT_NAME, :resource_body => first_time_employer_source_document}) }
  
    let!(:doc)  {Nokogiri::XML(employer_event.resource_body)}
  
  
    subject do
       EmployerEvents::Renderer.new(first_time_employer_event)
    end
  
  
    describe "with plan years for the specified carrier" do
      let(:hbx_carrier_id) { "SOME CARRIER ID" }
  
      it "finds updates the event if there is a previous plan year" do
        allow(employer_event).to receive(:event_name=).with(EmployerEvents::EventNames::RENEWAL_SUCCESSFUL_EVENT).and_return(employer_event)
        allow(renewal_carrier_change_employer_event).to receive(:event_name=).with(EmployerEvents::EventNames::RENEWAL_CARRIER_CHANGE_EVENT).and_return(renewal_carrier_change_employer_event)
        allow(employer_event).to receive(:employer_id).and_return(employer.hbx_id)
        allow(renewal_carrier_change_employer_event).to receive(:employer_id).and_return(employer.hbx_id)
        allow(Employer).to receive(:where).with(:hbx_id => hbx_id).and_return([employer])
        allow(plan_years).to receive(:detect).and_return(plan_year)
        allow(plan_years).to receive(:detect).with(:end_date => (Date.strptime(start_date, "%Y%m%d")-1.day)).and_return([plan_year])
        allow(employer).to receive(:plan_years).and_return(plan_years)
        allow(employer).to receive(:id).and_return(hbx_id)
        # allow(PlanYear).to receive(:where).with(employer_id: employer.id, start_date: Date.strptime(old_plan_year_start_date, "%Y%m%d"), end_date: Date.strptime(old_plan_year_end_date, "%Y%m%d")).and_return([nil])

        allow(PlanYear).to receive(:where).with(employer_id: employer.id, start_date: Date.strptime(old_plan_year_start_date, "%Y%m%d"), end_date: Date.strptime(old_plan_year_end_date, "%Y%m%d")).and_return([plan_year])

        allow(PlanYear).to receive(:first).and_return(plan_year)
        allow(PlanYear).to receive(:first).and_return(nil)

        allow(PlanYear).to receive(:where).with(employer_id: employer.id, end_date: Date.strptime(old_plan_year_start_date , "%Y%m%d")-1.day).and_return([])
        allow(first_time_employer_event).to receive(:employer_id).and_return(employer.id)
  
        allow(carrier).to receive(:id).and_return(carrier.id)
  
        expect(subject.update_event_name(carrier, first_time_employer_event)).to eq EmployerEvents::EventNames::FIRST_TIME_EMPLOYER_EVENT_NAME
  
      end
  
    end
  


end
end
