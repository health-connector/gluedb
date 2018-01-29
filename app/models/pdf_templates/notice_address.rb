module PdfTemplates
  class NoticeAddress
    include Virtus.model

    attribute :street_1, String
    attribute :street_2, String
    attribute :city, String
    attribute :state, String
    attribute :zip, String

    def to_s
      city.present? ? city_delim = city + "," : city_delim = city
      [street_1, street_2, city_delim, state, zip].reject(&:nil? || empty?).join(' ')
    end
  end
end
