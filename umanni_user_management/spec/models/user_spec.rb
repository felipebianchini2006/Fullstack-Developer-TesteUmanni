require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:full_name) }
    it { should validate_length_of(:full_name).is_at_least(2).is_at_most(100) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:password) }
    it { should validate_length_of(:password).is_at_least(6) }

    describe 'avatar_image validations' do
      it 'is valid with a valid image format' do
        user = build(:user)
        user.avatar_image.attach(
          io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'test_avatar.png')),
          filename: 'test_avatar.png',
          content_type: 'image/png'
        )
        expect(user).to be_valid
      end

      it 'is invalid with an invalid image format' do
        user = build(:user)
        user.avatar_image.attach(
          io: StringIO.new('fake pdf content'),
          filename: 'test.pdf',
          content_type: 'application/pdf'
        )
        expect(user).not_to be_valid
        expect(user.errors[:avatar_image]).to include('must be a valid image format')
      end

      it 'is invalid with a file larger than 5MB' do
        user = build(:user)
        large_file = StringIO.new('x' * 6.megabytes)
        user.avatar_image.attach(
          io: large_file,
          filename: 'large.png',
          content_type: 'image/png'
        )
        expect(user).not_to be_valid
        expect(user.errors[:avatar_image]).to include('should be less than 5MB')
      end

      it 'is valid without avatar_image' do
        user = build(:user)
        expect(user).to be_valid
      end
    end
  end

  describe 'associations' do
    it 'has one attached avatar_image' do
      expect(User.new.avatar_image).to be_an_instance_of(ActiveStorage::Attached::One)
    end
  end

  describe 'enums' do
    it { should define_enum_for(:role).with_values(user: 0, admin: 1) }
  end

  describe '#admin?' do
    it 'returns true for admin users' do
      admin = build(:user, :admin)
      expect(admin.admin?).to be true
    end

    it 'returns false for regular users' do
      user = build(:user)
      expect(user.admin?).to be false
    end
  end

  describe '#user?' do
    it 'returns true for regular users' do
      user = build(:user)
      expect(user.user?).to be true
    end

    it 'returns false for admin users' do
      admin = build(:user, :admin)
      expect(admin.user?).to be false
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:user)).to be_valid
    end

    it 'has a valid admin factory' do
      expect(build(:user, :admin)).to be_valid
    end
  end

  describe 'devise modules' do
    it 'is database authenticatable' do
      expect(User.new).to respond_to(:email)
      expect(User.new).to respond_to(:encrypted_password)
    end

    it 'is registerable' do
      expect(User.new).to respond_to(:password)
      expect(User.new).to respond_to(:password_confirmation)
    end

    it 'is recoverable' do
      expect(User.new).to respond_to(:reset_password_token)
      expect(User.new).to respond_to(:reset_password_sent_at)
    end

    it 'is rememberable' do
      expect(User.new).to respond_to(:remember_created_at)
    end

    it 'is validatable' do
      user = build(:user, email: 'invalid')
      expect(user).not_to be_valid
    end
  end
end
