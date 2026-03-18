class SnapshotInvalidationJob < ApplicationJob
  queue_as :default

  def perform(user_a_id, user_b_id)
    SnapshotRecalculationService.new(user_a_id, user_b_id).call
  end
end
