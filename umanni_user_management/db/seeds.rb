# Seed data for Umanni User Management application
# This file is idempotent and can be run multiple times

puts "🌱 Starting database seed..."

# Clear existing data (optional, comment out if you want to preserve data)
puts "🗑️  Clearing existing data..."
ImportJob.destroy_all
User.destroy_all

# Create admin user
puts "👑 Creating admin user..."
admin = User.find_or_create_by!(email: "admin@example.com") do |user|
  user.full_name = "Admin User"
  user.password = "password"
  user.password_confirmation = "password"
  user.role = :admin
end
puts "   ✓ Admin created: #{admin.email} (password: password)"

# Create regular users with realistic data
puts "👥 Creating regular users..."

users_data = [
  { full_name: "John Doe", email: "john.doe@example.com" },
  { full_name: "Jane Smith", email: "jane.smith@example.com" },
  { full_name: "Robert Johnson", email: "robert.johnson@example.com" },
  { full_name: "Emily Williams", email: "emily.williams@example.com" },
  { full_name: "Michael Brown", email: "michael.brown@example.com" },
  { full_name: "Sarah Davis", email: "sarah.davis@example.com" },
  { full_name: "David Wilson", email: "david.wilson@example.com" },
  { full_name: "Lisa Anderson", email: "lisa.anderson@example.com" },
  { full_name: "James Taylor", email: "james.taylor@example.com" },
  { full_name: "Jennifer Martinez", email: "jennifer.martinez@example.com" }
]

users_data.each do |user_data|
  user = User.find_or_create_by!(email: user_data[:email]) do |u|
    u.full_name = user_data[:full_name]
    u.password = "password"
    u.password_confirmation = "password"
    u.role = :user
  end
  puts "   ✓ User created: #{user.email}"
end

puts "\n✅ Seed completed successfully!"
puts "\n📊 Summary:"
puts "   Total users: #{User.count}"
puts "   Admins: #{User.where(role: :admin).count}"
puts "   Regular users: #{User.where(role: :user).count}"
puts "\n🔑 Login credentials:"
puts "   Admin: admin@example.com / password"
puts "   User: john.doe@example.com / password"
