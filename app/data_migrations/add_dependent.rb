# adds a dependent to an policy

require File.join(Rails.root, "lib/mongoid_migration_task")

class AddDependent < MongoidMigrationTask

  def migrate
    policy = Policy.where(eg_id: ENV['eg_id']).first
    person = Person.where(authority_member_id: ENV['hbx_id']).first
    if policy.blank?
        puts "Could not find a matching policy" unless Rails.env.test?
    elsif person.blank?
        puts "Could not find a matching person" unless Rails.env.test?
    else 
        add_dependent(policy,person)
    end
  end

  def add_dependent(policy, person)
    if is_already_member?(policy, person)
      puts "This person is already an enrollee on this policy" unless Rails.env.test?
    else 
      policy.enrollees.create!(m_id:person.authority_member_id, rel_code:ENV['rel_code'])
    end
  end

  def is_already_member?(policy, person)
    member = policy.enrollees.where(m_id: person.authority_member_id).first
    return true if member.present? 
  end

end