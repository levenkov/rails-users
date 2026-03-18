class CreateSplitApprovals < ActiveRecord::Migration[8.0]
  def change
    create_table :split_approvals do |t|
      t.references :order, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :approved_at, null: false
      t.timestamps
    end
    add_index :split_approvals, %i[order_id user_id], unique: true
  end
end
