require 'spec_helper'

describe Phone do
  describe "validate associations" do
	  it { should be_embedded_in :person }
    it { should be_embedded_in :employer }
  end

  [:phone_type, :phone_number, :extension, :person, :employer].each do |attribute|
    it { should respond_to attribute }
  end

  describe '#match' do
    let(:phone) do
      p = Phone.new
      p.phone_type = 'home'
      p.phone_number = '222-222-2222'
      p.extension = '12'
      p
    end

    context 'phones are the same' do 
      let(:other_phone) { phone.clone }
      it 'returns true' do
        expect(phone.match(other_phone)).to be_true
      end
    end

    context 'phones differ' do 
      context 'by type' do 
        let(:other_phone) do 
          p = phone.clone 
          p.phone_type = 'work'
          p
        end
        it 'returns false' do
          expect(phone.match(other_phone)).to be_false
        end
      end
      context 'by number' do 
        let(:other_phone) do 
          p = phone.clone 
          p.phone_number = '666-666-6666'
          p
        end
        it 'returns false' do
          expect(phone.match(other_phone)).to be_false
        end
      end
    end
  end

end
