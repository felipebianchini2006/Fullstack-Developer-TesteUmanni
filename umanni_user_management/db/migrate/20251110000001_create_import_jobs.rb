class CreateImportJobs < ActiveRecord::Migration[8.1]
  def change
    create_table :import_jobs do |t|
      t.string :file_name, null: false
      t.integer :status, default: 0, null: false
      t.integer :total_records, default: 0
      t.integer :processed_records, default: 0
      t.integer :failed_records, default: 0
      t.text :error_messages
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :import_jobs, :status
    add_index :import_jobs, :created_at
  end
end
