# Testing Guide for Umanni User Management

This document provides comprehensive information about the test suite for the Umanni User Management Rails 8 application.

## Overview

The test suite includes comprehensive RSpec tests covering:
- **Models**: User and ImportJob models with validations and business logic
- **Requests (Controllers)**: Admin dashboard, users management, profiles, and home page
- **Policies**: Authorization rules using Pundit
- **Jobs**: Background job processing for user imports
- **Factories**: Test data generation with FactoryBot
- **Support Files**: Devise authentication helpers, Pundit matchers, and shared contexts

## Test Coverage

The test suite aims for 90%+ code coverage and tests:
- All validations
- All business logic methods
- All authorization policies
- Success and failure scenarios
- Edge cases and error handling
- Action Cable broadcasting
- Background job processing
- File uploads and Active Storage

## Project Structure

```
spec/
├── factories/              # FactoryBot test data factories
│   ├── users.rb           # User factory with traits (admin, with_avatar)
│   └── import_jobs.rb     # ImportJob factory with traits (processing, completed, failed)
├── fixtures/              # Static test data
│   └── files/
│       └── test_avatar.png
├── jobs/                  # Background job specs
│   └── user_import_job_spec.rb
├── models/                # Model specs
│   ├── user_spec.rb       # User model tests
│   └── import_job_spec.rb # ImportJob model tests
├── policies/              # Authorization policy specs
│   ├── user_policy_spec.rb
│   └── dashboard_policy_spec.rb
├── requests/              # Controller/Request specs
│   ├── admin/
│   │   ├── dashboard_spec.rb
│   │   └── users_spec.rb
│   ├── home_spec.rb
│   └── profiles_spec.rb
├── support/               # RSpec support and configuration
│   ├── action_cable.rb    # Action Cable testing helpers
│   ├── devise.rb          # Devise authentication helpers
│   ├── pundit.rb          # Pundit authorization matchers
│   └── shared_contexts.rb # Shared test contexts
├── rails_helper.rb        # Rails test configuration
└── spec_helper.rb         # RSpec configuration with SimpleCov
```

## Running Tests

### Run all tests
```bash
bundle exec rspec
```

### Run with code coverage report
```bash
bundle exec rspec --require spec_helper
```
Coverage report will be generated in `coverage/` directory.

### Run specific test file
```bash
bundle exec rspec spec/models/user_spec.rb
```

### Run specific test with line number
```bash
bundle exec rspec spec/models/user_spec.rb:25
```

### Run with documentation format
```bash
bundle exec rspec -f d
```

### Run only previously failing tests
```bash
bundle exec rspec --only-failures
```

### Run tests in order
```bash
bundle exec rspec --order defined
```

### Run tests tagged with :focus
```bash
bundle exec rspec --tag focus
```

## Test Categories

### Model Tests (`spec/models/`)

#### User Model (`user_spec.rb`)
- Validations: full_name, email, password, avatar_image
- Associations: avatar_image attachment
- Enums: role (user/admin)
- Methods: `admin?`, `user?`
- Devise modules integration
- Factory tests

**Coverage**: 100%
**Tests**: 20+

#### ImportJob Model (`import_job_spec.rb`)
- Validations: file_name, status
- Associations: belongs_to :user
- Enums: status (pending/processing/completed/failed)
- Scopes: recent, by_status
- Methods: `progress_percentage`, `completed?`, `failed?`, `processing?`
- Progress calculation with edge cases
- Factory tests

**Coverage**: 100%
**Tests**: 30+

### Policy Tests (`spec/policies/`)

#### UserPolicy (`user_policy_spec.rb`)
- `index?`: Admin-only list all users
- `show?`: Admin or self
- `create?`: Admin-only
- `update?`: Admin or self
- `destroy?`: Admin or self, prevent last admin deletion
- `toggle_role?`: Admin but not self
- `import?`: Admin-only
- Scope: User resolution for admin vs regular users

**Coverage**: 100%
**Tests**: 25+

#### DashboardPolicy (`dashboard_policy_spec.rb`)
- `show?`: Admin-only access to dashboard

**Coverage**: 100%
**Tests**: 3

### Request Tests (`spec/requests/`)

#### Admin Dashboard (`admin/dashboard_spec.rb`)
- GET /admin/dashboard access control
- Statistics calculation (total users, admins, regular users)
- Import job retrieval
- Unauthorized access handling

**Coverage**: 95%+
**Tests**: 15+

#### Admin Users Management (`admin/users_spec.rb`)
- CRUD operations (index, show, new, create, edit, update, delete)
- Role toggling with authorization
- User import functionality
- Action Cable broadcasting on user events
- Pagination
- Validation error handling
- Duplicate email prevention
- Password field handling in updates
- Last admin protection

**Coverage**: 95%+
**Tests**: 50+

#### Profiles (`profiles_spec.rb`)
- GET /profile (show current user profile)
- GET /profile/edit
- PATCH /profile (update with validations)
- DELETE /profile (account deletion)
- Avatar image uploads
- Password changes
- Duplicate email prevention
- Authorization (users can only manage own profile)

**Coverage**: 95%+
**Tests**: 40+

#### Home Page (`home_spec.rb`)
- GET / (home index)
- Admin redirect to dashboard
- Regular user redirect to profile
- Unauthenticated user access

**Coverage**: 90%+
**Tests**: 10+

### Job Tests (`spec/jobs/`)

