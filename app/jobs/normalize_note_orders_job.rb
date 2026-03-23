class NormalizeNoteOrdersJob < ApplicationJob
  queue_as :default

  def perform
    User.find_each do |user|
      notes = user.notes.reorder(:order).to_a
      notes.each_with_index do |note, i|
        new_order = (i + 1) * 1000
        note.update_column(:order, new_order) if note.order != new_order
      end
    end
  end
end
