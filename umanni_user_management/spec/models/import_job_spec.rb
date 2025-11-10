require 'rails_helper'

RSpec.describe ImportJob, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    subject { build(:import_job) }

    it { should validate_presence_of(:file_name) }
    it { should validate_presence_of(:status) }
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(pending: 0, processing: 1, completed: 2, failed: 3) }
  end

  describe 'scopes' do
    let!(:recent_job) { create(:import_job, created_at: 1.hour.ago) }
    let!(:old_job) { create(:import_job, created_at: 1.day.ago) }
    let!(:pending_job) { create(:import_job, status: :pending) }
    let!(:completed_job) { create(:import_job, status: :completed) }

    describe '.recent' do
      it 'returns import jobs ordered by created_at descending' do
        jobs = ImportJob.recent
        expect(jobs.first).to eq(recent_job)
        expect(jobs.last).to eq(old_job)
      end
    end

    describe '.by_status' do
      it 'returns import jobs filtered by status' do
        jobs = ImportJob.by_status(:completed)
        expect(jobs).to include(completed_job)
        expect(jobs).not_to include(pending_job)
      end

      it 'returns all jobs when status is nil' do
        jobs = ImportJob.by_status(nil)
        expect(jobs).to include(pending_job, completed_job)
      end

      it 'returns all jobs when status is empty string' do
        jobs = ImportJob.by_status('')
        expect(jobs).to include(pending_job, completed_job)
      end
    end
  end

  describe '#progress_percentage' do
    context 'when total_records is zero' do
      let(:import_job) { build(:import_job, total_records: 0, processed_records: 0) }

      it 'returns 0' do
        expect(import_job.progress_percentage).to eq(0)
      end
    end

    context 'when no records have been processed' do
      let(:import_job) { build(:import_job, total_records: 10, processed_records: 0) }

      it 'returns 0' do
        expect(import_job.progress_percentage).to eq(0)
      end
    end

    context 'when some records have been processed' do
      let(:import_job) { build(:import_job, total_records: 10, processed_records: 5) }

      it 'returns 50.0' do
        expect(import_job.progress_percentage).to eq(50.0)
      end
    end

    context 'when all records have been processed' do
      let(:import_job) { build(:import_job, total_records: 10, processed_records: 10) }

      it 'returns 100.0' do
        expect(import_job.progress_percentage).to eq(100.0)
      end
    end

    context 'with decimal results' do
      let(:import_job) { build(:import_job, total_records: 3, processed_records: 1) }

      it 'rounds to 2 decimal places' do
        expect(import_job.progress_percentage).to eq(33.33)
      end
    end
  end

  describe '#completed?' do
    it 'returns true when status is completed' do
      import_job = build(:import_job, status: :completed)
      expect(import_job.completed?).to be true
    end

    it 'returns false when status is not completed' do
      import_job = build(:import_job, status: :pending)
      expect(import_job.completed?).to be false
    end

    it 'returns false when status is processing' do
      import_job = build(:import_job, status: :processing)
      expect(import_job.completed?).to be false
    end

    it 'returns false when status is failed' do
      import_job = build(:import_job, status: :failed)
      expect(import_job.completed?).to be false
    end
  end

  describe '#failed?' do
    it 'returns true when status is failed' do
      import_job = build(:import_job, status: :failed)
      expect(import_job.failed?).to be true
    end

    it 'returns false when status is not failed' do
      import_job = build(:import_job, status: :pending)
      expect(import_job.failed?).to be false
    end

    it 'returns false when status is completed' do
      import_job = build(:import_job, status: :completed)
      expect(import_job.failed?).to be false
    end
  end

  describe '#processing?' do
    it 'returns true when status is processing' do
      import_job = build(:import_job, status: :processing)
      expect(import_job.processing?).to be true
    end

    it 'returns false when status is not processing' do
      import_job = build(:import_job, status: :pending)
      expect(import_job.processing?).to be false
    end

    it 'returns false when status is completed' do
      import_job = build(:import_job, status: :completed)
      expect(import_job.processing?).to be false
    end
  end

  describe 'factory' do
    it 'has a valid default factory' do
      expect(build(:import_job)).to be_valid
    end

    it 'has a valid processing trait factory' do
      expect(build(:import_job, :processing)).to be_valid
    end

    it 'has a valid completed trait factory' do
      expect(build(:import_job, :completed)).to be_valid
    end

    it 'has a valid completed_with_errors trait factory' do
      expect(build(:import_job, :completed_with_errors)).to be_valid
    end

    it 'has a valid failed trait factory' do
      expect(build(:import_job, :failed)).to be_valid
    end
  end
end
