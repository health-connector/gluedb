require 'spec_helper'

describe Queries::ExistingPersonQuery, :dbclean => :after_each do
  let(:existing_person) { Person.new(name_first: 'John', name_last: 'Doe') }
  let(:existing_member) { Member.new(ssn: '111111111', gender: 'male', dob: DateTime.new(2001,2,3) ) }
  let(:new_member) { existing_member.clone }

  before do
    existing_person.members << existing_member
    existing_person.save
  end

  context 'when person exists' do
    it 'finds the person' do
      query = Queries::ExistingPersonQuery.new(new_member.ssn, existing_person.name_first, new_member.dob.strftime("%Y%m%d"))
      result = query.find
      expect(result).to eq existing_person
    end
  end

  context "when person doesn't exist" do
    it 'returns nil' do
      query = Queries::ExistingPersonQuery.new('999999999', existing_person.name_first, '19400101')

      result = query.find
      expect(result).to be_nil
    end
  end
end
