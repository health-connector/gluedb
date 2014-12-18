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
      let(:person) { subject[:individuals].first }

      it "should have no name_pfx" do
        expect(person[:name_pfx]).to be_blank
      end
      it "should have the correct name_first" do
        expect(person[:name_first]).to eql("Daniel")
      end
      it "should have no name_middle" do
        expect(person[:name_middle]).to be_blank
      end
      it "should have the correct name_last" do
        expect(person[:name_last]).to eql("Tharper")
      end
      it "should have no name_sfx" do
        expect(person[:name_sfx]).to be_blank
      end

      it "should have no emails" do
        expect(person[:emails]).to be_empty
      end

      it "should have no phones" do
        expect(person[:phones]).to be_empty
      end

      it "should have the correct ssn" do
        expect(person[:ssn]).to eql("633702503")
      end
      it "should have the correct dob" do
        expect(person[:dob]).to eql("19640613")
      end
      it "should have the correct gender" do
        expect(person[:gender]).to eql("male")
      end
      it "should have the correct hbx_member_id" do
        expect(person[:hbx_member_id]).to eql("122070")
      end

      it "should have one address" do
        expect(person[:addresses].length).to eql(1)
      end

      describe "with an address" do
        let(:address) { person[:addresses].first }

        it "should be a home address" do
          expect(address[:address_type]).to eql("home")
        end

        it "should have the correct address_1" do
          expect(address[:address_1]).to eql("2255 Wisconsin Ave NW")
        end
        it "should have no address_2" do
          expect(address[:address_2]).to be_blank
        end
        it "should have no address_3" do
          expect(address[:address_3]).to be_blank
        end
        it "should have the correct city" do
          expect(address[:city]).to eql("Washington")
        end
        it "should have the correct zip" do
          expect(address[:zip]).to eql("20015")
        end
        it "should have the correct state" do
          expect(address[:state]).to eql("DC")
        end
      end
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
