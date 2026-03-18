class FinancialTransaction < ApplicationRecord
  belongs_to :sender, class_name: 'User'
  belongs_to :receiver, class_name: 'User'

  validates :amount, presence: true, numericality: { greater_than: 0 }

  after_commit :schedule_snapshot_invalidation, on: %i[create update destroy]

  private

  def schedule_snapshot_invalidation
    SnapshotInvalidationJob.perform_later(sender_id, receiver_id)
  end
end
