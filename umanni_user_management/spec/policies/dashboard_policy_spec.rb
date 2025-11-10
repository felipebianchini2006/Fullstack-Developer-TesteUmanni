require 'rails_helper'

RSpec.describe DashboardPolicy, type: :policy do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }

  subject { DashboardPolicy.new(user, :dashboard) }

  describe '#show?' do
    context 'when user is an admin' do
      let(:user) { admin_user }

      it { is_expected.to permit(:show) }
    end

    context 'when user is a regular user' do
      let(:user) { regular_user }

      it { is_expected.to forbid(:show) }
    end

    context 'when user is not authenticated' do
      let(:user) { nil }

      it { is_expected.to forbid(:show) }
    end
  end
end
