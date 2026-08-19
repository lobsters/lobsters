class RenameIdleQueue < ActiveRecord::Migration[8.0]
  def up
    SolidQueue::Queue.find_by_name("idle").clear
    SolidQueue::ScheduledExecution.where(queue_name: "idle").discard_all_in_batches
  end

  def down
  end
end
