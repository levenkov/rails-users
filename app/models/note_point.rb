class NotePoint < ApplicationRecord
  belongs_to :note
  belongs_to :parent, class_name: "NotePoint", optional: true
  has_many :children, class_name: "NotePoint", foreign_key: :parent_id, dependent: :destroy

  scope :roots, -> { where(parent_id: nil) }

  default_scope { order(:position) }
end
