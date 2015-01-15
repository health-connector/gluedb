class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    alias_action :update, :destroy, :to => :modify

    if user.role == "admin"
      can :manage, :all
    elsif user.role == "edi_ops"
      can :manage, :all
      cannot :modify, User
    elsif user.role == "user"
      can :read, :all
    elsif user.role == "service"
      can :read, Person
    end

  end
end
