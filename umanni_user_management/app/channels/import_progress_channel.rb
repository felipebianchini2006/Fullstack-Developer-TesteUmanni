class ImportProgressChannel < ApplicationCable::Channel
  def subscribed
    import_job_id = params[:import_job_id]
    stream_from "import_progress_#{import_job_id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
