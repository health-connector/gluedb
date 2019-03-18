require "rails_helper"

# Integration specs for payloads we know to cause a crash during import.
# This will function as a place to identify and solve explicitly the issues
# with crash during the employer import.
describe EmployerEvents::EmployerImporter, "given an employer event xml known to cause a contacts crash", dbclean: :after_each do
  let(:event_xml_path) do
    File.expand_path(
      File.join(
        Rails.root,
        "spec/data/resources/employer_with_contact_info.xml"
      )
    )
  end

  let(:employer_event_xml) do
    File.read(event_xml_path)
  end

  let(:event_name) { "benefit_coverage_initial_application_eligible" }

  subject { EmployerEvents::EmployerImporter.new(employer_event_xml, event_name) }

  it "persists without issue" do
    subject.persist
  end
end
