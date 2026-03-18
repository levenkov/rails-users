class CreateArticles < ActiveRecord::Migration[8.0]
  def change
    create_table :articles do |t|
      t.references :market, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.boolean :unlimited, null: false, default: true
      t.integer :stock, null: false, default: 0

      t.timestamps
    end
  end
end
