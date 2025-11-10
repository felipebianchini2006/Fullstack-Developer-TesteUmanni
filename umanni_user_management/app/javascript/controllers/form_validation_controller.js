import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "submit"]

  connect() {
    if (this.hasFormTarget) {
      this.formTarget.setAttribute("novalidate", true)
    }
  }

  validate(event) {
    if (this.hasFormTarget && !this.formTarget.checkValidity()) {
      event.preventDefault()
      event.stopPropagation()
      this.showErrors()
    }

    this.formTarget.classList.add("was-validated")
  }

  showErrors() {
    const invalidFields = this.formTarget.querySelectorAll(":invalid")

    invalidFields.forEach((field) => {
      const feedback = field.parentElement.querySelector(".invalid-feedback")
      if (feedback) {
        feedback.style.display = "block"
      }
    })

    // Scroll to first error
    if (invalidFields.length > 0) {
      invalidFields[0].scrollIntoView({ behavior: "smooth", block: "center" })
      invalidFields[0].focus()
    }
  }

  clearValidation() {
    if (this.hasFormTarget) {
      this.formTarget.classList.remove("was-validated")
    }
  }
}
