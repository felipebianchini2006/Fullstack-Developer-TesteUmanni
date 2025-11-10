import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = ["totalUsers", "totalAdmins", "totalRegularUsers"]

  connect() {
    this.subscribe()
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  subscribe() {
    const consumer = createConsumer()
    this.subscription = consumer.subscriptions.create("DashboardChannel", {
      connected: () => {
        console.log("Connected to DashboardChannel")
      },

      disconnected: () => {
        console.log("Disconnected from DashboardChannel")
      },

      received: (data) => {
        console.log("Received data:", data)
        this.updateCounters(data)
      }
    })
  }

  updateCounters(data) {
    if (data.total_users !== undefined && this.hasTotalUsersTarget) {
      this.animateCounter(this.totalUsersTarget, data.total_users)
    }

    if (data.total_admins !== undefined && this.hasTotalAdminsTarget) {
      this.animateCounter(this.totalAdminsTarget, data.total_admins)
    }

    if (data.total_regular_users !== undefined && this.hasTotalRegularUsersTarget) {
      this.animateCounter(this.totalRegularUsersTarget, data.total_regular_users)
    }
  }

  animateCounter(element, newValue) {
    const currentValue = parseInt(element.textContent) || 0
    const increment = newValue > currentValue ? 1 : -1
    const duration = 500
    const steps = Math.abs(newValue - currentValue)
    const stepDuration = steps > 0 ? duration / steps : 0

    let current = currentValue

    const timer = setInterval(() => {
      current += increment
      element.textContent = current

      if (current === newValue) {
        clearInterval(timer)
        element.classList.add('animate-pulse')
        setTimeout(() => element.classList.remove('animate-pulse'), 600)
      }
    }, stepDuration)
  }
}
