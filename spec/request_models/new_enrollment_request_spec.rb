require "rails_helper"

describe NewEnrollmentRequest do

  let(:xml) { File.open(file_path).read }

  subject { NewEnrollmentRequest.from_xml(xml) }

  describe "with file n4601383594475126784.xml" do

    let(:file_path) { File.join(Rails.root, "spec/data/request_models/new_enrollment_request/n4601383594475126784.xml") }

    it "should have a single policy" do
      expect(subject[:policies].length).to eql 1
    end

    it "should have a single individual" do
      expect(subject[:individuals].length).to eql 1
    end

    describe "the single individual" do

    end

    describe "the single policy inside" do
      let(:policy) { subject[:policies].first }

      it "should have the correct enrollment group id" do
        expect(policy[:enrollment_group_id]).to eql("-4601383594475126784")
      end

      it "should have the correct hios_id" do
        expect(policy[:hios_id]).to eql("86052DC0410002-01")
      end

      it "should have the correct plan_year" do
        expect(policy[:plan_year]).to eql("2014")
      end

      it "should have the correct applied_aptc" do
        expect(policy[:applied_aptc]).to eql("0.0")
      end
      it "should have the correct pre_amt_tot" do
        expect(policy[:pre_amt_tot]).to eql("244.17")
      end

      it "should have the correct tot_res_amt" do
        expect(policy[:tot_res_amt]).to eql("244.17")
      end

      it "should have the correct carrier_to_bill" do
        expect(policy[:carrier_to_bill]).to eql("true")
      end

      it "should have no broker" do
        expect(policy[:broker_npn]).to be_blank
      end

      it "should have a single enrollee" do
        expect(policy[:enrollees].length).to eql(1)
      end

      describe "the single enrollee for that policy" do
        let(:enrollee) { policy[:enrollees].first }

        it "should have the correct m_id" do
          expect(enrollee[:m_id]).to eql("122070")
        end

        it "should have the correct rel_code" do
          expect(enrollee[:rel_code]).to eql("self")
        end

        it "should have the correct ben_stat" do
          expect(enrollee[:ben_stat]).to eql("active")
        end

        it "should have the correct emp_stat" do
          expect(enrollee[:emp_stat]).to eql("active")
        end

        it "should have the correct pre_amt" do
          expect(enrollee[:pre_amt]).to eql("244.17")
        end

        it "should have the correct coverage_start" do
          expect(enrollee[:coverage_start]).to eql("20141201")
        end
      end
    end
  end

end
