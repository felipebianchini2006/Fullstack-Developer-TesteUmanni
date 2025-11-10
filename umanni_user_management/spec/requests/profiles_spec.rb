require 'rails_helper'

RSpec.describe 'User Profiles', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe 'GET /profile (show)' do
    context 'when user is authenticated' do
      before do
        sign_in user
      end

      it 'returns 200 OK' do
        get profile_path
        expect(response).to have_http_status(:ok)
      end

      it 'renders the show view' do
        get profile_path
        expect(response).to render_template(:show)
      end

      it 'assigns current user' do
        get profile_path
        expect(assigns(:user)).to eq(user)
      end

      it 'displays user full name' do
        get profile_path
        expect(response.body).to include(user.full_name)
      end

      it 'displays user email' do
        get profile_path
        expect(response.body).to include(user.email)
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        get profile_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /profile/edit (edit)' do
    context 'when user is authenticated' do
      before do
        sign_in user
      end

      it 'returns 200 OK' do
        get edit_profile_path
        expect(response).to have_http_status(:ok)
      end

      it 'renders the edit view' do
        get edit_profile_path
        expect(response).to render_template(:edit)
      end

      it 'assigns current user' do
        get edit_profile_path
        expect(assigns(:user)).to eq(user)
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        get edit_profile_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /profile (update)' do
    context 'when user is authenticated' do
      before do
        sign_in user
      end

      context 'with valid parameters' do
        let(:update_params) do
          {
            user: {
              full_name: 'Updated Name',
              email: user.email
            }
          }
        end

        it 'updates the user' do
          patch profile_path, params: update_params
          user.reload
          expect(user.full_name).to eq('Updated Name')
        end

        it 'redirects to profile path' do
          patch profile_path, params: update_params
          expect(response).to redirect_to(profile_path)
        end

        it 'displays a success notice' do
          patch profile_path, params: update_params
          expect(response).to have_http_status(:redirect)
          follow_redirect!
          expect(response.body).to include('Profile was successfully updated')
        end
      end

      context 'with invalid parameters' do
        let(:invalid_params) do
          {
            user: {
              full_name: '',
              email: user.email
            }
          }
        end

        it 'does not update the user' do
          patch profile_path, params: invalid_params
          user.reload
          expect(user.full_name).not_to eq('')
        end

        it 'returns 422 Unprocessable Entity' do
          patch profile_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 're-renders the edit view' do
          patch profile_path, params: invalid_params
          expect(response).to render_template(:edit)
        end
      end

      context 'with blank password fields' do
        let(:update_params) do
          {
            user: {
              full_name: 'Updated Name',
              email: user.email,
              password: '',
              password_confirmation: ''
            }
          }
        end

        it 'updates user without changing password' do
          original_encrypted_password = user.encrypted_password
          patch profile_path, params: update_params
          user.reload
          expect(user.encrypted_password).to eq(original_encrypted_password)
        end

        it 'redirects to profile' do
          patch profile_path, params: update_params
          expect(response).to redirect_to(profile_path)
        end
      end

      context 'with valid password' do
        let(:update_params) do
          {
            user: {
              full_name: user.full_name,
              email: user.email,
              password: 'newpassword123',
              password_confirmation: 'newpassword123'
            }
          }
        end

        it 'updates the password' do
          patch profile_path, params: update_params
          user.reload
          expect(user.valid_password?('newpassword123')).to be true
        end
      end

      context 'with avatar image' do
        it 'attaches avatar image' do
          avatar = File.open(Rails.root.join('spec', 'fixtures', 'files', 'test_avatar.png'))
          update_params = {
            user: {
              full_name: user.full_name,
              email: user.email,
              avatar_image: avatar
            }
          }
          patch profile_path, params: update_params
          user.reload
          expect(user.avatar_image.attached?).to be true
          avatar.close
        end
      end

      context 'updating email to another user email' do
        let(:duplicate_params) do
          {
            user: {
              full_name: user.full_name,
              email: other_user.email
            }
          }
        end

        it 'does not update email' do
          patch profile_path, params: duplicate_params
          user.reload
          expect(user.email).not_to eq(other_user.email)
        end

        it 'returns 422 Unprocessable Entity' do
          patch profile_path, params: duplicate_params
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        patch profile_path, params: { user: attributes_for(:user) }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /profile (destroy)' do
    context 'when user is authenticated' do
      before do
        sign_in user
      end

      it 'deletes the user account' do
        user_id = user.id
        delete profile_path
        expect(User.find_by(id: user_id)).to be_nil
      end

      it 'redirects to root path' do
        delete profile_path
        expect(response).to redirect_to(root_path)
      end

      it 'displays a success notice' do
        delete profile_path
        expect(response).to have_http_status(:redirect)
        follow_redirect!
        expect(response.body).to include('Your account has been successfully deleted')
      end

      it 'signs out the user' do
        delete profile_path
        expect(controller.current_user).to be_nil
      end

      context 'when user has avatar' do
        before do
          user.avatar_image.attach(
            io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'test_avatar.png')),
            filename: 'test_avatar.png',
            content_type: 'image/png'
          )
        end

        it 'deletes the avatar' do
          delete profile_path
          expect(ActiveStorage::Attachment.find_by(record_type: 'User', record_id: user.id)).to be_nil
        end
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        delete profile_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'Authorization' do
    context 'when user can manage their own profile' do
      before do
        sign_in user
      end

      it 'allows access to own profile' do
        get profile_path
        expect(response).to have_http_status(:ok)
      end

      it 'allows editing own profile' do
        get edit_profile_path
        expect(response).to have_http_status(:ok)
      end

      it 'allows updating own profile' do
        patch profile_path, params: { user: { full_name: 'New Name' } }
        expect(response).to have_http_status(:redirect)
      end

      it 'allows deleting own profile' do
        delete profile_path
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe 'Profile information display' do
    before do
      sign_in user
    end

    it 'displays user full name in show view' do
      get profile_path
      expect(response.body).to include(user.full_name)
    end

    it 'displays user email in show view' do
      get profile_path
      expect(response.body).to include(user.email)
    end

    it 'displays role information' do
      user.update(role: :admin)
      get profile_path
      expect(response.body).to include('admin')
    end
  end
end
