require 'rails_helper'

RSpec.describe 'Admin Users Management', type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let(:other_user) { create(:user) }

  describe 'GET /admin/users (index)' do
    context 'when user is an admin' do
      before do
        sign_in admin_user
        create_list(:user, 25)
      end

      it 'returns 200 OK' do
        get admin_users_path
        expect(response).to have_http_status(:ok)
      end

      it 'renders the index view' do
        get admin_users_path
        expect(response).to render_template(:index)
      end

      it 'assigns paginated users' do
        get admin_users_path
        expect(assigns(:users)).not_to be_nil
        expect(assigns(:pagy)).not_to be_nil
      end

      it 'paginates users with 20 per page' do
        get admin_users_path
        # 1 admin_user + 25 created users = 26 total
        expect(assigns(:users).count).to be <= 20
      end

      it 'orders users by created_at descending' do
        get admin_users_path
        users = assigns(:users)
        expect(users).to eq(users.sort_by(&:created_at).reverse)
      end
    end

    context 'when user is a regular user' do
      before do
        sign_in regular_user
      end

      it 'returns 403 Forbidden' do
        get admin_users_path
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        get admin_users_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /admin/users/:id (show)' do
    context 'when user is an admin' do
      before do
        sign_in admin_user
      end

      it 'returns 200 OK' do
        get admin_user_path(other_user)
        expect(response).to have_http_status(:ok)
      end

      it 'renders the show view' do
        get admin_user_path(other_user)
        expect(response).to render_template(:show)
      end

      it 'assigns the correct user' do
        get admin_user_path(other_user)
        expect(assigns(:user)).to eq(other_user)
      end
    end

    context 'when user does not exist' do
      before do
        sign_in admin_user
      end

      it 'returns 404 Not Found' do
        get admin_user_path(999)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET /admin/users/new (new)' do
    context 'when user is an admin' do
      before do
        sign_in admin_user
      end

      it 'returns 200 OK' do
        get new_admin_user_path
        expect(response).to have_http_status(:ok)
      end

      it 'renders the new view' do
        get new_admin_user_path
        expect(response).to render_template(:new)
      end

      it 'assigns a new user' do
        get new_admin_user_path
        expect(assigns(:user)).to be_a_new(User)
      end
    end
  end

  describe 'POST /admin/users (create)' do
    context 'when user is an admin' do
      before do
        sign_in admin_user
      end

      context 'with valid parameters' do
        let(:user_params) do
          {
            user: {
              full_name: 'New User',
              email: 'newuser@example.com',
              password: 'password123',
              password_confirmation: 'password123',
              role: :user
            }
          }
        end

        it 'creates a new user' do
          expect {
            post admin_users_path, params: user_params
          }.to change(User, :count).by(1)
        end

        it 'redirects to users index' do
          post admin_users_path, params: user_params
          expect(response).to redirect_to(admin_users_path)
        end

        it 'displays a success notice' do
          post admin_users_path, params: user_params
          expect(response).to have_http_status(:redirect)
          follow_redirect!
          expect(response.body).to include('User was successfully created')
        end

        it 'broadcasts user creation to Action Cable' do
          expect(ActionCable.server).to receive(:broadcast).with('dashboard_channel', hash_including(event: 'user_created'))
          post admin_users_path, params: user_params
        end

        context 'creating an admin user' do
          it 'creates user with admin role' do
            params = user_params
            params[:user][:role] = :admin
            post admin_users_path, params: params
            new_user = User.find_by(email: 'newuser@example.com')
            expect(new_user.admin?).to be true
          end
        end
      end

      context 'with invalid parameters' do
        let(:invalid_params) do
          {
            user: {
              full_name: '',
              email: '',
              password: 'password123',
              password_confirmation: 'password123'
            }
          }
        end

        it 'does not create a user' do
          expect {
            post admin_users_path, params: invalid_params
          }.not_to change(User, :count)
        end

        it 'returns 422 Unprocessable Entity' do
          post admin_users_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 're-renders the new view' do
          post admin_users_path, params: invalid_params
          expect(response).to render_template(:new)
        end
      end

      context 'with duplicate email' do
        let(:duplicate_params) do
          {
            user: {
              full_name: 'Another User',
              email: other_user.email,
              password: 'password123',
              password_confirmation: 'password123'
            }
          }
        end

        it 'does not create a user' do
          expect {
            post admin_users_path, params: duplicate_params
          }.not_to change(User, :count)
        end

        it 'returns 422 Unprocessable Entity' do
          post admin_users_path, params: duplicate_params
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context 'when user is not an admin' do
      before do
        sign_in regular_user
      end

      it 'returns 403 Forbidden' do
        post admin_users_path, params: { user: attributes_for(:user) }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'GET /admin/users/:id/edit (edit)' do
    context 'when user is an admin' do
      before do
        sign_in admin_user
      end

      it 'returns 200 OK' do
        get edit_admin_user_path(other_user)
        expect(response).to have_http_status(:ok)
      end

      it 'renders the edit view' do
        get edit_admin_user_path(other_user)
        expect(response).to render_template(:edit)
      end

      it 'assigns the correct user' do
        get edit_admin_user_path(other_user)
        expect(assigns(:user)).to eq(other_user)
      end
    end
  end

  describe 'PATCH /admin/users/:id (update)' do
    context 'when user is an admin' do
      before do
        sign_in admin_user
      end

      context 'with valid parameters' do
        let(:update_params) do
          {
            user: {
              full_name: 'Updated Name',
              email: other_user.email
            }
          }
        end

        it 'updates the user' do
          patch admin_user_path(other_user), params: update_params
          other_user.reload
          expect(other_user.full_name).to eq('Updated Name')
        end

        it 'redirects to users index' do
          patch admin_user_path(other_user), params: update_params
          expect(response).to redirect_to(admin_users_path)
        end

        it 'displays a success notice' do
          patch admin_user_path(other_user), params: update_params
          expect(response).to have_http_status(:redirect)
          follow_redirect!
          expect(response.body).to include('User was successfully updated')
        end
      end

      context 'with invalid parameters' do
        let(:invalid_params) do
          {
            user: {
              full_name: '',
              email: other_user.email
            }
          }
        end

        it 'does not update the user' do
          patch admin_user_path(other_user), params: invalid_params
          other_user.reload
          expect(other_user.full_name).not_to eq('')
        end

        it 'returns 422 Unprocessable Entity' do
          patch admin_user_path(other_user), params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 're-renders the edit view' do
          patch admin_user_path(other_user), params: invalid_params
          expect(response).to render_template(:edit)
        end
      end

      context 'with blank password fields' do
        let(:update_params) do
          {
            user: {
              full_name: 'Updated Name',
              email: other_user.email,
              password: '',
              password_confirmation: ''
            }
          }
        end

        it 'updates user without changing password' do
          original_encrypted_password = other_user.encrypted_password
          patch admin_user_path(other_user), params: update_params
          other_user.reload
          expect(other_user.encrypted_password).to eq(original_encrypted_password)
        end
      end
    end

    context 'when user is not an admin' do
      before do
        sign_in regular_user
      end

      it 'returns 403 Forbidden' do
        patch admin_user_path(other_user), params: { user: attributes_for(:user) }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE /admin/users/:id (destroy)' do
    context 'when user is an admin' do
      before do
        sign_in admin_user
        create(:user, :admin) # Ensure there are multiple admins
      end

      let!(:user_to_delete) { create(:user) }

      context 'when deleting a regular user' do
        it 'deletes the user' do
          expect {
            delete admin_user_path(user_to_delete)
          }.to change(User, :count).by(-1)
        end

        it 'redirects to users index' do
          delete admin_user_path(user_to_delete)
          expect(response).to redirect_to(admin_users_path)
        end

        it 'displays a success notice' do
          delete admin_user_path(user_to_delete)
          expect(response).to have_http_status(:redirect)
          follow_redirect!
          expect(response.body).to include('User was successfully deleted')
        end

        it 'broadcasts user deletion to Action Cable' do
          expect(ActionCable.server).to receive(:broadcast).with('dashboard_channel', hash_including(event: 'user_deleted'))
          delete admin_user_path(user_to_delete)
        end
      end

      context 'when deleting the last admin' do
        it 'does not delete the last admin' do
          # Remove the extra admin created in before block
          User.where(role: :admin).where.not(id: admin_user.id).destroy_all

          expect {
            delete admin_user_path(admin_user)
          }.not_to change(User, :count)
        end

        it 'redirects with an alert' do
          User.where(role: :admin).where.not(id: admin_user.id).destroy_all
          delete admin_user_path(admin_user)
          expect(response).to redirect_to(admin_users_path)
        end
      end
    end

    context 'when user is not an admin' do
      before do
        sign_in regular_user
      end

      it 'returns 403 Forbidden' do
        delete admin_user_path(other_user)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'PATCH /admin/users/:id/toggle_role (toggle_role)' do
    context 'when user is an admin' do
      before do
        sign_in admin_user
        create(:user, :admin) # Ensure there are multiple admins
      end

      context 'toggling a regular user to admin' do
        it 'updates user role to admin' do
          patch admin_user_toggle_role_path(regular_user)
          regular_user.reload
          expect(regular_user.admin?).to be true
        end

        it 'redirects to users index' do
          patch admin_user_toggle_role_path(regular_user)
          expect(response).to redirect_to(admin_users_path)
        end

        it 'displays a success notice' do
          patch admin_user_toggle_role_path(regular_user)
          expect(response).to have_http_status(:redirect)
          follow_redirect!
          expect(response.body).to include('User role was successfully updated')
        end

        it 'broadcasts role change to Action Cable' do
          expect(ActionCable.server).to receive(:broadcast).with('dashboard_channel', hash_including(event: 'user_role_changed'))
          patch admin_user_toggle_role_path(regular_user)
        end
      end

      context 'toggling an admin to regular user' do
        let!(:another_admin) { create(:user, :admin) }

        it 'updates user role to user' do
          patch admin_user_toggle_role_path(another_admin)
          another_admin.reload
          expect(another_admin.user?).to be true
        end
      end

      context 'trying to toggle admin user to regular' do
        it 'updates the role successfully' do
          create(:user, :admin) # Ensure multiple admins exist
          patch admin_user_toggle_role_path(admin_user)
          admin_user.reload
          expect(admin_user.user?).to be true
        end
      end

      context 'when update fails' do
        before do
          allow_any_instance_of(User).to receive(:update).and_return(false)
        end

        it 'redirects with alert' do
          patch admin_user_toggle_role_path(regular_user)
          expect(response).to redirect_to(admin_users_path)
        end
      end
    end

    context 'when user tries to toggle own role' do
      before do
        sign_in admin_user
      end

      it 'returns 403 Forbidden' do
        patch admin_user_toggle_role_path(admin_user)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when user is not an admin' do
      before do
        sign_in regular_user
      end

      it 'returns 403 Forbidden' do
        patch admin_user_toggle_role_path(other_user)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'GET /admin/users/import (import form)' do
    context 'when user is an admin' do
      before do
        sign_in admin_user
      end

      it 'returns 200 OK' do
        get import_admin_users_path
        expect(response).to have_http_status(:ok)
      end

      it 'renders the import view' do
        get import_admin_users_path
        expect(response).to render_template(:import)
      end
    end

    context 'when user is not an admin' do
      before do
        sign_in regular_user
      end

      it 'returns 403 Forbidden' do
        get import_admin_users_path
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST /admin/users/process_import (process_import)' do
    context 'when user is an admin' do
      before do
        sign_in admin_user
      end

      context 'with a valid file' do
        let(:valid_file) do
          temp_file = Tempfile.new(['import', '.xlsx'], Rails.root.join('tmp'))
          temp_file.write('dummy xlsx content for testing')
          temp_file.rewind
          ActionDispatch::Http::UploadedFile.new(
            tempfile: temp_file,
            filename: 'users_import.xlsx',
            type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
          )
        end

        it 'creates an ImportJob' do
          expect {
            post process_import_admin_users_path, params: { file: valid_file }
          }.to change(ImportJob, :count)
        end

        it 'enqueues UserImportJob' do
          expect(UserImportJob).to receive(:perform_async)
          post process_import_admin_users_path, params: { file: valid_file }
        end

        it 'redirects to admin dashboard' do
          post process_import_admin_users_path, params: { file: valid_file }
          expect(response).to redirect_to(admin_dashboard_path)
        end

        it 'displays a success notice' do
          post process_import_admin_users_path, params: { file: valid_file }
          expect(response).to have_http_status(:redirect)
          follow_redirect!
          expect(response.body).to include('Import started')
        end
      end

      context 'without a file' do
        it 'does not create an ImportJob' do
          expect {
            post process_import_admin_users_path, params: { file: nil }
          }.not_to change(ImportJob, :count)
        end

        it 'redirects to import form' do
          post process_import_admin_users_path, params: { file: nil }
          expect(response).to redirect_to(import_admin_users_path)
        end

        it 'displays an alert' do
          post process_import_admin_users_path, params: { file: nil }
          expect(response).to have_http_status(:redirect)
          follow_redirect!
          expect(response.body).to include('Please select a file')
        end
      end
    end

    context 'when user is not an admin' do
      before do
        sign_in regular_user
      end

      it 'returns 403 Forbidden' do
        temp_file = Tempfile.new(['import', '.xlsx'], Rails.root.join('tmp'))
        temp_file.write('dummy xlsx content for testing')
        temp_file.rewind
        file = ActionDispatch::Http::UploadedFile.new(
          tempfile: temp_file,
          filename: 'users_import.xlsx',
          type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        )
        post process_import_admin_users_path, params: { file: file }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
