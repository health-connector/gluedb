require "rails_helper"

RSpec.shared_examples_for "a Tufts Effectuation Transformation" do |span_count, expected_bgn_date, expected_bgn_time|
  it "alters the GS02 to the proper value" do
    parsed_json = JSON.parse(subject["WIREPAYLOADUNPACKED"])
    expect(parsed_json["GS"][2]).to eq "SHP"
  end

  it "alters the creates the right number of 834s" do
    parsed_json = JSON.parse(subject["WIREPAYLOADUNPACKED"])
    expect(parsed_json["L834s"].count).to eq span_count
  end

  it "alters and increments the STs for all 834s" do
    parsed_json = JSON.parse(subject["WIREPAYLOADUNPACKED"])
    l834s = parsed_json["L834s"]
    st_vals = l834s.map do |l834|
      l834["ST"][2]
    end
    expect(l834s.length).to eq st_vals.uniq.length
  end

  it "alters and increments the STs for all 834s" do
    parsed_json = JSON.parse(subject["WIREPAYLOADUNPACKED"])
    l834s = parsed_json["L834s"]
    se_vals = l834s.map do |l834|
      l834["SE"][2]
    end
    expect(l834s.length).to eq se_vals.uniq.length
  end

  it "alters and increments the BGN 02s for all 834s" do
    parsed_json = JSON.parse(subject["WIREPAYLOADUNPACKED"])
    l834s = parsed_json["L834s"]
    bgn_vals = l834s.map do |l834|
      l834["BGN"][2]
    end
    expect(l834s.length).to eq bgn_vals.uniq.length
  end

  it "relocates supergroup 1Ls to PIDs" do
    old_l834s = original_json["L834s"]
    located_1_l_s = Hash.new
    old_l834s.each do |l834|
      l834["L2000s"].each do |l2000|
        m_id_ref = l2000["REFs"].detect do |ref|
          ref[1] == "23"
        end
        member_id = m_id_ref[2]
        l2300s = l2000["L2300s"]
        l2300s.each do |l2300|
          l2300["REFs"].each do |ref|
            if (ref[1] == "1L")
              located_1_l_s[member_id] = ref[2]
            end
          end
        end
      end
    end
    parsed_json = JSON.parse(subject["WIREPAYLOADUNPACKED"])
    l834s = parsed_json["L834s"]
    located_p_i_d_s = Hash.new
    l834s.each do |l834|
      l834["L2000s"].each do |l2000|
        m_id_ref = l2000["REFs"].detect do |ref|
          ref[1] == "23"
        end
        member_id = m_id_ref[2]
        l2300s = l2000["L2300s"]
        l2300s.each do |l2300|
          l2300["REFs"].each do |ref|
            if (ref[1] == "PID")
              located_p_i_d_s[member_id] = ref[2]
            end
          end
        end
      end
    end
    expect(located_p_i_d_s.to_a).to eq(located_1_l_s.to_a)
  end

  it "corrects the time zone in the BGN" do
    parsed_json = JSON.parse(subject["WIREPAYLOADUNPACKED"])
    new_bgns = parsed_json["L834s"].map do |l834|
      l834["BGN"]
    end
    new_bgns.each do |bgn|
      expect(bgn[5]).to eq "UT"
      expect(bgn[3]).to eq expected_bgn_date
      expect(bgn[4]).to eq expected_bgn_time
    end
  end
end

describe LegacyEdiTransformations::TuftsEffectuationTransform, "given:
  - an effectuation with everyone in one 834
  - none of the policies are found
" do

  let(:csv_row) do
    {
      "WIREPAYLOADUNPACKED" => File.read(
        File.join(
          Rails.root,
          "spec",
          "data",
          "effectuation_transforms",
          "tufts_example.json"
        )
      )
    }
  end

  let(:transform) { LegacyEdiTransformations::TuftsEffectuationTransform.new }

  let(:original_json) { JSON.parse(csv_row["WIREPAYLOADUNPACKED"]) }

  subject { transform.apply(csv_row) }

  before :each do
    # Don't search policy info for now - we have another spec for that
    allow_any_instance_of(::LegacyEdiTransformations::TuftsSubscriberInfo).to receive(:locate_policy_information).and_return(nil)
  end

  it_behaves_like "a Tufts Effectuation Transformation", 3, "20190327", "1313"

end

describe LegacyEdiTransformations::TuftsEffectuationTransform, "given:
  - an effectuation with a single individual
  - the policy is found
