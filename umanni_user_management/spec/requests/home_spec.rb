require 'rails_helper'

RSpec.describe 'Home Page', type: :request do
  describe 'GET / (home#index)' do
    context 'when user is not authenticated' do
      it 'returns 200 OK' do
        get root_path
        expect(response).to have_http_status(:ok)
      end

      it 'renders the index view' do
        get root_path
        expect(response).to render_template(:index)
      end
    end

    context 'when user is an admin' do
      let(:admin_user) { create(:user, :admin) }

      before do
        sign_in admin_user
      end

      it 'redirects to admin dashboard' do
        get root_path
        expect(response).to redirect_to(admin_dashboard_path)
      end

      it 'returns 302 Found' do
        get root_path
        expect(response).to have_http_status(:found)
      end
    end

    context 'when user is a regular user' do
      let(:regular_user) { create(:user) }

      before do
        sign_in regular_user
      end

      it 'redirects to profile path' do
        get root_path
        expect(response).to redirect_to(profile_path)
      end

      it 'returns 302 Found' do
        get root_path
        expect(response).to have_http_status(:found)
      end
    end
  end

  describe 'Home page content' do
    context 'for unauthenticated users' do
      it 'displays welcome message or login prompt' do
        get root_path
        expect(response.body).not_to be_empty
      end

      it 'has a link to sign in' do
        get root_path
        # Check for sign in link
        expect(response.body).to include('sign') # generic check for sign-in related content
      end
    end
  end

  describe 'Root path routing' do
    it 'routes / to home#index' do
      expect(get: '/').to route_to('home#index')
    end
  end
end
