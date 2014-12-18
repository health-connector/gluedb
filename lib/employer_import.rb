require "net/http"
require './app/use_cases/import_employer_demographics'

class EmployerImport

  def initialize
  end

  def new_employers(file)
  end

  def process
    xml_file = File.open(Rails.root.to_s + "/sample.xml")
    ImportEmployerDemographics.new.execute(xml_file)
  end

  def update_employers
    # get_employers_from_proxy(['135469872'])
    Employer.all.in_groups_of(5, false) do |employers|
      get_employers_from_proxy(employers.map(&:fein))
      break
    end
  end

  def get_employers_from_proxy(feins)
    begin
      delivery_info_response, response_properties, employers_xml = Amqp::Requestor.default.request(
      {:routing_key => 'employer.get_by_feins'}, JSON.dump(feins), 60)

      response_code = response_properties[:headers]['status'].to_i
      case response_code
      when 200
        ImportEmployerDemographics.new.execute(employers_xml)
      when (400..499)
        raise 'Bad Request'
      when (500..599)
        raise 'Server Issues'
      end
    rescue
    end
  end
end