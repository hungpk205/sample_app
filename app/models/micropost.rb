class Micropost < ApplicationRecord
  belongs_to :user
  # default_scope ->{order(created_at: :desc)}
  mount_uploader :picture, PictureUploader
  validates :user_id, presence: true
  validates :content, presence: true,
    length: {maximum: Settings.microposts.content.length}
  validate :picture_size
  scope :sort_created, ->{order created_at: :desc}

  private
  def picture_size
    return unless picture.size > Settings.image.size.megabytes
    errors.add(:picture, t(".over_size_image"))
  end
end
