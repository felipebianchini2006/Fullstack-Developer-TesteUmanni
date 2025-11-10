FactoryBot.define do
  factory :import_job do
    association :user
    file_name { "users_import_#{Time.current.to_i}.xlsx" }
    status { :pending }
    total_records { 10 }
    processed_records { 0 }
    failed_records { 0 }
    error_messages { nil }

    trait :processing do
      status { :processing }
      processed_records { 5 }
    end

    trait :completed do
      status { :completed }
      total_records { 10 }
      processed_records { 10 }
      failed_records { 0 }
    end

    trait :completed_with_errors do
      status { :completed }
      total_records { 10 }
      processed_records { 8 }
      failed_records { 2 }
      error_messages { "Row 5: Email has already been taken\nRow 8: Email has already been taken" }
    end

    trait :failed do
      status { :failed }
      total_records { 10 }
      processed_records { 0 }
      failed_records { 10 }
      error_messages { "Missing required columns: full_name, email" }
    end
  end
end
