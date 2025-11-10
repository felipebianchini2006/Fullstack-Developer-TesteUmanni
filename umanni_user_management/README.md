# Umanni User Management System

A full-stack Ruby on Rails application for managing users with role-based permissions, real-time updates, and spreadsheet import functionality.

## 🚀 Features

### Admin Features
- **Dashboard**: Real-time statistics showing total users and role distribution
- **User Management**: Full CRUD operations (Create, Read, Update, Delete)
- **Role Management**: Toggle user roles between Admin and Regular User
- **Bulk Import**: Import users from CSV/XLSX spreadsheets with progress tracking
- **Real-time Updates**: Live counter updates via Action Cable when users are created/deleted

### User Features
- **Profile Management**: View and edit personal information
- **Avatar Upload**: Upload profile pictures from file or URL
- **Account Management**: Update password and delete own account
- **Secure Authentication**: Industry-standard authentication via Devise

### Security Features
- ✅ CSRF Protection
- ✅ SQL Injection Prevention
- ✅ XSS Prevention
- ✅ Mass Assignment Protection
- ✅ Role-based Authorization (Pundit)
- ✅ Secure Password Hashing (bcrypt)
- ✅ File Upload Validation

## 🛠 Technology Stack

- **Backend**: Ruby 3.3.6, Rails 8.1.1
- **Database**: PostgreSQL 16
- **Frontend**: Hotwire (Turbo + Stimulus), Bootstrap 5, SCSS
- **Real-time**: Action Cable with Redis
- **Background Jobs**: Sidekiq with Redis
- **Authentication**: Devise
- **Authorization**: Pundit
- **File Storage**: Active Storage
- **Testing**: RSpec, FactoryBot, SimpleCov (90%+ coverage)
- **Linting**: RuboCop
- **Security**: Brakeman, Bundler Audit
- **Containerization**: Docker & Docker Compose

## 📋 Prerequisites

- Docker (20.10+)
- Docker Compose (2.0+)

That's it! Everything else runs in containers.

## 🏗 Build and Run

### 1. Build the Application

```bash
docker-compose build
```

### 2. Setup the Database

```bash
docker-compose run web bin/rails db:create db:migrate db:seed
```

### 3. Start the Application

```bash
docker-compose up
```

The application will be available at: **http://localhost:3000**

### 4. Access the Application

**Admin Account:**
- Email: `admin@example.com`
- Password: `password`

**Regular User Account:**
- Email: `john.doe@example.com`
- Password: `password`

## 🧪 Running Tests

### Run Full Test Suite

```bash
docker-compose run web bundle exec rspec
```

### Run Tests with Coverage Report

```bash
docker-compose run web bash -c "COVERAGE=true bundle exec rspec"
```

Coverage reports will be generated in `coverage/` directory.

### Run Specific Tests

```bash
# Models
docker-compose run web bundle exec rspec spec/models

# Controllers
docker-compose run web bundle exec rspec spec/requests

# Specific file
docker-compose run web bundle exec rspec spec/models/user_spec.rb
```

## 🔍 Code Quality

### Run Linter

```bash
docker-compose run web bundle exec rubocop
```

### Run Security Audit

```bash
docker-compose run web bundle exec brakeman
docker-compose run web bundle exec bundle-audit check --update
```

## 📁 Project Structure

