# == Schema Information
#
# Table name: articles
#
#  id           :bigint           not null, primary key
#  body         :text
#  published_at :datetime
#  status       :integer          default("draft"), not null
#  title        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_articles_on_published_at  (published_at)
#  index_articles_on_status        (status)
#  index_articles_on_user_id       (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Article < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :article_likes, dependent: :destroy

  enum status: { draft: 0, published: 1 }

  validates :title, length: { in: 1..75 }, if: :published?
  validates :body, length: { in: 1..200 }, if: :published?
  validates :title, presence: true, if: :draft?
  validates :body, presence: true, if: :draft?

  scope :published, -> { where(status: :published) }
  scope :draft, -> { where(status: :draft) }
  scope :by_user, ->(user) { where(user: user) }

  before_save :set_published_at, if: :status_changed_to_published?

  private

    def set_published_at
      self.published_at = Time.current
    end

    def status_changed_to_published?
      status_changed? && published?
    end
end
