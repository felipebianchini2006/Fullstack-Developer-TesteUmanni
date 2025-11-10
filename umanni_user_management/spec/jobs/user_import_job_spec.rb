require 'rails_helper'

RSpec.describe UserImportJob, type: :job do
  include ActiveJob::TestHelper

  let(:admin_user) { create(:user, :admin) }
  let(:import_job) { create(:import_job, user: admin_user) }

  describe '#perform' do
    context 'with valid spreadsheet data' do
      let(:file_data) do
        # Create a valid XLSX file with proper headers
        require 'roo'
        temp_file = Tempfile.new(['users', '.xlsx'])
        workbook = RubyXL::Workbook.new
        worksheet = workbook[0]

        # Add headers
        worksheet.add_cell(0, 0, 'full_name')
        worksheet.add_cell(0, 1, 'email')
        worksheet.add_cell(0, 2, 'role')

        # Add user data
        worksheet.add_cell(1, 0, 'John Doe')
        worksheet.add_cell(1, 1, 'john@example.com')
        worksheet.add_cell(1, 2, 'user')

        worksheet.add_cell(2, 0, 'Jane Admin')
        worksheet.add_cell(2, 1, 'jane@example.com')
        worksheet.add_cell(2, 2, 'admin')

        workbook.write(temp_file.path)
        temp_file.close
        File.read(temp_file.path)
      end

      before do
        import_job.update(total_records: 2)
      end

      it 'marks import job as processing' do
        allow_any_instance_of(UserImportJob).to receive(:broadcast_progress)
        allow_any_instance_of(UserImportJob).to receive(:broadcast_completion)
        UserImportJob.new.perform(import_job.id, file_data)
        import_job.reload
        expect(import_job.processing?).to be true
      end

      it 'creates users from spreadsheet' do
        allow_any_instance_of(UserImportJob).to receive(:broadcast_progress)
        allow_any_instance_of(UserImportJob).to receive(:broadcast_completion)

        expect {
          UserImportJob.new.perform(import_job.id, file_data)
        }.to change(User, :count).by(2)
      end

      it 'creates user with correct full_name' do
        allow_any_instance_of(UserImportJob).to receive(:broadcast_progress)
        allow_any_instance_of(UserImportJob).to receive(:broadcast_completion)
        UserImportJob.new.perform(import_job.id, file_data)

        user = User.find_by(email: 'john@example.com')
        expect(user.full_name).to eq('John Doe')
      end

      it 'creates user with correct email' do
        allow_any_instance_of(UserImportJob).to receive(:broadcast_progress)
        allow_any_instance_of(UserImportJob).to receive(:broadcast_completion)
        UserImportJob.new.perform(import_job.id, file_data)

        user = User.find_by(email: 'john@example.com')
        expect(user).to be_present
      end

      it 'creates user with correct role' do
        allow_any_instance_of(UserImportJob).to receive(:broadcast_progress)
        allow_any_instance_of(UserImportJob).to receive(:broadcast_completion)
        UserImportJob.new.perform(import_job.id, file_data)

        admin = User.find_by(email: 'jane@example.com')
        expect(admin.admin?).to be true
      end

      it 'marks import job as completed' do
        allow_any_instance_of(UserImportJob).to receive(:broadcast_progress)
        allow_any_instance_of(UserImportJob).to receive(:broadcast_completion)
        UserImportJob.new.perform(import_job.id, file_data)

        import_job.reload
        expect(import_job.completed?).to be true
      end

      it 'updates processed_records count' do
        allow_any_instance_of(UserImportJob).to receive(:broadcast_progress)
        allow_any_instance_of(UserImportJob).to receive(:broadcast_completion)
        UserImportJob.new.perform(import_job.id, file_data)

        import_job.reload
        expect(import_job.processed_records).to eq(2)
      end

      it 'broadcasts progress updates' do
        expect_any_instance_of(UserImportJob).to receive(:broadcast_progress).at_least(:once)
        expect_any_instance_of(UserImportJob).to receive(:broadcast_completion)
        UserImportJob.new.perform(import_job.id, file_data)
      end

      it 'broadcasts user count to dashboard' do
        expect(ActionCable.server).to receive(:broadcast).with('dashboard_channel', hash_including(event: 'users_imported'))
        allow_any_instance_of(UserImportJob).to receive(:broadcast_progress)
        UserImportJob.new.perform(import_job.id, file_data)
      end
    end

    context 'with missing required headers' do
      let(:file_data) do
        temp_file = Tempfile.new(['users', '.xlsx'])
        workbook = RubyXL::Workbook.new
        worksheet = workbook[0]

        # Add only email header (missing full_name and role)
        worksheet.add_cell(0, 0, 'email')
        worksheet.add_cell(1, 0, 'john@example.com')

        workbook.write(temp_file.path)
        temp_file.close
        File.read(temp_file.path)
      end

      it 'marks import job as failed' do
        allow_any_instance_of(UserImportJob).to receive(:broadcast_completion)
        UserImportJob.new.perform(import_job.id, file_data)

        import_job.reload
        expect(import_job.failed?).to be true
      end

      it 'records error messages about missing columns' do
        allow_any_instance_of(UserImportJob).to receive(:broadcast_completion)
        UserImportJob.new.perform(import_job.id, file_data)

        import_job.reload
        expect(import_job.error_messages).to include('Missing required columns')
      end

      it 'does not create users' do
        allow_any_instance_of(UserImportJob).to receive(:broadcast_completion)
        expect {
          UserImportJob.new.perform(import_job.id, file_data)
        }.not_to change(User, :count)
      end
    end

    context 'with invalid email addresses' do
      let(:file_data) do
        temp_file = Tempfile.new(['users', '.xlsx'])
        workbook = RubyXL::Workbook.new
        worksheet = workbook[0]

        # Add headers
        worksheet.add_cell(0, 0, 'full_name')
        worksheet.add_cell(0, 1, 'email')
        worksheet.add_cell(0, 2, 'role')

        # Add user with invalid email
        worksheet.add_cell(1, 0, 'John Doe')
        worksheet.add_cell(1, 1, 'invalid-email')
        worksheet.add_cell(1, 2, 'user')

        workbook.write(temp_file.path)
        temp_file.close
        File.read(temp_file.path)
      end

      before do
        import_job.update(total_records: 1)
      end

      it 'records failed record' do
        allow_any_instance_of(UserImportJob).to receive(:broadcast_progress)
        allow_any_instance_of(UserImportJob).to receive(:broadcast_completion)
        UserImportJob.new.perform(import_job.id, file_data)

        import_job.reload
        expect(import_job.failed_records).to be > 0
      end

      it 'marks import as completed even with errors' do
        allow_any_instance_of(UserImportJob).to receive(:broadcast_progress)
        allow_any_instance_of(UserImportJob).to receive(:broadcast_completion)
        UserImportJob.new.perform(import_job.id, file_data)

        import_job.reload
        expect(import_job.completed?).to be true
      end
    end

    context 'with duplicate email addresses' do
      before do
        create(:user, email: 'duplicate@example.com')
      end

      let(:file_data) do
        temp_file = Tempfile.new(['users', '.xlsx'])
        workbook = RubyXL::Workbook.new
        worksheet = workbook[0]

        # Add headers
        worksheet.add_cell(0, 0, 'full_name')
        worksheet.add_cell(0, 1, 'email')
        worksheet.add_cell(0, 2, 'role')

        # Add user with duplicate email
        worksheet.add_cell(1, 0, 'Duplicate User')
        worksheet.add_cell(1, 1, 'duplicate@example.com')
        worksheet.add_cell(1, 2, 'user')

        # Add valid user
        worksheet.add_cell(2, 0, 'New User')
        worksheet.add_cell(2, 1, 'newuser@example.com')
        worksheet.add_cell(2, 2, 'user')

        workbook.write(temp_file.path)
        temp_file.close
        File.read(temp_file.path)
      end

      before do
        import_job.update(total_records: 2)
      end

      it 'fails to create user with duplicate email' do
        allow_any_instance_of(UserImportJob).to receive(:broadcast_progress)
        allow_any_instance_of(UserImportJob).to receive(:broadcast_completion)

        initial_count = User.count
        UserImportJob.new.perform(import_job.id, file_data)

        # Should add 1 (newuser), not 2 (duplicate email fails)
        expect(User.count).to eq(initial_count + 1)
      end

      it 'records the duplicate email error' do
        allow_any_instance_of(UserImportJob).to receive(:broadcast_progress)
        allow_any_instance_of(UserImportJob).to receive(:broadcast_completion)
        UserImportJob.new.perform(import_job.id, file_data)

        import_job.reload
        expect(import_job.error_messages).to include('already been taken')
      end
    end

    context 'with whitespace in data' do
      let(:file_data) do
        temp_file = Tempfile.new(['users', '.xlsx'])
        workbook = RubyXL::Workbook.new
        worksheet = workbook[0]

        # Add headers
        worksheet.add_cell(0, 0, 'full_name')
        worksheet.add_cell(0, 1, 'email')
        worksheet.add_cell(0, 2, 'role')

        # Add user with whitespace
        worksheet.add_cell(1, 0, '  John Doe  ')
        worksheet.add_cell(1, 1, '  john@example.com  ')
        worksheet.add_cell(1, 2, '  user  ')

        workbook.write(temp_file.path)
        temp_file.close
        File.read(temp_file.path)
      end

      before do
        import_job.update(total_records: 1)
      end

      it 'strips whitespace from data' do
        allow_any_instance_of(UserImportJob).to receive(:broadcast_progress)
        allow_any_instance_of(UserImportJob).to receive(:broadcast_completion)
        UserImportJob.new.perform(import_job.id, file_data)

        user = User.find_by(email: 'john@example.com')
        expect(user.full_name).to eq('John Doe')
      end
    end

    context 'with invalid role values' do
      let(:file_data) do
        temp_file = Tempfile.new(['users', '.xlsx'])
        workbook = RubyXL::Workbook.new
        worksheet = workbook[0]

        # Add headers
        worksheet.add_cell(0, 0, 'full_name')
        worksheet.add_cell(0, 1, 'email')
        worksheet.add_cell(0, 2, 'role')

        # Add user with invalid role
        worksheet.add_cell(1, 0, 'John Doe')
        worksheet.add_cell(1, 1, 'john@example.com')
        worksheet.add_cell(1, 2, 'superadmin')

        workbook.write(temp_file.path)
        temp_file.close
        File.read(temp_file.path)
      end

      before do
        import_job.update(total_records: 1)
      end

      it 'defaults invalid role to user' do
        allow_any_instance_of(UserImportJob).to receive(:broadcast_progress)
        allow_any_instance_of(UserImportJob).to receive(:broadcast_completion)
        UserImportJob.new.perform(import_job.id, file_data)

        user = User.find_by(email: 'john@example.com')
        expect(user.user?).to be true
      end
    end

    context 'with case-insensitive headers' do
      let(:file_data) do
        temp_file = Tempfile.new(['users', '.xlsx'])
        workbook = RubyXL::Workbook.new
        worksheet = workbook[0]

        # Add headers with different cases
        worksheet.add_cell(0, 0, 'FULL_NAME')
        worksheet.add_cell(0, 1, 'EMAIL')
        worksheet.add_cell(0, 2, 'ROLE')

        # Add user data
        worksheet.add_cell(1, 0, 'John Doe')
        worksheet.add_cell(1, 1, 'john@example.com')
        worksheet.add_cell(1, 2, 'user')

        workbook.write(temp_file.path)
        temp_file.close
        File.read(temp_file.path)
      end

      before do
        import_job.update(total_records: 1)
      end

      it 'handles case-insensitive headers' do
        allow_any_instance_of(UserImportJob).to receive(:broadcast_progress)
        allow_any_instance_of(UserImportJob).to receive(:broadcast_completion)
        UserImportJob.new.perform(import_job.id, file_data)

        expect(User.find_by(email: 'john@example.com')).to be_present
      end
    end

    context 'when exception occurs during processing' do
      let(:file_data) { 'invalid data' }

      it 'marks import job as failed' do
        allow_any_instance_of(UserImportJob).to receive(:broadcast_completion)
        expect {
          UserImportJob.new.perform(import_job.id, file_data)
        }.to raise_error

        import_job.reload
        expect(import_job.failed?).to be true
      end

      it 'records error message' do
        allow_any_instance_of(UserImportJob).to receive(:broadcast_completion)
        expect {
          UserImportJob.new.perform(import_job.id, file_data)
        }.to raise_error

        import_job.reload
        expect(import_job.error_messages).to include('Import failed')
      end
    end

    context 'with avatar_url column' do
      let(:file_data) do
        temp_file = Tempfile.new(['users', '.xlsx'])
        workbook = RubyXL::Workbook.new
        worksheet = workbook[0]

        # Add headers including avatar_url
        worksheet.add_cell(0, 0, 'full_name')
        worksheet.add_cell(0, 1, 'email')
        worksheet.add_cell(0, 2, 'role')
        worksheet.add_cell(0, 3, 'avatar_url')

        # Add user data
        worksheet.add_cell(1, 0, 'John Doe')
        worksheet.add_cell(1, 1, 'john@example.com')
        worksheet.add_cell(1, 2, 'user')
        worksheet.add_cell(1, 3, 'https://example.com/avatar.jpg')

        workbook.write(temp_file.path)
        temp_file.close
        File.read(temp_file.path)
      end

      before do
        import_job.update(total_records: 1)
      end

      it 'handles avatar_url column' do
        allow_any_instance_of(UserImportJob).to receive(:broadcast_progress)
        allow_any_instance_of(UserImportJob).to receive(:broadcast_completion)
        UserImportJob.new.perform(import_job.id, file_data)

        user = User.find_by(email: 'john@example.com')
        expect(user).to be_present
      end
    end

    context 'with progress tracking' do
      let(:file_data) do
        temp_file = Tempfile.new(['users', '.xlsx'])
        workbook = RubyXL::Workbook.new
        worksheet = workbook[0]

        # Add headers
        worksheet.add_cell(0, 0, 'full_name')
        worksheet.add_cell(0, 1, 'email')
        worksheet.add_cell(0, 2, 'role')

        # Add 5 users
        5.times do |i|
          worksheet.add_cell(i + 1, 0, "User #{i}")
          worksheet.add_cell(i + 1, 1, "user#{i}@example.com")
          worksheet.add_cell(i + 1, 2, 'user')
        end

        workbook.write(temp_file.path)
        temp_file.close
        File.read(temp_file.path)
      end

      before do
        import_job.update(total_records: 5)
      end

      it 'updates processed_records incrementally' do
        allow_any_instance_of(UserImportJob).to receive(:broadcast_progress)
        allow_any_instance_of(UserImportJob).to receive(:broadcast_completion)

        UserImportJob.new.perform(import_job.id, file_data)

        import_job.reload
        expect(import_job.processed_records).to eq(5)
      end

      it 'broadcasts progress with correct data' do
        job = UserImportJob.new
        expect(job).to receive(:broadcast_progress).at_least(:once) do |import_job_arg|
          expect(import_job_arg).to be_a(ImportJob)
        end
        allow(job).to receive(:broadcast_completion)

        job.perform(import_job.id, file_data)
      end
    end
  end
end
