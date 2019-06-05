class User < ApplicationRecord
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
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
    presence: true
end
