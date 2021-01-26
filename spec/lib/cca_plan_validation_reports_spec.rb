# frozen_string_literal: true

require 'rails_helper'
require 'rake'
require 'rubyXL'
require 'rubyXL/convenience_methods'

describe 'reports generation after plan loading', :dbclean => :after_each do

  let(:current_date) {Date.today.strftime("%Y_%m_%d")}
  let(:file_name) {"CCA_PlanLoadValidation_Report_GDB_#{current_date}.xlsx"}

  before do
    load File.expand_path("#{Rails.root}/lib/tasks/cca_plan_validation_reports.rake", __FILE__)
    Rake::Task.define_task(:environment)
    allow(Date).to receive(:today).and_return Date.new(2001,2,3)
  end

  context 'generation of reports' do
    after :all do
      File.delete("CCA_PlanLoadValidation_Report_GDB_2001_02_03.xlsx") if File.file?("CCA_PlanLoadValidation_Report_GDB_2001_02_03.xlsx")
    end

    it 'should generate a xlsx when active date is passed' do
      Rake::Task["cca_plan_validation:reports"].invoke("2019-12-01")
      expect(File.exist?(file_name)).to be true
    end

    context 'first sheet' do
      it 'should generate xlsx report with given headers' do
        workbook = RubyXL::Parser.parse(file_name)
        worksheet = workbook[0]
        worksheet.sheet_data[0]
        expect(worksheet.sheet_data[0].cells.map(&:value)).to eq ["PlanYearId", "CarrierId", "CarrierName", "PlanTypeCode", "Tier", "Count"]
      end
    end

    context 'second sheet' do
      it 'should generate xlsx report with given headers' do
        workbook = RubyXL::Parser.parse(file_name)
        worksheet1 = workbook[1]
        worksheet1.sheet_data[0]
        expect(worksheet1.sheet_data[0].cells.map(&:value)).to eq ["PlanYearId", "CarrierId", "CarrierName", "Age(Range)", "IndividualRate"]
      end
    end
  end
end
