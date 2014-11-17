require 'open-uri'
require 'nokogiri'
require './lib/exposes_employer_xml'

describe ExposesEmployerXml do
  let(:namespace) { "xmlns=\"http://dchealthlink.com/vocabulary/20131030/employer\"" }

  it 'exposes name' do
    name = 'Joe Dirt'
    parser = Nokogiri::XML("<employer #{namespace}><name>#{name}</name></employer>")
    employer = ExposesEmployerXml.new(parser)
    expect(employer.name).to eq name
  end

  it 'exposes fein' do
    fein = '1234'
    parser = Nokogiri::XML("<employer #{namespace}><fein>#{fein}</fein></employer>")
    employer = ExposesEmployerXml.new(parser)
    expect(employer.fein).to eq fein
  end

  it 'exposes employer exchange id' do
    employer_exchange_id = '4321'
    parser = Nokogiri::XML("<employer #{namespace}><employer_exchange_id>#{employer_exchange_id}</employer_exchange_id></employer>")
    employer = ExposesEmployerXml.new(parser)
    expect(employer.employer_exchange_id).to eq employer_exchange_id
  end

  describe 'sic code' do
    it 'returns code when present' do
      sic_code = '4321'
      parser = Nokogiri::XML("<employer #{namespace}><sic_code>#{sic_code}</sic_code></employer>")
      employer = ExposesEmployerXml.new(parser)
      expect(employer.sic_code).to eq sic_code
    end

    it 'returns blank when absent' do
      parser = Nokogiri::XML("<employer #{namespace}></employer>")
      employer = ExposesEmployerXml.new(parser)
      expect(employer.sic_code).to eq ''
    end
  end

  it 'exposes fte_count' do
    fte_count = '1'
    parser = Nokogiri::XML("<employer #{namespace}><fte_count>#{fte_count}</fte_count></employer>")
    employer = ExposesEmployerXml.new(parser)
    expect(employer.fte_count).to eq fte_count
  end

  it 'exposes pte_count' do
    pte_count = '1'
    parser = Nokogiri::XML("<employer #{namespace}><pte_count>#{pte_count}</pte_count></employer>")
    employer = ExposesEmployerXml.new(parser)
    expect(employer.pte_count).to eq pte_count
  end

  describe 'broker npn id' do
    it 'exposes broker npn id' do
      broker_npn_id = '6543'
      parser = Nokogiri::XML("<employer #{namespace}><broker><npn_id>#{broker_npn_id}</npn_id></broker></employer>")
      employer = ExposesEmployerXml.new(parser)
      expect(employer.broker_npn_id).to eq broker_npn_id
    end

    it 'is optional sent' do
      parser = Nokogiri::XML("<employer #{namespace}></employer>")
      employer = ExposesEmployerXml.new(parser)
      expect(employer.broker_npn_id).to eq ''
    end
  end


  it 'exposes open_enrollment_start' do
    open_enrollment_start = '2010-02-01'
    parser = Nokogiri::XML("<employer #{namespace}><open_enrollment_start>#{open_enrollment_start}</open_enrollment_start></employer>")
    employer = ExposesEmployerXml.new(parser)
    expect(employer.open_enrollment_start).to eq open_enrollment_start
  end

  it 'exposes open_enrollment_end' do
    open_enrollment_end = '2010-02-01'
    parser = Nokogiri::XML("<employer #{namespace}><open_enrollment_end>#{open_enrollment_end}</open_enrollment_end></employer>")
    employer = ExposesEmployerXml.new(parser)
    expect(employer.open_enrollment_end).to eq open_enrollment_end
  end

  it 'exposes plan_year_start' do
    plan_year_start = '2010-02-01'
    parser = Nokogiri::XML("<employer #{namespace}><plan_year_start>#{plan_year_start}</plan_year_start></employer>")
    employer = ExposesEmployerXml.new(parser)
    expect(employer.plan_year_start).to eq plan_year_start
  end

  describe 'plan_year_end' do
    it 'returns date when present' do
      plan_year_end = '2010-02-01'
      parser = Nokogiri::XML("<employer #{namespace}><plan_year_end>#{plan_year_end}</plan_year_end></employer>")
      employer = ExposesEmployerXml.new(parser)
      expect(employer.plan_year_end).to eq plan_year_end
    end

    it 'returns blank when absent' do
      parser = Nokogiri::XML("<employer #{namespace}></employer>")
      employer = ExposesEmployerXml.new(parser)
      expect(employer.plan_year_end).to eq ''
    end
  end


  it 'exposes plans' do
    parser = Nokogiri::XML("<employer #{namespace}><plans><plan>yoo</plan></plans></employer>")
    employer = ExposesEmployerXml.new(parser.root)
    expect(employer.plans.length).to eq 1
  end

  it 'exposes employer contact' do
    parser = Nokogiri::XML("<employer #{namespace}><vcard>SOMETHING</vcard></employer>")
    employer = ExposesEmployerXml.new(parser)
    expect(employer.contact).not_to eq nil
  end

  it 'exposes exchange id' do
    exchange_id = '4321'
    parser = Nokogiri::XML("<employer #{namespace}><exchange_id>#{exchange_id}</exchange_id></employer>")
    employer = ExposesEmployerXml.new(parser)
    expect(employer.exchange_id).to eq exchange_id
  end
  it 'exposes exchange status' do
    exchange_status = 'active'
    parser = Nokogiri::XML("<employer #{namespace}><exchange_status>#{exchange_status}</exchange_status></employer>")
    employer = ExposesEmployerXml.new(parser)
    expect(employer.exchange_status).to eq exchange_status
  end
  it 'exposes exchange version' do
    exchange_version = '1'
    parser = Nokogiri::XML("<employer #{namespace}><exchange_version>#{exchange_version}</exchange_version></employer>")
    employer = ExposesEmployerXml.new(parser)
    expect(employer.exchange_version).to eq exchange_version
  end

  describe 'notes' do
    it 'exposes notes when present' do
      notes = "This is something that should be noted."
      parser = Nokogiri::XML("<employer #{namespace}><notes>#{notes}</notes></employer>")
      employer = ExposesEmployerXml.new(parser)
      expect(employer.notes).to eq notes
    end

    it 'returns blank when absent' do
      parser = Nokogiri::XML("<employer #{namespace}></employer>")
      employer = ExposesEmployerXml.new(parser)
      expect(employer.notes).to eq ''
    end
  end
end
