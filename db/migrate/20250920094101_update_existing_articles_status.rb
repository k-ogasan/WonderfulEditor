class UpdateExistingArticlesStatus < ActiveRecord::Migration[6.1]
  def up
    # 既存の記事を全て公開記事として設定
    Article.where(status: nil).update_all(status: 1, published_at: Time.current)
  end

  def down
    # ロールバック時は何もしない（元の状態に戻せないため）
  end
end
