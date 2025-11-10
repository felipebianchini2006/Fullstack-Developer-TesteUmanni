# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def index?
    user&.admin?
  end

  def show?
    user&.admin? || user == record
  end

  def create?
    user&.admin?
  end

  def update?
    user&.admin? || user == record
  end

  def destroy?
    return false unless user
    return false if user == record && last_admin?
    user.admin? || user == record
  end

  def toggle_role?
    user&.admin? && user != record
  end

  def import?
    user&.admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.admin?
        scope.all
      else
        scope.where(id: user.id)
      end
    end
  end

  private

  def last_admin?
    user&.admin? && User.where(role: :admin).count == 1
  end
end
