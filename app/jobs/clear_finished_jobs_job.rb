class ClearFinishedJobsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    SolidQueue::Job.clear_finished_in_batches
  end
end
