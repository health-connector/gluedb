class EmployerEvent
  include Mongoid::Document
  include Mongoid::Timestamps

  field :event_time, Time
  field :event_name, String
  field :resource_body, String
  field :employer_id, String

  index({event_time: 1, event_name: 1, employer_id: 1})

  def self.newest_event?(new_employer_id, new_event_name, new_event_time)
    !self.where(:employer_id => new_employer_id, :event_name => new_event_name, :event_time => {"$gte" => new_event_time}).any?
  end

  def self.store_and_yield_deleted(new_employer_id, new_event_name, new_event_time, new_payload)
    new_event = self.create!({
      employer_id: new_employer_id,
      event_name: new_event_name,
      event_time: new_event_time,
      resource_body: new_payload
    })
    self.where(:employer_id => new_employer_id, :event_name => new_event_name, :_id => {"$ne" => new_event._id}).each do |old_record|
      yield old_record
      old_record.destroy!
    end
  end

end
