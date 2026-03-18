class CreateUserOauths < ActiveRecord::Migration[8.0]
  def change
    create_table :user_oauths do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :uid, null: false
      t.string :email
      t.string :name

      t.timestamps
    end

    add_index :user_oauths, %i[provider uid], unique: true
    add_index :user_oauths, %i[user_id provider], unique: true
  end
end