```
umanni_user_management/
├── app/
│   ├── assets/
│   │   └── stylesheets/        # SCSS organized by components and pages
│   ├── channels/               # Action Cable channels for real-time
│   ├── controllers/
│   │   ├── admin/              # Admin namespace controllers
│   │   └── profiles_controller.rb
│   ├── helpers/
│   ├── javascript/
│   │   └── controllers/        # Stimulus controllers
│   ├── jobs/
│   │   └── user_import_job.rb  # Background job for spreadsheet import
│   ├── models/
│   │   ├── user.rb
│   │   └── import_job.rb
│   ├── policies/               # Pundit authorization policies
│   └── views/
│       ├── admin/              # Admin views
│       ├── profiles/           # User profile views
│       └── shared/             # Shared partials
├── config/
│   ├── initializers/
│   │   ├── pagy.rb             # Pagination configuration
│   │   ├── sidekiq.rb          # Background jobs configuration
│   │   └── devise.rb           # Authentication configuration
│   ├── cable.yml               # Action Cable configuration
│   ├── database.yml            # Database configuration
│   └── routes.rb               # Application routes
├── db/
│   ├── migrate/                # Database migrations
│   └── seeds.rb                # Seed data
├── spec/                       # RSpec test suite (90%+ coverage)
│   ├── models/
│   ├── requests/
│   ├── policies/
│   ├── jobs/
│   ├── factories/
│   └── support/
├── Dockerfile                  # Production-ready Dockerfile
├── Dockerfile.dev              # Development Dockerfile
├── docker-compose.yml          # Docker services configuration
├── Gemfile                     # Ruby dependencies
└── README.md                   # This file
```

## 🚢 Docker Services

The application runs 4 services:

1. **web**: Rails application (Port 3000)
2. **db**: PostgreSQL database (Port 5432)
3. **redis**: Redis for Action Cable & Sidekiq (Port 6379)
4. **sidekiq**: Background job processor

## 🌐 API Endpoints

### Authentication
- `GET /users/sign_in` - Login page
- `POST /users/sign_in` - Login
- `DELETE /users/sign_out` - Logout
- `GET /users/sign_up` - Registration page
- `POST /users` - Register new user

### Profile
- `GET /profile` - View own profile
- `GET /profile/edit` - Edit profile form
- `PATCH /profile` - Update profile
- `DELETE /profile` - Delete own account

### Admin Dashboard
- `GET /admin/dashboard` - Admin dashboard with statistics

### Admin User Management
- `GET /admin/users` - List all users
- `GET /admin/users/new` - New user form
- `POST /admin/users` - Create user
- `GET /admin/users/:id` - Show user
- `GET /admin/users/:id/edit` - Edit user form
- `PATCH /admin/users/:id` - Update user
- `DELETE /admin/users/:id` - Delete user
- `PATCH /admin/users/:id/toggle_role` - Toggle user role
- `GET /admin/users/import` - Import form
- `POST /admin/users/process_import` - Process spreadsheet import

## 📊 Spreadsheet Import Format

The import accepts CSV or XLSX files with the following columns:

| Column Name | Required | Format | Example |
|-------------|----------|--------|---------|
| full_name   | Yes      | String (2-100 chars) | John Doe |
| email       | Yes      | Valid email | john@example.com |
| role        | Yes      | "admin" or "user" | user |
| avatar_url  | No       | Valid image URL | https://example.com/avatar.jpg |

**Example CSV:**

```csv
full_name,email,role,avatar_url
John Doe,john@example.com,user,https://ui-avatars.com/api/?name=John+Doe
Jane Admin,jane@example.com,admin,
```

## 🔧 Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `POSTGRES_HOST` | PostgreSQL host | db |
| `POSTGRES_USER` | PostgreSQL user | postgres |
| `POSTGRES_PASSWORD` | PostgreSQL password | 123456 |
| `POSTGRES_PORT` | PostgreSQL port | 5432 |
| `REDIS_URL` | Redis connection URL | redis://redis:6379/0 |
| `RAILS_ENV` | Rails environment | development |
| `RAILS_MAX_THREADS` | Max threads | 5 |

## 🎨 Design Patterns & Best Practices

### Architecture
- **MVC Pattern**: Clear separation of concerns
- **Service Objects**: Complex business logic (UserImportJob)
- **Policy Objects**: Authorization logic (Pundit)
- **Background Jobs**: Long-running operations (Sidekiq)
- **Real-time Communication**: Action Cable for live updates

