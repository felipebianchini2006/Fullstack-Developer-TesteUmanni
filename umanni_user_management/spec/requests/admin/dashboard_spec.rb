require 'rails_helper'

RSpec.describe 'Admin Dashboard', type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }

  describe 'GET /admin/dashboard' do
    context 'when user is an admin' do
      before do
        sign_in admin_user
        create(:user, :admin)
        create_list(:user, 5)
        create_list(:import_job, 3, user: admin_user)
      end

      it 'returns 200 OK' do
        get admin_dashboard_path
        expect(response).to have_http_status(:ok)
      end

      it 'renders the dashboard index view' do
        get admin_dashboard_path
        expect(response).to render_template(:index)
      end

      it 'assigns total_users' do
        get admin_dashboard_path
        expect(assigns(:total_users)).to eq(User.count)
      end

      it 'assigns total_admins' do
        get admin_dashboard_path
        expect(assigns(:total_admins)).to eq(User.where(role: :admin).count)
      end

      it 'assigns total_regular_users' do
        get admin_dashboard_path
        expect(assigns(:total_regular_users)).to eq(User.where(role: :user).count)
      end

      it 'assigns recent_imports limited to 10' do
        get admin_dashboard_path
        expect(assigns(:recent_imports).count).to be <= 10
      end

      it 'assigns recent_users limited to 10' do
        get admin_dashboard_path
        expect(assigns(:recent_users).count).to be <= 10
      end

      it 'displays dashboard content' do
        get admin_dashboard_path
        expect(response.body).to include('Dashboard')
      end
    end

    context 'when user is a regular user' do
      before do
        sign_in regular_user
      end

      it 'returns 403 Forbidden' do
        get admin_dashboard_path
        expect(response).to have_http_status(:forbidden)
      end

      it 'does not render the dashboard' do
        get admin_dashboard_path
        expect(response.body).not_to include('total_users')
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        get admin_dashboard_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'Dashboard statistics' do
    context 'with multiple users and admin statuses' do
      before do
        sign_in admin_user
        create(:user, :admin)
        create_list(:user, 8) # 8 regular users
      end

      it 'shows correct user counts' do
        get admin_dashboard_path

        # admin_user + 1 created admin + 8 regular users = 10 total
        expect(assigns(:total_users)).to eq(10)
        expect(assigns(:total_admins)).to eq(2)
        expect(assigns(:total_regular_users)).to eq(8)
      end
    end

    context 'with import jobs' do
      before do
        sign_in admin_user
        create(:import_job, :completed, user: admin_user)
        create(:import_job, :processing, user: admin_user)
        create(:import_job, :failed, user: admin_user)
      end

      it 'retrieves recent import jobs' do
        get admin_dashboard_path
        recent_imports = assigns(:recent_imports)

        expect(recent_imports.count).to eq(3)
        expect(recent_imports.map(&:status)).to include('completed', 'processing', 'failed')
      end
    end
  end
end
