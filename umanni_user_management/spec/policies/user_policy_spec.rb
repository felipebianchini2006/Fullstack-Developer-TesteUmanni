require 'rails_helper'

RSpec.describe UserPolicy, type: :policy do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let(:other_user) { create(:user) }

  subject { UserPolicy.new(user, record) }

  describe '#index?' do
    context 'when user is an admin' do
      let(:user) { admin_user }
      let(:record) { User.new }

      it { is_expected.to permit(:index) }
    end

    context 'when user is a regular user' do
      let(:user) { regular_user }
      let(:record) { User.new }

      it { is_expected.to forbid(:index) }
    end

    context 'when user is not authenticated' do
      let(:user) { nil }
      let(:record) { User.new }

      it { is_expected.to forbid(:index) }
    end
  end

  describe '#show?' do
    context 'when user is an admin' do
      let(:user) { admin_user }
      let(:record) { other_user }

      it { is_expected.to permit(:show) }
    end

    context 'when user is viewing their own profile' do
      let(:user) { regular_user }
      let(:record) { regular_user }

      it { is_expected.to permit(:show) }
    end

    context 'when user is a regular user viewing another user' do
      let(:user) { regular_user }
      let(:record) { other_user }

      it { is_expected.to forbid(:show) }
    end

    context 'when user is not authenticated' do
      let(:user) { nil }
      let(:record) { regular_user }

      it { is_expected.to forbid(:show) }
    end
  end

  describe '#create?' do
    context 'when user is an admin' do
      let(:user) { admin_user }
      let(:record) { User.new }

      it { is_expected.to permit(:create) }
    end

    context 'when user is a regular user' do
      let(:user) { regular_user }
      let(:record) { User.new }

      it { is_expected.to forbid(:create) }
    end

    context 'when user is not authenticated' do
      let(:user) { nil }
      let(:record) { User.new }

      it { is_expected.to forbid(:create) }
    end
  end

  describe '#update?' do
    context 'when user is an admin updating another user' do
      let(:user) { admin_user }
      let(:record) { other_user }

      it { is_expected.to permit(:update) }
    end

    context 'when user is updating their own profile' do
      let(:user) { regular_user }
      let(:record) { regular_user }

      it { is_expected.to permit(:update) }
    end

    context 'when user is a regular user trying to update another user' do
      let(:user) { regular_user }
      let(:record) { other_user }

      it { is_expected.to forbid(:update) }
    end

    context 'when user is not authenticated' do
      let(:user) { nil }
      let(:record) { other_user }

      it { is_expected.to forbid(:update) }
    end
  end

  describe '#destroy?' do
    context 'when user is an admin destroying another user' do
      let(:user) { admin_user }
      let(:record) { other_user }

      it { is_expected.to permit(:destroy) }
    end

    context 'when user is destroying their own account' do
      let(:user) { regular_user }
      let(:record) { regular_user }

      it { is_expected.to permit(:destroy) }
    end

    context 'when user is a regular user trying to destroy another user' do
      let(:user) { regular_user }
      let(:record) { other_user }

      it { is_expected.to forbid(:destroy) }
    end

    context 'when user is not authenticated' do
      let(:user) { nil }
      let(:record) { regular_user }

      it { is_expected.to forbid(:destroy) }
    end

    context 'when trying to destroy the last admin' do
      let(:user) { admin_user }
      let(:record) { admin_user }

      before do
        # Create a scenario where this admin is the only admin
        User.where(role: :admin).where.not(id: admin_user.id).destroy_all
      end

      it 'prevents destruction of the last admin' do
        expect(subject.destroy?).to be false
      end
    end

    context 'when there are multiple admins' do
      let(:user) { admin_user }
      let(:record) { admin_user }

      before do
        create(:user, :admin)
      end

      it 'allows an admin to destroy themselves' do
        expect(subject.destroy?).to be true
      end
    end
  end

  describe '#toggle_role?' do
    context 'when user is an admin toggling another user' do
      let(:user) { admin_user }
      let(:record) { other_user }

      it { is_expected.to permit(:toggle_role) }
    end

    context 'when user is trying to toggle their own role' do
      let(:user) { admin_user }
      let(:record) { admin_user }

      it { is_expected.to forbid(:toggle_role) }
    end

    context 'when user is a regular user' do
      let(:user) { regular_user }
      let(:record) { other_user }

      it { is_expected.to forbid(:toggle_role) }
    end

    context 'when user is not authenticated' do
      let(:user) { nil }
      let(:record) { other_user }

      it { is_expected.to forbid(:toggle_role) }
    end
  end

  describe '#import?' do
    context 'when user is an admin' do
      let(:user) { admin_user }
      let(:record) { User.new }

      it { is_expected.to permit(:import) }
    end

    context 'when user is a regular user' do
      let(:user) { regular_user }
      let(:record) { User.new }

      it { is_expected.to forbid(:import) }
    end

    context 'when user is not authenticated' do
      let(:user) { nil }
      let(:record) { User.new }

      it { is_expected.to forbid(:import) }
    end
  end

  describe 'Scope' do
    let(:user) { regular_user }
    let(:scope) { UserPolicy::Scope.new(user, User.all) }

    context 'when user is an admin' do
      let(:user) { admin_user }

      it 'returns all users' do
        expect(scope.resolve).to include(admin_user, regular_user, other_user)
      end
    end

    context 'when user is a regular user' do
      it 'returns only the current user' do
        expect(scope.resolve).to eq([regular_user])
      end
    end

    context 'when user is not authenticated' do
      let(:user) { nil }

      it 'returns no users' do
        expect(scope.resolve).to be_empty
      end
    end
  end
end