#### UserImportJob (`user_import_job_spec.rb`)
- Successful spreadsheet import with valid data
- User creation from XLSX files
- Role assignment (admin/user)
- Progress tracking and updates
- Action Cable broadcasting
- Error handling for missing headers
- Invalid email validation
- Duplicate email detection
- Whitespace stripping
- Invalid role defaults to user
- Case-insensitive header handling
- Avatar URL handling
- Import failure scenarios
- Comprehensive progress percentage calculation

**Coverage**: 90%+
**Tests**: 40+

## Factories

### User Factory (`spec/factories/users.rb`)

```ruby
# Create a regular user
user = create(:user)

# Create an admin user
admin = create(:user, :admin)

# Create user with avatar
user_with_avatar = create(:user, :with_avatar)

# Build (without saving)
user = build(:user)
```

Traits:
- `:admin` - Creates user with admin role
- `:with_avatar` - Attaches test avatar image

### ImportJob Factory (`spec/factories/import_jobs.rb`)

```ruby
# Create pending import job
job = create(:import_job)

# Create processing job with partial progress
job = create(:import_job, :processing)

# Create completed job
job = create(:import_job, :completed)

# Create completed job with errors
job = create(:import_job, :completed_with_errors)

# Create failed job
job = create(:import_job, :failed)
```

Traits:
- `:processing` - Status: processing, 50% complete
- `:completed` - Status: completed, 100% processed
- `:completed_with_errors` - Completed with 2 errors
- `:failed` - Status: failed with error message

## Support Files

### Devise Helper (`spec/support/devise.rb`)
Provides:
- `sign_in(user)` - Sign in a user in request specs
- `sign_out` - Sign out current user
- Integration with Devise test helpers

### Pundit Matcher (`spec/support/pundit.rb`)
Provides:
- `permit(:action)` - Assert policy permits action
- `forbid(:action)` - Assert policy forbids action

### Action Cable (`spec/support/action_cable.rb`)
Configuration for testing Action Cable broadcasting

### Shared Contexts (`spec/support/shared_contexts.rb`)
Provides:
- `authenticated as admin` - Sign in as admin
- `authenticated as user` - Sign in as regular user
- `unauthenticated` - Sign out user

## Common Test Patterns

### Testing Authorization
```ruby
context 'when user is an admin' do
  let(:user) { admin_user }
  it { is_expected.to permit(:action) }
end

context 'when user is not admin' do
  let(:user) { regular_user }
  it { is_expected.to forbid(:action) }
end
```

### Testing Request with Authentication
```ruby
before { sign_in admin_user }

it 'returns 200 OK' do
  get admin_dashboard_path
  expect(response).to have_http_status(:ok)
end
```

### Testing Action Cable Broadcasting
```ruby
it 'broadcasts user creation' do
  expect(ActionCable.server).to receive(:broadcast).with('dashboard_channel', hash_including(event: 'user_created'))
  post admin_users_path, params: { user: user_params }
end
```

### Testing Model Validations
```ruby
subject { build(:user) }
it { should validate_presence_of(:full_name) }
it { should validate_length_of(:full_name).is_at_least(2).is_at_most(100) }
```

## Code Coverage

To view code coverage:

1. Run tests with coverage:
```bash
COVERAGE=true bundle exec rspec
```

2. Open coverage report:
```bash
open coverage/index.html
```

The SimpleCov configuration in `spec_helper.rb` is set to:
- Minimum coverage: 90%
- Include: Controllers, Models, Helpers, Jobs, Mailers, Services, Policies
- Exclude: Bin, DB, Spec, Config, Vendor

## Best Practices

1. **Isolation**: Each test should be independent
2. **Clarity**: Use descriptive test names
3. **DRY**: Use shared contexts and factories to reduce duplication
4. **Focus**: Use `focus` tag to debug failing tests
5. **Speed**: Mock external dependencies (emails, file downloads)
6. **Coverage**: Aim for 90%+ coverage on business logic

## Debugging Tests

### Run with verbose output
```bash
bundle exec rspec --format documentation
```

### Run specific failing test
```bash
bundle exec rspec spec/path/to/spec.rb:line_number
```

### Debug with pry
Add `binding.pry` in test and run with `--no-fail-fast`:
```bash
bundle exec rspec spec/path/to/spec.rb --no-fail-fast
```

### Check slowest tests
```bash
bundle exec rspec --profile
```

## CI/CD Integration

The test suite is designed for CI/CD pipelines:
- Tests run in isolation with transactional fixtures
- Random order prevents order dependencies
- Coverage reports generated automatically
- JUnit XML output available (configure formatter)

## Troubleshooting

### Tests timeout
- Increase timeout in `spec_helper.rb`
- Check for missing database transactions
- Review slow tests with `--profile`

### Database state issues
- Ensure `use_transactional_fixtures = true` in rails_helper.rb
- Clear database between test runs
- Check for leftover test data

### Action Cable not broadcasting
- Verify Action Cable configured in test environment
- Use `allow_any_instance_of(UserImportJob).to receive(:broadcast_progress)`
- Check broadcast channel names match

### Missing fixtures
- Ensure `spec/fixtures/files/test_avatar.png` exists
- Use temporary files for XLSX test fixtures
- Leverage FactoryBot for dynamic test data

## Additional Resources

- [RSpec Documentation](https://rspec.info)
- [FactoryBot Documentation](https://github.com/thoughtbot/factory_bot)
- [Pundit Documentation](https://github.com/varvet/pundit)
- [Devise Documentation](https://github.com/heartcombo/devise)
- [SimpleCov Documentation](https://github.com/simplecov-ruby/simplecov)
- [Shoulda Matchers Documentation](https://github.com/thoughtbot/shoulda-matchers)
