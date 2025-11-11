# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a full-stack Ruby on Rails 8.1.1 user management application built for the Umanni Fullstack Developer test. The application demonstrates role-based access control, real-time updates via Action Cable, background job processing, and spreadsheet import functionality.

**Tech Stack:** Ruby 3.3.6, Rails 8.1.1, PostgreSQL 16, Redis, Sidekiq, Hotwire (Turbo + Stimulus), Bootstrap 5, Docker

## Development Environment

All development happens inside Docker containers. The project uses Docker Compose with 4 services:
- **web**: Rails application (localhost:3000)
- **db**: PostgreSQL database
- **redis**: Redis for Action Cable & Sidekiq
- **sidekiq**: Background job processor

### Essential Commands

**Initial Setup:**
```bash
cd umanni_user_management
docker-compose build
docker-compose run web bin/rails db:create db:migrate db:seed
docker-compose up
```

**Admin Credentials:**
- Email: `admin@email.com`
- Password: `admin123456`
- Role: Administrator

**Daily Development:**
```bash
# Start all services
docker-compose up

# Run Rails console
docker-compose run web bin/rails console

# Run tests
docker-compose run web bundle exec rspec

# Run specific test file
docker-compose run web bundle exec rspec spec/models/user_spec.rb

# Run tests with coverage report
docker-compose run web bash -c "COVERAGE=true bundle exec rspec"

# Code linting
docker-compose run web bundle exec rubocop

# Security scan
docker-compose run web bundle exec brakeman
```

**Database Operations:**
```bash
# Run migrations
docker-compose run web bin/rails db:migrate

# Reset database
docker-compose run web bin/rails db:reset

# Generate migration
docker-compose run web bin/rails generate migration MigrationName
```

## Architecture Overview

### Authentication & Authorization Flow

The application uses **Devise** for authentication and **Pundit** for authorization:

1. **User Model** ([app/models/user.rb](umanni_user_management/app/models/user.rb)):
   - Two roles: `admin` and `user` (enum)
   - Admin users access dashboard, manage all users, import spreadsheets
   - Regular users only access their own profile

2. **Authorization Logic** ([app/policies/](umanni_user_management/app/policies/)):
   - `UserPolicy`: Defines who can CRUD users, toggle roles, import data
   - `DashboardPolicy`: Restricts dashboard to admins only
   - Policies enforce "admin can do everything except delete last admin" and "users can only edit themselves"

3. **Routing** ([config/routes.rb](umanni_user_management/config/routes.rb)):
   - After login, admins → `/admin/dashboard`, users → `/profile`
   - Admin routes under `/admin` namespace
   - Profile routes use singular resource pattern

### Real-time Architecture

The application uses **Action Cable** for real-time updates:

1. **DashboardChannel** ([app/channels/dashboard_channel.rb](umanni_user_management/app/channels/dashboard_channel.rb)):
   - Broadcasts to `dashboard_channel` when users are created/deleted/imported
   - Updates admin dashboard counters in real-time without page refresh

2. **ImportProgressChannel** ([app/channels/import_progress_channel.rb](umanni_user_management/app/channels/import_progress_channel.rb)):
   - Streams to `import_progress_#{import_job_id}` for each import job
   - Broadcasts progress updates as spreadsheet is processed
   - Used by frontend Stimulus controller to update progress bar

3. **Broadcasting Pattern**:
   - Controllers broadcast user events after create/destroy actions
   - Background jobs broadcast progress and completion events
   - Frontend subscribes via Stimulus controllers with Action Cable consumer

### Background Job Processing

**UserImportJob** ([app/jobs/user_import_job.rb](umanni_user_management/app/jobs/user_import_job.rb)) handles spreadsheet imports:

1. **Input**: ImportJob ID and file data (CSV/XLSX)
2. **Process**:
   - Validates required headers (full_name, email, role)
   - Processes rows sequentially with progress tracking
   - Downloads avatar images from URLs if provided
   - Broadcasts progress via Action Cable after each row
   - Handles validation errors gracefully (continues processing)
3. **Output**: ImportJob updated with status, processed/failed counts, errors
4. **Note**: Job uses Tempfile for XLSX processing and Roo gem for spreadsheet parsing

### Controller Organization

- **ApplicationController** ([app/controllers/application_controller.rb](umanni_user_management/app/controllers/application_controller.rb)):
  - Includes Pundit::Authorization and Pagy::Backend
  - Handles role-based redirect after login
  - Configures Devise permitted parameters

- **Admin Namespace** ([app/controllers/admin/](umanni_user_management/app/controllers/admin/)):
  - `DashboardController`: Statistics and recent imports
  - `UsersController`: Full CRUD, role toggle, import functionality
  - All actions authorize via Pundit

- **ProfilesController** ([app/controllers/profiles_controller.rb](umanni_user_management/app/controllers/profiles_controller.rb)):
  - Uses singular resource pattern
  - Users manage only their own profile
  - Supports avatar upload and account deletion

