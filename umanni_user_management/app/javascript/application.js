// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import * as ActionCable from "@rails/actioncable"

// Create global Action Cable consumer
window.Cable = ActionCable.createConsumer()
