class CreateArticleVariants < ActiveRecord::Migration[8.0]
  def change
    create_table :article_variants do |t|
      t.references :article, null: false, foreign_key: true
      t.string :name
      t.decimal :price, precision: 10, scale: 2, null: false

      t.timestamps
    end
  end
end
