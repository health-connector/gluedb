module ApplicantGrouping
  def self.included(base)
    base.class_eval do
      field :primary_applicant_id, type: Moped::BSON::ObjectId
      field :applicant_link_ids, type: [Moped::BSON::ObjectId]
    end
  end

  def primary_applicant=(app_link)
    self.primary_applicant_id = app_link._id
  end

  def primary_applicant
    return nil unless self.application_group
    self.application_group.applicant_links.detect do |al|
      al._id == self.primary_applicant_id
    end
  end

  def applicant_links
    return [] unless self.application_group
    self.application_group.applicant_links.select do |al|
      applicant_ids.include?(al._id)
    end
  end
end
