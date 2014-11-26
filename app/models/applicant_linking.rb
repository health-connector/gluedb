module ApplicantLinking
  def self.included(base)
    base.class_eval do
      field :applicant_link_id, type: Moped::BSON::ObjectId
    end
  end

  def applicant_link=(app_link)
    self.applicant_link_id = app_link._id
  end

  def applicant_link
    return nil unless self.application_group
    self.application_group.applicant_links.detect do |al|
      al._id == self.applicant_link_id
    end
  end
end
