require 'rails_helper'

module Generators::Reports
  describe MultiVersionAptcLookup do
    subject { MultiVersionAptcLookup.new(policy) }

    let(:policy) { double(id: 24, subscriber: subscriber, enrollees: [subscriber, dependent1, dependent2], applied_aptc: 364.0, versions: versions) }

    let(:plan) { double(carrier: carrier) }
    let(:carrier) { double(name: 'Care First')}
    let(:policy_start) { Date.new(2014, 1, 1) }
    let(:policy_end) { Date.new(2014, 12, 31)} 
    let(:subscriber) { double(person: person, relationship_status_code: 'Self', coverage_start: policy_start, coverage_end: policy_end) }
    let(:dependent1) { double(person: person, relationship_status_code: 'Spouse', coverage_start: policy_start, coverage_end: policy_end) }
    let(:dependent2) { double(person: person, relationship_status_code: 'Child', coverage_start: policy_start, coverage_end: policy_end) }

    let(:person) { double(full_name: 'Ann B Mcc', name_first: 'Ann', name_middle: 'B', name_last: 'Mcc', name_sfx: '') }

    let(:versions) { [] }

    context 'when a policy got different APTC versions for the same month' do

      let(:version1) { double(applied_aptc: 975.0, updated_at: Time.new(2014, 8, 9, 6))}
      let(:version2) { double(applied_aptc: 975.0, updated_at: Time.new(2014, 8, 9, 8))}
      let(:version3) { double(applied_aptc: 443.0, updated_at: Time.new(2014, 8, 9, 10))}

      let(:versions) { [version1, version2, version3] }
      let(:policy) { double(subscriber: subscriber, applied_aptc: 443.0, versions: versions, updated_at: Time.new(2014, 12, 9, 10)) }

      let(:policy_start) { Date.new(2014, 8, 1) }
      let(:policy_end) { Date.new(2014, 12, 31)} 

      it 'should take most recent aptc' do
        expect(subject.aptc_as_of(Date.new(2014, 1, 1))).to be_nil
        expect(subject.aptc_as_of(Date.new(2014, 2, 1))).to be_nil
        expect(subject.aptc_as_of(Date.new(2014, 3, 1))).to be_nil
        expect(subject.aptc_as_of(Date.new(2014, 4, 1))).to be_nil
        expect(subject.aptc_as_of(Date.new(2014, 5, 1))).to be_nil
        expect(subject.aptc_as_of(Date.new(2014, 6, 1))).to be_nil
        expect(subject.aptc_as_of(Date.new(2014, 7, 1))).to be_nil
        expect(subject.aptc_as_of(Date.new(2014, 8, 1))).to eq(443.0)
        expect(subject.aptc_as_of(Date.new(2014, 9, 1))).to eq(443.0)
        expect(subject.aptc_as_of(Date.new(2014, 10, 1))).to eq(443.0)
        expect(subject.aptc_as_of(Date.new(2014, 11, 1))).to eq(443.0)
        expect(subject.aptc_as_of(Date.new(2014, 12, 1))).to eq(443.0)
      end
    end

    context 'when policy started and ended in the middle of the year' do
      let(:version1) { double(applied_aptc: 162.0, updated_at: Time.new(2014, 8, 9, 22))}
      let(:version2) { double(applied_aptc: 162.0, updated_at: Time.new(2014, 9, 12, 15))}
      let(:version3) { double(applied_aptc: 162.0, updated_at: Time.new(2014, 11, 6, 23))}
      let(:version4) { double(applied_aptc: 0.0, updated_at: Time.new(2014, 11, 8, 10))}

      let(:versions) { [version1, version2, version3, version4] }
      let(:policy) { double(subscriber: subscriber, applied_aptc: 0.0, versions: versions, updated_at: Time.new(2014, 12, 9, 10)) }

      let(:policy_start) { Date.new(2014, 5, 1) }
      let(:policy_end) { Date.new(2014, 11, 1)} 

      it 'should display aptcs for the covered period' do
        expect(subject.aptc_as_of(Date.new(2014, 1, 1))).to be_nil
        expect(subject.aptc_as_of(Date.new(2014, 2, 1))).to be_nil
        expect(subject.aptc_as_of(Date.new(2014, 3, 1))).to be_nil
        expect(subject.aptc_as_of(Date.new(2014, 4, 1))).to be_nil
        expect(subject.aptc_as_of(Date.new(2014, 5, 1))).to eq(162.0)
        expect(subject.aptc_as_of(Date.new(2014, 6, 1))).to eq(162.0)
        expect(subject.aptc_as_of(Date.new(2014, 7, 1))).to eq(162.0)
        expect(subject.aptc_as_of(Date.new(2014, 8, 1))).to eq(162.0)
        expect(subject.aptc_as_of(Date.new(2014, 9, 1))).to eq(162.0)
        expect(subject.aptc_as_of(Date.new(2014, 10, 1))).to eq(162.0)
        expect(subject.aptc_as_of(Date.new(2014, 11, 1))).to be_nil
        expect(subject.aptc_as_of(Date.new(2014, 12, 1))).to be_nil
      end
    end


    context 'when a policy aptc changed in the last month to zero' do
  
      let(:version1) { double(applied_aptc: 13.0, updated_at: Time.new(2014, 8, 9, 6))}
      let(:version2) { double(applied_aptc: 13.0, updated_at: Time.new(2014, 9, 12, 8))}
      let(:version3) { double(applied_aptc: 0.0, updated_at: Time.new(2014, 11, 8, 10))}

      let(:versions) { [version1, version2, version3] }
      let(:policy) { double(subscriber: subscriber, applied_aptc: 0.0, versions: versions, updated_at: Time.new(2014, 12, 9, 10)) }
      let(:policy_start) { Date.new(2014, 4, 1) }
      let(:policy_end) { Date.new(2014, 12, 31)}

      it 'should display aptcs for the rest of the period' do
        expect(subject.aptc_as_of(Date.new(2014, 1, 1))).to be_nil
        expect(subject.aptc_as_of(Date.new(2014, 2, 1))).to be_nil
        expect(subject.aptc_as_of(Date.new(2014, 3, 1))).to be_nil
        expect(subject.aptc_as_of(Date.new(2014, 4, 1))).to eq(13.0)
        expect(subject.aptc_as_of(Date.new(2014, 5, 1))).to eq(13.0)
        expect(subject.aptc_as_of(Date.new(2014, 6, 1))).to eq(13.0)
        expect(subject.aptc_as_of(Date.new(2014, 7, 1))).to eq(13.0)
        expect(subject.aptc_as_of(Date.new(2014, 8, 1))).to eq(13.0)
        expect(subject.aptc_as_of(Date.new(2014, 9, 1))).to eq(13.0)
        expect(subject.aptc_as_of(Date.new(2014, 10, 1))).to eq(13.0)
        expect(subject.aptc_as_of(Date.new(2014, 11, 1))).to eq(13.0)
        expect(subject.aptc_as_of(Date.new(2014, 12, 1))).to eq(0.0)
      end
    end

    context 'when current policy version is updated in november to zero' do
      let(:version1) { double(applied_aptc: 198.0, updated_at: Time.new(2014, 8, 9, 6))}
      let(:version2) { double(applied_aptc: 198.0, updated_at: Time.new(2014, 8, 13, 8))}
      let(:version3) { double(applied_aptc: 198.0, updated_at: Time.new(2014, 9, 12, 10))}

      let(:versions) { [version1, version2, version3] }
      let(:policy) { double(subscriber: subscriber, applied_aptc: 0.0, versions: versions, updated_at: Time.new(2014, 11, 12, 10) ) }
      let(:policy_start) { Date.new(2014, 1, 1) }
      let(:policy_end) { Date.new(2014, 12, 31)} 

      it 'should display last month aptc as zero' do
        expect(subject.aptc_as_of(Date.new(2014, 1, 1))).to eq(198.0)
        expect(subject.aptc_as_of(Date.new(2014, 2, 1))).to eq(198.0)
        expect(subject.aptc_as_of(Date.new(2014, 3, 1))).to eq(198.0)
        expect(subject.aptc_as_of(Date.new(2014, 4, 1))).to eq(198.0)
        expect(subject.aptc_as_of(Date.new(2014, 5, 1))).to eq(198.0)
        expect(subject.aptc_as_of(Date.new(2014, 6, 1))).to eq(198.0)
        expect(subject.aptc_as_of(Date.new(2014, 7, 1))).to eq(198.0)
        expect(subject.aptc_as_of(Date.new(2014, 8, 1))).to eq(198.0)
        expect(subject.aptc_as_of(Date.new(2014, 9, 1))).to eq(198.0)
        expect(subject.aptc_as_of(Date.new(2014, 10, 1))).to eq(198.0)
        expect(subject.aptc_as_of(Date.new(2014, 11, 1))).to eq(198.0)
        expect(subject.aptc_as_of(Date.new(2014, 12, 1))).to eq(0.0)
      end
    end

    context 'when policy begin and end dates in the middle of the month' do
      let(:version1) { double(applied_aptc: 198.0, updated_at: Time.new(2014, 8, 9, 6))}
      let(:version2) { double(applied_aptc: 198.0, updated_at: Time.new(2014, 8, 13, 8))}
      let(:version3) { double(applied_aptc: 198.0, updated_at: Time.new(2014, 9, 12, 10))}

      let(:versions) { [version1, version2, version3] }
      let(:policy) { double(subscriber: subscriber, applied_aptc: 0.0, versions: versions, updated_at: Time.new(2014, 12, 12, 10) ) }
      let(:policy_start) { Date.new(2014, 2, 6) }
      let(:policy_end) { Date.new(2014, 8, 8)} 

      it 'should change coverage only at the end of the month' do
        expect(subject.aptc_as_of(Date.new(2014, 1, 1))).to be_nil
        expect(subject.aptc_as_of(Date.new(2014, 2, 1))).to be_nil
        expect(subject.aptc_as_of(Date.new(2014, 3, 1))).to eq(198.0)
        expect(subject.aptc_as_of(Date.new(2014, 4, 1))).to eq(198.0)
        expect(subject.aptc_as_of(Date.new(2014, 5, 1))).to eq(198.0)
        expect(subject.aptc_as_of(Date.new(2014, 6, 1))).to eq(198.0)
        expect(subject.aptc_as_of(Date.new(2014, 7, 1))).to eq(198.0)
        expect(subject.aptc_as_of(Date.new(2014, 8, 1))).to eq(198.0)
        expect(subject.aptc_as_of(Date.new(2014, 9, 1))).to be_nil
        expect(subject.aptc_as_of(Date.new(2014, 10, 1))).to be_nil
        expect(subject.aptc_as_of(Date.new(2014, 11, 1))).to be_nil
        expect(subject.aptc_as_of(Date.new(2014, 12, 1))).to be_nil
      end
    end


    context 'when policy begin and end dates in the middle of the month' do
      let(:version1) { double(applied_aptc: 162.0, updated_at: Time.new(2014, 8, 9, 6))}
      let(:version2) { double(applied_aptc: 162.0, updated_at: Time.new(2014, 9, 13, 8))}
      let(:version3) { double(applied_aptc: 162.0, updated_at: Time.new(2014, 11, 6, 10))}
      let(:version4) { double(applied_aptc:   0.0, updated_at: Time.new(2014, 11, 8, 10))}

      let(:versions) { [version1, version2, version3, version4] }
      let(:policy) { double(subscriber: subscriber, applied_aptc: 0.0, versions: versions, updated_at: Time.new(2014, 12, 12, 10) ) }
      let(:policy_start) { Date.new(2014, 1, 1) }
      let(:policy_end) { Date.new(2014, 12, 10)} 

      it 'should change coverage only at the end of the month' do
        expect(subject.aptc_as_of(Date.new(2014, 1, 1))).to eq(162.0)
        expect(subject.aptc_as_of(Date.new(2014, 2, 1))).to eq(162.0)
        expect(subject.aptc_as_of(Date.new(2014, 3, 1))).to eq(162.0)
        expect(subject.aptc_as_of(Date.new(2014, 4, 1))).to eq(162.0)
        expect(subject.aptc_as_of(Date.new(2014, 5, 1))).to eq(162.0)
        expect(subject.aptc_as_of(Date.new(2014, 6, 1))).to eq(162.0)
        expect(subject.aptc_as_of(Date.new(2014, 7, 1))).to eq(162.0)
        expect(subject.aptc_as_of(Date.new(2014, 8, 1))).to eq(162.0)
        expect(subject.aptc_as_of(Date.new(2014, 9, 1))).to eq(162.0)
        expect(subject.aptc_as_of(Date.new(2014, 10, 1))).to eq(162.0)
        expect(subject.aptc_as_of(Date.new(2014, 11, 1))).to eq(162.0)
        expect(subject.aptc_as_of(Date.new(2014, 12, 1))).to eq(0.0)
      end
    end

    context 'when policy has partial aptc' do
      let(:version1) { double(applied_aptc: 48.0, updated_at: Time.new(2014, 8, 9, 6))}
      let(:version2) { double(applied_aptc: 0.0, updated_at: Time.new(2014, 8, 11, 8))}
      let(:version3) { double(applied_aptc: 0.0, updated_at: Time.new(2014, 9, 6, 10))}
      let(:version4) { double(applied_aptc: 48.0, updated_at: Time.new(2014, 9, 9, 10))}

      let(:versions) { [version1, version2, version3, version4] }
      let(:policy) { double(subscriber: subscriber, applied_aptc: 0.0, versions: versions, updated_at: Time.new(2014, 11, 12, 10) ) }
      let(:policy_start) { Date.new(2014, 3, 1) }
      let(:policy_end) { Date.new(2014, 12, 10)}

      it 'should display aptcs for respective months' do
        expect(subject.aptc_as_of(Date.new(2014, 1, 1))).to be_nil
        expect(subject.aptc_as_of(Date.new(2014, 2, 1))).to be_nil
        expect(subject.aptc_as_of(Date.new(2014, 3, 1))).to eq(0.0)
        expect(subject.aptc_as_of(Date.new(2014, 4, 1))).to eq(0.0)
        expect(subject.aptc_as_of(Date.new(2014, 5, 1))).to eq(0.0)
        expect(subject.aptc_as_of(Date.new(2014, 6, 1))).to eq(0.0)
        expect(subject.aptc_as_of(Date.new(2014, 7, 1))).to eq(0.0)
        expect(subject.aptc_as_of(Date.new(2014, 8, 1))).to eq(0.0)
        expect(subject.aptc_as_of(Date.new(2014, 9, 1))).to eq(0.0)
        expect(subject.aptc_as_of(Date.new(2014, 10, 1))).to eq(48.0)
        expect(subject.aptc_as_of(Date.new(2014, 11, 1))).to eq(48.0)
        expect(subject.aptc_as_of(Date.new(2014, 12, 1))).to eq(0.0)
      end
    end

    context 'when policy has partial aptc' do
      let(:version1) { double(applied_aptc: 317.0, updated_at: Time.new(2014, 8, 9, 6))}
      let(:version2) { double(applied_aptc: 317.0, updated_at: Time.new(2014, 9, 11, 8))}
      let(:version3) { double(applied_aptc: 317.0, updated_at: Time.new(2014, 11, 6, 10))}
      let(:version4) { double(applied_aptc: 0.0, updated_at: Time.new(2014, 11, 19, 10))}

      let(:versions) { [version1, version2, version3, version4] }
      let(:policy) { double(subscriber: subscriber, applied_aptc: 0.0, versions: versions, updated_at: Time.new(2015, 1, 28, 10) ) }
      let(:policy_start) { Date.new(2014, 3, 1) }
      let(:policy_end) { Date.new(2014, 12, 31)}

      it 'should display aptcs for respective months' do
        expect(subject.aptc_as_of(Date.new(2014, 3, 1))).to eq(317.0)
        expect(subject.aptc_as_of(Date.new(2014, 4, 1))).to eq(317.0)
        expect(subject.aptc_as_of(Date.new(2014, 5, 1))).to eq(317.0)
        expect(subject.aptc_as_of(Date.new(2014, 6, 1))).to eq(317.0)
        expect(subject.aptc_as_of(Date.new(2014, 7, 1))).to eq(317.0)
        expect(subject.aptc_as_of(Date.new(2014, 8, 1))).to eq(317.0)
        expect(subject.aptc_as_of(Date.new(2014, 9, 1))).to eq(317.0)
        expect(subject.aptc_as_of(Date.new(2014, 10, 1))).to eq(317.0)
        expect(subject.aptc_as_of(Date.new(2014, 11, 1))).to eq(317.0)
        expect(subject.aptc_as_of(Date.new(2014, 12, 1))).to eq(0.0)
      end
    end
  end
end