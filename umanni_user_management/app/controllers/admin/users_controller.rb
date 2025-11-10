module Admin
  class UsersController < BaseController
    before_action :set_user, only: [:show, :edit, :update, :destroy, :toggle_role]

    def index
      authorize User
      @pagy, @users = pagy(User.order(created_at: :desc), items: 20)
    end

    def show
      authorize @user
    end

    def new
      @user = User.new
      authorize @user
    end

    def create
      @user = User.new(user_params)
      authorize @user

      if @user.save
        # Broadcast to Action Cable
        ActionCable.server.broadcast("dashboard_channel", {
          event: "user_created",
          total_users: User.count,
          total_admins: User.where(role: :admin).count,
          total_regular_users: User.where(role: :user).count
        })

        redirect_to admin_users_path, notice: "User was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @user
    end

    def update
      authorize @user

      if @user.update(user_params)
        redirect_to admin_users_path, notice: "User was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @user

      if @user.destroy
        # Broadcast to Action Cable
        ActionCable.server.broadcast("dashboard_channel", {
          event: "user_deleted",
          total_users: User.count,
          total_admins: User.where(role: :admin).count,
          total_regular_users: User.where(role: :user).count
        })

        redirect_to admin_users_path, notice: "User was successfully deleted."
      else
        redirect_to admin_users_path, alert: "Cannot delete user: #{@user.errors.full_messages.join(', ')}"
      end
    end

    def toggle_role
      authorize @user, :toggle_role?

      new_role = @user.admin? ? :user : :admin
      if @user.update(role: new_role)
        # Broadcast to Action Cable
        ActionCable.server.broadcast("dashboard_channel", {
          event: "user_role_changed",
          total_admins: User.where(role: :admin).count,
          total_regular_users: User.where(role: :user).count
        })

        redirect_to admin_users_path, notice: "User role was successfully updated."
      else
        redirect_to admin_users_path, alert: "Failed to update user role."
      end
    end

    def import
      authorize User, :import?
    end

    def process_import
      authorize User, :import?

      unless params[:file].present?
        redirect_to import_admin_users_path, alert: "Please select a file to import."
        return
      end

      import_job = ImportJob.create!(
        user: current_user,
        file_name: params[:file].original_filename,
        status: :pending
      )

      # Enqueue Sidekiq job
      UserImportJob.perform_async(import_job.id, params[:file].read)

      redirect_to admin_dashboard_path, notice: "Import started. You can track progress on the dashboard."
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      permitted = [:full_name, :email, :password, :password_confirmation, :avatar_image, :role]

      # Remove password fields if they are blank (for updates)
      if params[:user][:password].blank? && params[:user][:password_confirmation].blank?
        params[:user].delete(:password)
        params[:user].delete(:password_confirmation)
      end

      params.require(:user).permit(permitted)
    end
  end
end
