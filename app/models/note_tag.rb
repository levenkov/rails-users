class NoteTag < ApplicationRecord
  belongs_to :user
  has_many :note_taggings, dependent: :destroy
  has_many :notes, through: :note_taggings

  validates :name, presence: true, uniqueness: { scope: :user_id }
end