" do

  let(:csv_row) do
    {
      "WIREPAYLOADUNPACKED" => File.read(
        File.join(
          Rails.root,
          "spec",
          "data",
          "effectuation_transforms",
          "tufts_single_example.json"
        )
      )
    }
  end

  let(:transform) { LegacyEdiTransformations::TuftsEffectuationTransform.new }

  let(:original_json) { JSON.parse(csv_row["WIREPAYLOADUNPACKED"]) }

  let(:subscriber_info) do
    instance_double(
      ::LegacyEdiTransformations::TuftsSubscriberInfo,
      :subscriber_id => "100001",
      :hios_id => "29125MA0030196-01",
      :carrier_assigned_policy_id => "000000001",
      :subscriber_start => "20190401"
    )
  end

  let(:policy_information) do
    [
      glue_policy_id,
      glue_employer_name,
      glue_employer_fein
    ]
  end

  let(:glue_policy_id) { "A POLICY ID" }
  let(:glue_employer_name) { "EMPLOYER NAME" }
  let(:glue_employer_fein) { "EMPLOYER FEIN" }

  subject { transform.apply(csv_row) }

  before :each do
    allow(::LegacyEdiTransformations::TuftsSubscriberInfo).to receive(:new).with(
      "100001",
      "29125MA0030196-01",
      "000000001",
      "20190401"
    ).and_return(subscriber_info)
    allow(subscriber_info).to receive(:locate_policy_information).and_return(policy_information)
  end

  it_behaves_like "a Tufts Effectuation Transformation", 1, "20190301", "0213"

  it "replaces the 1000A loop" do
    parsed_json = JSON.parse(subject["WIREPAYLOADUNPACKED"])
    l834s = parsed_json["L834s"]
    n1 = l834s.first["L1000A"]["N1"]
    expect(n1).to eq [8, "P5", glue_employer_name, "FI", glue_employer_fein]
  end

  it "adds the policy ID to all members" do
    parsed_json = JSON.parse(subject["WIREPAYLOADUNPACKED"])
    l834s = parsed_json["L834s"]
    located_1_l_s = Array.new
    l834s.each do |l834|
      l834["L2000s"].each do |l2000|
        l2300s = l2000["L2300s"]
        l2300s.each do |l2300|
          l2300["REFs"].each do |ref|
            if (ref[1] == "1L")
              located_1_l_s << ref[2]
            end
          end
        end
      end
    end
    expect(located_1_l_s).to eq [glue_policy_id]
  end

end

describe LegacyEdiTransformations::TuftsEffectuationTransform, "given:
  - an effectuation with a two individuals
  - the policy is found for both
  - the policies have different employers
" do

  let(:csv_row) do
    {
      "WIREPAYLOADUNPACKED" => File.read(
        File.join(
          Rails.root,
          "spec",
          "data",
          "effectuation_transforms",
          "tufts_two_employer_example.json"
        )
      )
    }
  end

  let(:transform) { LegacyEdiTransformations::TuftsEffectuationTransform.new }

  let(:original_json) { JSON.parse(csv_row["WIREPAYLOADUNPACKED"]) }

  let(:subscriber_1_info) do
    instance_double(
      ::LegacyEdiTransformations::TuftsSubscriberInfo,
      :subscriber_id => "100001",
      :hios_id => "29125MA0030196-01",
      :carrier_assigned_policy_id => "000000001",
      :subscriber_start => "20190401"
    )
  end

  let(:subscriber_2_info) do
    instance_double(
      ::LegacyEdiTransformations::TuftsSubscriberInfo,
      :subscriber_id => "100002",
      :hios_id => "29125MA0030195-01",
      :carrier_assigned_policy_id => "000000003",
      :subscriber_start => "20190401"
    )
  end

  let(:policy_1_information) do
    [
      glue_policy_id_1,
      glue_employer_name_1,
      glue_employer_fein_1
    ]
  end

  let(:policy_2_information) do
    [
      glue_policy_id_2,
      glue_employer_name_2,
      glue_employer_fein_2
    ]
  end

  let(:glue_policy_id_1) { "A POLICY ID 1" }
  let(:glue_employer_name_1) { "EMPLOYER NAME 1" }
  let(:glue_employer_fein_1) { "EMPLOYER FEIN 1" }
  let(:glue_policy_id_2) { "A POLICY ID 2" }
  let(:glue_employer_name_2) { "EMPLOYER NAME 2" }
  let(:glue_employer_fein_2) { "EMPLOYER FEIN 2" }

  subject { transform.apply(csv_row) }

  before :each do
    allow(::LegacyEdiTransformations::TuftsSubscriberInfo).to receive(:new).with(
      "100001",
      "29125MA0030196-01",
      "000000001",
      "20190401"
    ).and_return(subscriber_1_info)
    allow(subscriber_1_info).to receive(:locate_policy_information).and_return(policy_1_information)
    allow(::LegacyEdiTransformations::TuftsSubscriberInfo).to receive(:new).with(
      "100002",
      "29125MA0030195-01",
      "000000003",
      "20190401"
    ).and_return(subscriber_2_info)
    allow(subscriber_2_info).to receive(:locate_policy_information).and_return(policy_2_information)
  end

  it_behaves_like "a Tufts Effectuation Transformation", 2, "20190327", "1313"

  it "replaces the 1000A loops with different employers" do
    parsed_json = JSON.parse(subject["WIREPAYLOADUNPACKED"])
    l834s = parsed_json["L834s"]
    loop_1000a_n1s = l834s.map do |l834|
      l834["L1000A"]["N1"]
    end
    expect(loop_1000a_n1s).to eq(
      [
        [8, "P5", glue_employer_name_1, "FI", glue_employer_fein_1],
        [8, "P5", glue_employer_name_2, "FI", glue_employer_fein_2]
      ]
    )
  end

  it "adds the policy IDs to all members" do
    parsed_json = JSON.parse(subject["WIREPAYLOADUNPACKED"])
    l834s = parsed_json["L834s"]
    located_1_l_s = Array.new
    l834s.each do |l834|
      l834["L2000s"].each do |l2000|
        l2300s = l2000["L2300s"]
        l2300s.each do |l2300|
          l2300["REFs"].each do |ref|
            if (ref[1] == "1L")
              located_1_l_s << ref[2]
            end
          end
        end
      end
    end
    expect(located_1_l_s).to eq [glue_policy_id_1, glue_policy_id_2]
  end

end