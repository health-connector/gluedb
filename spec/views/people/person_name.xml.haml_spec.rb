require "rails_helper"

shared_examples_for "a person name partial" do
  it "has name_last" do
    expected_node = subject.at_xpath("//person_name/person_surname")
    expect(expected_node.content).to eq name_last
  end
  it "has name_first" do
    expected_node = subject.at_xpath("//person_name/person_given_name")
    expect(expected_node.content).to eq name_first
  end
end

describe "people/_person_name.xml" do
    let(:name_last){"Last name"}
    let(:name_first){"First name"}
    let(:render_result){
      render :partial => "people/person_name", :formats => [:xml], :object=> person_name
      rendered
    }
    subject{
      Nokogiri::XML(render_result)
    }

    describe "Given:
                - NO name_pfx and No name_sfx and No name_middle" do
      let(:person_name) { instance_double(Person, {
                                                    :name_first => name_first,
                                                    :name_last => name_last,
                                                    :name_pfx => nil,
                                                    :name_sfx => nil,
                                                    :name_middle => nil
                                                }) }
      it_should_behave_like "a person name partial"
      it "has no name_pfx" do
        expected_node = subject.at_xpath("//person_name/person_name_prefix_text")
        expect(expected_node).to eq nil
      end
      it "has no name_sfx" do
        expected_node = subject.at_xpath("//person_name/person_name_suffix_text")
        expect(expected_node).to eq nil
      end
      it "has no name_middle" do
        expected_node = subject.at_xpath("//person_name/person_middle_name")
        expect(expected_node).to eq nil
      end
    end

    describe "Given:
              - An name_middle" do
      let(:name_middle) { "Some middle name" }
      let(:person_name) { instance_double(Person, {
                                                    :name_first => name_first,
                                                    :name_last => name_last,
                                                    :name_pfx => nil,
                                                    :name_sfx => nil,
                                                    :name_middle => name_middle
                                                }) }
      it_should_behave_like "a person name partial"
      it "has name_middle" do
        expected_node = subject.at_xpath("//person_name/person_middle_name")
        expect(expected_node.content).to eq name_middle
      end
    end

    describe "Given:
              - An name_pfx" do
      let(:name_pfx) { "Some name_pfx" }
      let(:person_name) { instance_double(Person, {
                                                    :name_first => name_first,
                                                    :name_last => name_last,
                                                    :name_pfx => name_pfx,
                                                    :name_sfx => nil,
                                                    :name_middle => nil
                                                }) }
      it_should_behave_like "a person name partial"
      it "has name_pfx" do
        expected_node = subject.at_xpath("//person_name/person_name_prefix_text")
        expect(expected_node.content).to eq name_pfx
      end
    end

    describe "Given:
              - An name_sfx" do
      let(:name_sfx) { "Some name_sfx" }
      let(:person_name) { instance_double(Person, {
                                                    :name_first => name_first,
                                                    :name_last => name_last,
                                                    :name_pfx => nil,
                                                    :name_sfx => name_sfx,
                                                    :name_middle => nil
                                                }) }
      it_should_behave_like "a person name partial"
      it "has name_sfx" do
        expected_node = subject.at_xpath("//person_name/person_name_suffix_text")
        expect(expected_node.content).to eq name_sfx
      end
    end

end

