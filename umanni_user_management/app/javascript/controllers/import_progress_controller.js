import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = ["progressBar", "percentage", "status", "processed", "total", "failed"]
  static values = { importJobId: Number }

  connect() {
    if (this.hasImportJobIdValue) {
      this.subscribe()
    }
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  subscribe() {
    const consumer = createConsumer()
    this.subscription = consumer.subscriptions.create(
      {
        channel: "ImportProgressChannel",
        import_job_id: this.importJobIdValue
      },
      {
        connected: () => {
          console.log(`Connected to ImportProgressChannel for job ${this.importJobIdValue}`)
        },

        disconnected: () => {
          console.log("Disconnected from ImportProgressChannel")
        },

        received: (data) => {
          console.log("Import progress data:", data)
          this.updateProgress(data)
        }
      }
    )
  }

  updateProgress(data) {
    if (data.event === "progress") {
      const percentage = data.progress_percentage || 0

      if (this.hasProgressBarTarget) {
        this.progressBarTarget.style.width = `${percentage}%`
        this.progressBarTarget.setAttribute("aria-valuenow", percentage)
      }

      if (this.hasPercentageTarget) {
        this.percentageTarget.textContent = `${percentage.toFixed(1)}%`
      }

      if (this.hasProcessedTarget) {
        this.processedTarget.textContent = data.processed_records || 0
      }

      if (this.hasTotalTarget) {
        this.totalTarget.textContent = data.total_records || 0
      }

      if (this.hasFailedTarget) {
        this.failedTarget.textContent = data.failed_records || 0
      }

      if (this.hasStatusTarget) {
        this.statusTarget.textContent = data.status || "processing"
      }
    } else if (data.event === "completed") {
      this.handleCompletion(data)
    }
  }

  handleCompletion(data) {
    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = "100%"
      this.progressBarTarget.classList.remove("progress-bar-animated")

      if (data.status === "completed") {
        this.progressBarTarget.classList.remove("bg-primary")
        this.progressBarTarget.classList.add("bg-success")
      } else if (data.status === "failed") {
        this.progressBarTarget.classList.remove("bg-primary")
        this.progressBarTarget.classList.add("bg-danger")
      }
    }

    if (this.hasStatusTarget) {
      this.statusTarget.textContent = data.status
    }

    // Show notification
    this.showNotification(data)

    // Reload page after 2 seconds to show updated user list
    setTimeout(() => {
      window.location.reload()
    }, 2000)
  }

  showNotification(data) {
    const message = data.status === "completed"
      ? `Import completed successfully! Processed: ${data.processed_records}, Failed: ${data.failed_records}`
      : `Import failed: ${data.error_messages}`

    const alertClass = data.status === "completed" ? "alert-success" : "alert-danger"

    const notification = document.createElement("div")
    notification.className = `alert ${alertClass} alert-dismissible fade show`
    notification.setAttribute("role", "alert")
    notification.innerHTML = `
      ${message}
      <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    `

    const container = document.querySelector(".flash-messages") || document.body
    container.appendChild(notification)

    setTimeout(() => {
      notification.remove()
    }, 5000)
  }
}
