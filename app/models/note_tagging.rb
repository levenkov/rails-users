class NoteTagging < ApplicationRecord
  belongs_to :note
  belongs_to :note_tag
end
