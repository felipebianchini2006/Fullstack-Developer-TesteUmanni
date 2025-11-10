class ImportJob < ApplicationRecord
  belongs_to :user

  # Enum for status
  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }, default: :pending

  # Validations
  validates :file_name, presence: true
  validates :status, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) if status.present? }

  # Progress percentage
  def progress_percentage
    return 0 if total_records.zero?
    ((processed_records.to_f / total_records) * 100).round(2)
  end

  # Check if completed
  def completed?
    status == "completed"
  end

  # Check if failed
  def failed?
    status == "failed"
  end

  # Check if processing
  def processing?
    status == "processing"
  end
end
