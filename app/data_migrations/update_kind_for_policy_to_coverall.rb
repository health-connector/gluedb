# Changes the kind field on a policy to "coverall"
require File.join(Rails.root, "lib/mongoid_migration_task")
class UpdateKindForPolicyToCoverall < MongoidMigrationTask

  def migrate
    policy = Policy.where(eg_id: ENV['eg_id']).first
    policy.kind = "coverall"
    policy.save!
  end
end