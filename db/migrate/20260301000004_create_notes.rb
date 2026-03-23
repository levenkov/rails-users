class CreateNotes < ActiveRecord::Migration[8.0]
  def change
    create_table :notes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.text :body
      t.integer :order, null: false, default: 0
      t.timestamps
    end

    add_index :notes, [:user_id, :order]

    create_table :note_points do |t|
      t.references :note, null: false, foreign_key: true
      t.references :parent, null: true, foreign_key: { to_table: :note_points }
      t.string :text, null: false
      t.boolean :checked, default: false, null: false
      t.integer :position, default: 0, null: false
      t.timestamps
    end

    create_table :note_tags do |t|
      t.string :name, null: false
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
    add_index :note_tags, [:user_id, :name], unique: true

    create_table :note_taggings do |t|
      t.references :note, null: false, foreign_key: true
      t.references :note_tag, null: false, foreign_key: true
      t.timestamps
    end
    add_index :note_taggings, [:note_id, :note_tag_id], unique: true
  end
end
