require 'spec_helper'

describe Queries::PersonByHbxIdQuery, :dbclean => :after_each do
  let(:person) { Person.new(name_first: 'Joe', name_last: 'Dirt') }
  let(:member) { Member.new(gender: 'male') }
  let(:lookup_id) { '666' }
  let(:different_id) { '777'}
  let(:query) { Queries::PersonByHbxIdQuery.new(lookup_id) }
  context 'no person has members with the hbx id' do
    before do
      member.hbx_member_id = different_id
      person.members << member
      person.save!
    end

    it 'returns nil' do
      expect(query.execute).to eq nil
    end
  end

  context 'person has members with the hbx id' do
    before do
      member.hbx_member_id = lookup_id
      person.members << member
      person.save!
    end
    it 'returns the person' do
      expect(query.execute).to eq person
    end
  end
end