### Frontend Architecture

The application uses **Hotwire** (Turbo + Stimulus) for SPA-like experience:

- **Turbo**: Handles navigation without full page reloads
- **Stimulus Controllers** ([app/javascript/controllers/](umanni_user_management/app/javascript/controllers/)): Manage client-side interactions
- **SCSS Organization** ([app/assets/stylesheets/](umanni_user_management/app/assets/stylesheets/)): Component-based structure with Bootstrap 5
- **Action Cable Integration**: Stimulus controllers subscribe to channels for real-time updates

### Testing Strategy

The test suite achieves 90%+ coverage using RSpec. See [TESTING.md](umanni_user_management/TESTING.md) for details.

**Key Testing Patterns:**

1. **Models**: Validation, associations, enums, business logic methods
2. **Policies**: Authorization rules for all user roles and edge cases
3. **Requests (Controllers)**: HTTP status, redirects, database changes, Action Cable broadcasts
4. **Jobs**: Background processing, progress tracking, error handling

**Factories** ([spec/factories/](umanni_user_management/spec/factories/)):
- `create(:user)` - regular user
- `create(:user, :admin)` - admin user
- `create(:user, :with_avatar)` - user with avatar
- `create(:import_job, :processing)` - import job with status

**Running Tests:**
```bash
# All tests
docker-compose run web bundle exec rspec

# Specific suite
docker-compose run web bundle exec rspec spec/models
docker-compose run web bundle exec rspec spec/requests
docker-compose run web bundle exec rspec spec/policies
docker-compose run web bundle exec rspec spec/jobs

# With documentation format
docker-compose run web bundle exec rspec -f d

# Only failures
docker-compose run web bundle exec rspec --only-failures
```

## Important Development Notes

### Security Considerations

- **CSRF Protection**: Enabled by default in Rails
- **XSS Prevention**: Use `sanitize` helper, avoid `html_safe` unless necessary
- **SQL Injection**: Use ActiveRecord query interface, never raw SQL with user input
- **Mass Assignment**: Strong parameters in all controllers
- **File Upload Validation**: Avatar images validated for type and size in User model
- **Authorization**: Always use `authorize @resource` in admin controllers

### Spreadsheet Import Format

CSV/XLSX files must have these columns (case-insensitive headers):
- `full_name` (required, 2-100 chars)
- `email` (required, unique, valid format)
- `role` (required, "admin" or "user", defaults to "user" if invalid)
- `password` (optional, if not provided, a random password will be generated)
- `avatar_url` (optional, valid image URL)

### Common Gotchas

1. **Password Generation in Import**: If the CSV doesn't include a `password` column, the import job generates random passwords with `SecureRandom.hex(8)` - users must reset password. If a `password` column is provided, those passwords will be used.
2. **Last Admin Protection**: Cannot delete last admin user (enforced in UserPolicy)
3. **Action Cable Broadcasting**: Always broadcast after database commits to avoid race conditions
4. **Docker Volume Mounts**: Changes to Gemfile require `docker-compose build` to reinstall gems
5. **Redis Dependency**: Sidekiq and Action Cable both require Redis to be running

### Database Schema

- **users**: full_name, email, role (enum: 0=user, 1=admin), encrypted_password, avatar_image (Active Storage)
- **import_jobs**: file_name, status (enum), total_records, processed_records, failed_records, error_messages, user_id
- **active_storage_blobs** & **active_storage_attachments**: Rails Active Storage tables for avatars

### Configuration Files

- **Pagination**: [config/initializers/pagy.rb](umanni_user_management/config/initializers/pagy.rb) - Set to 10 items per page
- **Sidekiq**: [config/initializers/sidekiq.rb](umanni_user_management/config/initializers/sidekiq.rb) - Redis connection config
- **Devise**: [config/initializers/devise.rb](umanni_user_management/config/initializers/devise.rb) - Authentication settings
- **Action Cable**: [config/cable.yml](umanni_user_management/config/cable.yml) - Redis adapter for production

### Adding New Features

When adding features that require:
- **New Model**: Generate with `docker-compose run web bin/rails generate model ModelName`
- **New Controller**: Follow namespace pattern (Admin:: for admin features)
- **Authorization**: Create policy in `app/policies/` and call `authorize` in controller
- **Real-time Updates**: Broadcast to appropriate channel after database changes
- **Background Processing**: Create job in `app/jobs/` and enqueue with `.perform_later`

## Code Quality Tools

- **RuboCop** ([.rubocop.yml](umanni_user_management/.rubocop.yml)): Style guide enforcement
- **Brakeman**: Security vulnerability scanner
- **SimpleCov**: Code coverage reporting (90% minimum)
- **FactoryBot**: Test data generation
- **Shoulda Matchers**: RSpec matcher library for common Rails patterns
