class Note < ApplicationRecord
  belongs_to :user
  has_many :note_points, dependent: :destroy
  has_many :note_taggings, dependent: :destroy
  has_many :note_tags, through: :note_taggings

  default_scope { order(:order, updated_at: :desc) }

  before_create :assign_default_order

  def root_points
    note_points.where(parent_id: nil)
  end

  def self.insert_between(prev_order, next_order)
    (prev_order + next_order) / 2
  end

  private

  def assign_default_order
    max_order = user.notes.unscoped.where(user_id: user_id).maximum(:order) || 0
    self.order = max_order + 1000
  end
end