### Code Quality
- **DRY Principle**: No code repetition
- **SOLID Principles**: Single responsibility, dependency injection
- **RESTful Design**: Standard HTTP methods (GET, POST, PATCH, DELETE)
- **Security First**: Multiple layers of validation and authorization
- **Test Driven**: 90%+ test coverage with RSpec

### Frontend
- **Progressive Enhancement**: Works without JavaScript
- **Responsive Design**: Mobile-first approach with Bootstrap 5
- **SPA-like Experience**: Turbo for fast page transitions
- **Modern JavaScript**: Stimulus for lightweight interactivity
- **Organized CSS**: SCSS with component-based structure

## 🧰 Useful Commands

### Docker Commands

```bash
# Start all services
docker-compose up

# Start in background
docker-compose up -d

# Stop all services
docker-compose down

# View logs
docker-compose logs -f web

# Access Rails console
docker-compose run web bin/rails console

# Access database console
docker-compose exec db psql -U postgres -d umanni_user_management_development
```

### Rails Commands

```bash
# Create database
docker-compose run web bin/rails db:create

# Run migrations
docker-compose run web bin/rails db:migrate

# Seed database
docker-compose run web bin/rails db:seed

# Reset database
docker-compose run web bin/rails db:reset

# Rails console
docker-compose run web bin/rails console

# Generate migration
docker-compose run web bin/rails generate migration MigrationName
```

### Sidekiq Commands

```bash
# View Sidekiq logs
docker-compose logs -f sidekiq

# Restart Sidekiq
docker-compose restart sidekiq
```

## 📚 Additional Documentation

- [TESTING.md](TESTING.md) - Comprehensive testing guide
- [DEVELOPMENT_INSTRUCTIONS.md](../DEVELOPMENT_INSTRUCTIONS.md) - Detailed development instructions

## 🤝 Contributing

1. Follow the Ruby Style Guide
2. Write tests for new features
3. Ensure all tests pass
4. Run linters before committing
5. Use semantic commit messages

## 📝 License

This project is developed as part of the Umanni Fullstack Developer test.

## 👥 Author

Developed for Umanni Fullstack Developer position evaluation.

## 🆘 Troubleshooting

### Port Already in Use

If port 3000, 5432, or 6379 is already in use:

```bash
# Stop conflicting services
docker-compose down

# Or change ports in docker-compose.yml
```

### Database Connection Issues

```bash
# Recreate database container
docker-compose down -v
docker-compose up db
docker-compose run web bin/rails db:create db:migrate db:seed
```

### Asset Compilation Issues

```bash
# Precompile assets
docker-compose run web bin/rails assets:precompile

# Clear cache
docker-compose run web bin/rails tmp:cache:clear
```

### Sidekiq Not Processing Jobs

```bash
# Check Sidekiq logs
docker-compose logs sidekiq

# Restart Sidekiq
docker-compose restart sidekiq

# Check Redis connection
docker-compose exec redis redis-cli ping
```

## ✅ Features Checklist

- [x] RESTful API with proper HTTP methods
- [x] Authentication (Devise)
- [x] Authorization (Pundit)
- [x] Admin Dashboard with statistics
- [x] User CRUD operations
- [x] Role management (Admin/User)
- [x] Spreadsheet import (CSV/XLSX)
- [x] Real-time updates (Action Cable)
- [x] Background jobs (Sidekiq)
- [x] Avatar uploads (file and URL)
- [x] Responsive design (Bootstrap 5)
- [x] Form validations (frontend and backend)
- [x] Tests with 90%+ coverage
- [x] Security measures (XSS, CSRF, SQL Injection)
- [x] Docker & Docker Compose
- [x] Linters (RuboCop)
- [x] Security scanning (Brakeman)
- [x] Multi-browser support
- [x] SCSS organization
- [x] .gitignore & .dockerignore

---

**Happy Coding! 🎉**
