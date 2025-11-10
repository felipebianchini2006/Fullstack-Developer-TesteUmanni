require "roo"

class UserImportJob < ApplicationJob
  queue_as :default

  def perform(import_job_id, file_data)
    import_job = ImportJob.find(import_job_id)
    import_job.update!(status: :processing)

    begin
      # Parse file data
      temp_file = Tempfile.new(["import", ".xlsx"])
      temp_file.binmode
      temp_file.write(file_data)
      temp_file.rewind

      # Open spreadsheet
      spreadsheet = Roo::Spreadsheet.open(temp_file.path)
      headers = spreadsheet.row(1)

      # Validate headers
      required_headers = ["full_name", "email", "role"]
      missing_headers = required_headers - headers.map(&:downcase)

      if missing_headers.any?
        import_job.update!(
          status: :failed,
          error_messages: "Missing required columns: #{missing_headers.join(', ')}"
        )
        broadcast_completion(import_job)
        return
      end

      # Get column indices
      name_col = headers.index { |h| h.downcase == "full_name" }
      email_col = headers.index { |h| h.downcase == "email" }
      role_col = headers.index { |h| h.downcase == "role" }
      avatar_col = headers.index { |h| h&.downcase == "avatar_url" }

      total_records = spreadsheet.last_row - 1
      import_job.update!(total_records: total_records)

      errors = []
      processed = 0
      failed = 0

      # Process each row
      (2..spreadsheet.last_row).each do |row_num|
        row = spreadsheet.row(row_num)

        full_name = row[name_col]&.to_s&.strip
        email = row[email_col]&.to_s&.strip
        role = row[role_col]&.to_s&.strip&.downcase || "user"
        avatar_url = avatar_col ? row[avatar_col]&.to_s&.strip : nil

        # Validate role
        role = "user" unless ["admin", "user"].include?(role)

        # Create user
        user = User.new(
          full_name: full_name,
          email: email,
          role: role,
          password: SecureRandom.hex(8), # Generate random password
          password_confirmation: SecureRandom.hex(8)
        )

        # Attach avatar from URL if provided
        if avatar_url.present? && valid_url?(avatar_url)
          begin
            downloaded_image = URI.open(avatar_url)
            user.avatar_image.attach(io: downloaded_image, filename: "avatar_#{email}.jpg")
          rescue => e
            Rails.logger.error("Failed to download avatar for #{email}: #{e.message}")
          end
        end

        if user.save
          processed += 1
        else
          failed += 1
          errors << "Row #{row_num}: #{user.errors.full_messages.join(', ')}"
        end

        # Update progress
        import_job.update!(
          processed_records: processed,
          failed_records: failed
        )

        # Broadcast progress
        broadcast_progress(import_job)
      end

      # Update final status
      import_job.update!(
        status: failed.zero? ? :completed : :completed,
        error_messages: errors.join("\n")
      )

      # Broadcast completion
      broadcast_completion(import_job)

      # Broadcast user count update to dashboard
      ActionCable.server.broadcast("dashboard_channel", {
        event: "users_imported",
        total_users: User.count,
        total_admins: User.where(role: :admin).count,
        total_regular_users: User.where(role: :user).count
      })

    rescue => e
      import_job.update!(
        status: :failed,
        error_messages: "Import failed: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
      )
      broadcast_completion(import_job)
      raise e
    ensure
      temp_file.close
      temp_file.unlink
    end
  end

  private

  def valid_url?(url)
    uri = URI.parse(url)
    uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    false
  end

  def broadcast_progress(import_job)
    ActionCable.server.broadcast("import_progress_#{import_job.id}", {
      event: "progress",
      import_job_id: import_job.id,
      processed_records: import_job.processed_records,
      total_records: import_job.total_records,
      failed_records: import_job.failed_records,
      progress_percentage: import_job.progress_percentage,
      status: import_job.status
    })
  end

  def broadcast_completion(import_job)
    ActionCable.server.broadcast("import_progress_#{import_job.id}", {
      event: "completed",
      import_job_id: import_job.id,
      status: import_job.status,
      processed_records: import_job.processed_records,
      failed_records: import_job.failed_records,
      error_messages: import_job.error_messages
    })
  end
end
