class HomeController < ApplicationController
  def index
    if user_signed_in?
      redirect_to current_user.admin? ? admin_dashboard_path : profile_path
    end
  end
end
