class User < ApplicationRecord
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  attr_accessor :remember_token

  before_save{email.downcase!}
  has_secure_password
  validates :name,
    length: {maximum: Settings.users.name.max_length},
    presence: true
  validates :email,
    format: {with: VALID_EMAIL_REGEX},
    length: {maximum: Settings.users.email.max_length},
    presence: true,
    uniqueness: {case_sensitive: false}
  validates :password,
    length: {minimum: Settings.users.password.min_length},
    presence: true,
    allow_nil: true

  class << self
    def digest string
      cost = if ActiveModel::SecurePassword.min_cost
               BCrypt::Engine::MIN_COST
             else
               BCrypt::Engine.cost
             end
      BCrypt::Password.create string, cost: cost
    end

    def new_token
      SecureRandom.urlsafe_base64
    end
  end

  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  def authenticated? remember_token
    return false unless remember_digest
    BCrypt::Password.new(remember_digest).is_password?(remember_token)
  end

  def forget
    update_attribute :remember_digest, nil
  end
end
