class AddStatusAndPublishedAtToArticles < ActiveRecord::Migration[6.1]
  def change
    add_column :articles, :status, :integer, default: 0, null: false
    add_column :articles, :published_at, :datetime

    add_index :articles, :status
    add_index :articles, :published_at
  end
end
