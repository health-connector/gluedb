require 'rails_helper'

RSpec.describe Config::AcaHelper, :type => :helper do
  describe '#fetch_file_format' do
   let!(:helper_object) { Object.new.extend(Config::AcaHelper)}
   let!(:time_stamp) { Time.now.strftime('%Y_%m_%d_%H_%M_%S') }
   let!(:expected) { "CCA_PRODUCTION_ENROLLMENT_#{time_stamp}.csv"}

   it 'should return CCA requested file format for state MA' do
     expect(helper_object.fetch_file_format).to eq expected
   end
  end
end
