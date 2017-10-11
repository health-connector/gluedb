# Changes the broker on a policy
require File.join(Rails.root, "lib/mongoid_migration_task")
class ChangePolicyBroker < MongoidMigrationTask

  def migrate
    broker = Broker.find_by_npn(ENV['broker_npn'])
    policy = Policy.where(eg_id: ENV['eg_id']).first
    policy.broker = broker
    policy.save!
  end
end