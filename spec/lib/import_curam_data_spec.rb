require 'rails_helper'

describe ImportCuramData do
  subject { ImportCuramData.new(person_factory, app_group_repo, person_finder, app_group_factory, relationship_factory, qualification_factory, financial_statements_importer, member_factory) }
  let(:member_factory) { double(new: new_member) }
  let(:new_member) { double(hbx_member_id: '666') }
  
  let(:app_group_repo) { double(find_by_case_id: app_group) }
  let(:app_group) { double(destroy: nil) }
  let(:person_finder) { 
    finder = double
    allow(finder).to receive(:find).with(person_properties).and_return(person)
    allow(finder).to receive(:find).with(child_properties).and_return(child)
    finder
  }
  let(:person_factory) { double(create!: person)}
  let(:app_group_factory) { double(create!: nil)  }
  let(:person) { double(:id => person_id, :members => person_members, :authority_member => authority_member, save!: nil) }
  let(:person_members) { [authority_member] }
  let(:app_group_properties) {
     {
      e_case_id: case_id,
      primary_applicant_id: person_id,
      people: [person, child],
      submission_date: submission_date,
      consent_applicant_id: consent_applicant_id,
      consent_applicant_name: consent_applicant_name,
      consent_renewal_year: consent_renewal_year,
      coverage_renewal_year: coverage_renewal_year
     }
   }
  let(:consent_applicant_id) { '54321'}
  let(:consent_applicant_name) { 'George'}
  let(:consent_renewal_year) { 2006 }
  let(:coverage_renewal_year) { 'did' }
  let(:submission_date) { Date.today }
  let(:person_id) { "abcde" }
  let(:case_id) { "1234" }
  let(:applicant_id) { 'franks id' }
  let(:request) do
    {
      e_case_id: case_id,
      primary_applicant_id: applicant_id,
      submission_date: submission_date,
      consent_applicant_id: consent_applicant_id,
      consent_applicant_name: consent_applicant_name,
      consent_renewal_year: consent_renewal_year,
      coverage_renewal_year: coverage_renewal_year,
      people: [
       person_properties,
       child_properties
      ],
      relationships:  [
        {:subject_person => child_applicant_id, :relationship_kind => relationship_kind, :object_person => applicant_id }
      ]
    }
  end

  let(:authority_member) { double(:hbx_member_id => member_id) }
  let(:child_authority) { double(:hbx_member_id => child_id) }

  let(:child) { double(:id => child_id, :members => child_members, :authority_member => child_authority, save!: nil) }
  let(:child_members) { [child_authority] }
  
  let(:child_properties) { { id: child_applicant_id } }
  let(:child_applicant_id) { "klsjdflkdf" }
  let(:child_id) { "a child id" }
  let(:relationship_kind) { "child of" }
  let(:relationship_update) { double(save!: nil) }
  let(:relationship_factory) { double(new: relationship_update)}
  let(:person_properties) do
    {
      :id => applicant_id,
      :dob => "frank",
      :ssn => ssn,
      :gender => gender,
      :is_applicant => is_applicant,
      :citizen_status => citizen_status,
      :is_state_resident => is_state_resident,
      :is_incarcerated => is_incarcerated,
      :e_person_id => e_person_id,
      :e_concern_role_id => e_concern_role_id,
      :aceds_id => aceds_id,
      :financial_statements => financial_statements
    }
  end
  let(:ssn) { "12345678911"}
  let(:gender) { "male" }
  let(:is_applicant) { true }

  let(:qualification_factory) { double(:new => qualification_update) }
  let(:qualification_update) { double(:save! => nil) }
  let(:member_id) { "a member id" }
  let(:citizen_status) { "nope" }
  let(:is_incarcerated) { "yup" }
  let(:is_state_resident) { "maybe, I guess.  Define 'state'."}
  let(:e_person_id) { 'e_person_id' }
  let(:e_concern_role_id) { 'e_concern_role_id' }
  let(:aceds_id) { 'aceds_id' }

  it 'finds an application group by case number' do
    expect(app_group_repo).to receive(:find_by_case_id).with(request[:e_case_id]).and_return(app_group)
    subject.execute(request)
  end

  it "should update relationships" do
    expect(relationship_factory).to receive(:new).with(
      :subject_person_id => child_id,
      :object_person_id => person_id,
      :relationship_kind => relationship_kind
    ).and_return(relationship_update)
    expect(relationship_update).to receive(:save!)
    subject.execute(request)
  end

  context 'when application group exists' do
    it "is deleted" do
      expect(app_group).to receive(:destroy)
      subject.execute(request)
    end
  end

  it "creates the application group" do
    expect(app_group_factory).to receive(:create!).with(app_group_properties)
    subject.execute(request)
  end

  it "updates the member qualifications" do
    expect(qualification_factory).to receive(:new).with(
      :member_id => member_id,
      :citizen_status => citizen_status,
      :is_state_resident => is_state_resident,
      :is_incarcerated => is_incarcerated,
      :e_person_id => e_person_id,
      :e_concern_role_id => e_concern_role_id,
      :aceds_id => aceds_id,
      :is_applicant => is_applicant
    ).and_return(qualification_update)
    expect(qualification_update).to receive(:save!)
    subject.execute(request)
  end

  context "when a person exists" do
    before(:each) do
      allow(person_finder).to receive(:find).with(person_properties).and_return(person)
    end

    it 'does not create that person' do
      expect(person_factory).not_to receive(:create!).with(person_properties)
      subject.execute(request)
    end
  end

  context "when a person doesn't exist" do
    before(:each) do
      allow(person_finder).to receive(:find).with(person_properties).and_return(nil)
    end

    it "should create that person" do
      expect(person_factory).to receive(:create!).with(person_properties)
      subject.execute(request)
    end
  end

  let(:financial_statements_importer) { double(import!: nil) }
  let(:financial_statements) { [double] }
  it 'should import the assistance eligibility information' do
    expect(financial_statements_importer).to receive(:import!).with(
      person,
      financial_statements
    )
    expect(financial_statements_importer).to receive(:import!).with(
      child,
      []
    )
    subject.execute(request)
  end


  context 'primary_applicant_id is nil' do
    let(:applicant_id) { nil }
    it 'does not create the application group' do
      expect(app_group_factory).not_to receive(:create!)
      subject.execute(request)
    end
  end

  context 'when person has no member' do
    let(:person_members) { [] }
    it 'creates a member' do
      expect(member_factory).to receive(:new).with({
        dob: "frank",
        ssn: ssn,
        gender: gender,
        is_incarcerated: is_incarcerated,
        is_state_resident: is_state_resident,
        citizen_status: citizen_status,
        is_applicant: is_applicant
      }).and_return(new_member)
      subject.execute(request)
    end

    it 'new member is assigned to person' do
      subject.execute(request)
      expect(person.members).to include new_member
    end
  end

  it 'saves the person' do
    expect(person).to receive(:save!)
    subject.execute(request)
  end
end








