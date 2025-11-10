module Admin
  class DashboardController < BaseController
    def index
      authorize :dashboard, :show?

      @total_users = User.count
      @total_admins = User.where(role: :admin).count
      @total_regular_users = User.where(role: :user).count
      @recent_imports = ImportJob.recent.limit(10)
      @recent_users = User.order(created_at: :desc).limit(10)
    end
  end
end
