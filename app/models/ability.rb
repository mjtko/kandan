#==============================================================================
# Copyright (C) 2013
#
# This file is part of 
#
# Some rights reserved, see LICENSE.txt.
#==============================================================================
class Ability
  include CanCan::Ability

  def initialize(user)
    if user.is_admin
      can :manage, :all
    else
      can [:read, :create], Channel
      # can :manage, Channel, :owner => user
      # can [:read, :create], Activity
      # can :read, Attachment
      # can :manage, Attachment, :user => user
      # can :manage, User, :id => user.id # can manage themselves
    end
    # This goes last in order to override all other permissions.
    cannot :destroy, Channel, :id => 1
  end
end
