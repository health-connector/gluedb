require 'rails_helper'

module Generators::Reports
  describe IrsNoticeInputBuilder do
    subject { IrsNoticeInputBuilder.new(policy) }

    let(:policy) { double(subscriber: subscriber, enrollees_sans_subscriber: [dependent1, dependent2]) }
    let(:subscriber) { double(person: person, relationship_status_code: 'Self', coverage_start: nil, coverage_end: nil) }
    let(:dependent1) { double(person: person, relationship_status_code: 'Spouse', coverage_start: nil, coverage_end: nil) }
    let(:dependent2) { double(person: person, relationship_status_code: 'Child', coverage_start: nil, coverage_end: nil) }

    let(:person) { double(full_name: 'dan thomas', addresses: [address], authority_member: authority_member) }
    let(:authority_member) { double(ssn: '342321212', dob: (Date.today - 20.years)) }
    let(:address) { double(address_1: 'Wilson Building', address_2: 'Suite 100', city: 'Washington DC', state: 'DC', zip: '20002') }

    it 'should append recipient address' do
      subject.append_recipient_address
      expect(subject.notice.recipient_address).to be_kind_of(PdfTemplates::NoticeAddress)
      expect(subject.notice.recipient_address.street_1).to eq(address.address_1)
      expect(subject.notice.recipient_address.street_2).to eq(address.address_2)
      expect(subject.notice.recipient_address.city).to eq(address.city)
      expect(subject.notice.recipient_address.state).to eq(address.state)
      expect(subject.notice.recipient_address.zip).to eq(address.zip)
    end

    it 'should append household' do
      subject.append_household
      expect(subject.notice.recipient).to be_kind_of(PdfTemplates::Enrolee)
      expect(subject.notice.spouse).to be_kind_of(PdfTemplates::Enrolee)
    end

    it 'should append monthly premiums' do 
      subject.append_monthly_premiums

      expect(subject.notice.monthly_premiums.count).to eq(12)
      expect(subject.notice.monthly_premiums.first).to be_kind_of(PdfTemplates::MonthlyPremium)
    end
  end
end