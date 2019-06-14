class User < ApplicationRecord
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  attr_accessor :remember_token, :activation_token, :reset_token
  before_save :downcase_email
  before_create :create_activation_digest

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
  scope :activated, ->{where activated: true}
  has_many :microposts, dependent: :destroy

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

  def authenticated? attribute, token
    digest = send("#{attribute}_digest")
    return false unless digest
    BCrypt::Password.new(digest).is_password?(token)
  end

  def activate
    update_columns(activated: true, activated_at: Time.zone.now)
  end

  def create_reset_digest
    self.reset_token = User.new_token
    update_columns reset_digest: User.digest(reset_token),
      reset_sent_at: Time.zone.now
  end

  def create_activation_digest
    self.activation_token = User.new_token
    self.activation_digest = User.digest(activation_token)
  end

  def downcase_email
    email.downcase!
  end

  def feed
    self.microposts.sort_created
  end

  def forget
    update_attribute :remember_digest, nil
  end

  def password_reset_expired?
    reset_sent_at < Settings.expirate_hour.hours.ago
  end

  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end
end
