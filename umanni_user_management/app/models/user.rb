class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Active Storage for avatar
  has_one_attached :avatar_image

  # Enum for role
  enum :role, { user: 0, admin: 1 }, default: :user

  # Validations
  validates :full_name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :email, presence: true, uniqueness: true
  validates :avatar_image, content_type: { in: ['image/png', 'image/jpeg', 'image/gif'],
                                           message: 'must be a valid image format' },
                           size: { less_than: 5.megabytes,
                                   message: 'should be less than 5MB' },
                           allow_nil: true

  # Methods
  def admin?
    role == 'admin'
  end

  def user?
    role == 'user'
  end
end
