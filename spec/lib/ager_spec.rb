require './lib/ager'

describe Ager do
  subject(:ager) { Ager.new(birth_date) }
  let(:birth_date) { Date.new(1980,2,25) }

  it 'properly calculates an age for an exception' do
    ager = Ager.new(Date.new(1980,4,1))
    expect(ager.age_as_of(Date.new(2015,4,1))).to eq 35
  end

  it 'calculates the age as of a given date' do
    #same date as birth
    expect(ager.age_as_of(birth_date)).to eq 0

    # years later on birthday
    expect(ager.age_as_of(Date.new(1990,2,25))).to eq 10

    # days before birthday
    expect(ager.age_as_of(Date.new(1990,2,24))).to eq 9
    expect(ager.age_as_of(Date.new(1991,2,23))).to eq 10
    
    # month after birthday 
    expect(ager.age_as_of(Date.new(1990,3,1))).to eq 10

    #one day before birthday
  end
  context 'one day before birthday' do
    let(:birth_date) { Date.new(1959, 7, 31) }
    it 'calculates correct age' do
      expect(ager.age_as_of(Date.new(2014, 8, 1))).to eq 55 
    end
  end

  context 'months before birthday' do
    it 'calculates correct age' do
      expect(ager.age_as_of(Date.new(1990,1,25))).to eq 9
      expect(ager.age_as_of(Date.new(1991,1,25))).to eq 10
    end
  end

  describe 'leap year' do
    let(:birth_date) { Date.new(1992, 2, 29) }
    it 'calculates correct age' do
      expect(ager.age_as_of(Date.new(2000,3,1))).to eq 8
    end
  end

  describe 'leap year' do
    let(:birth_date) { Date.new(2000, 3, 1) }
    it 'calculates correct age' do
      expect(ager.age_as_of(Date.new(2004, 2, 29))).to eq 3
    end
  end
end
