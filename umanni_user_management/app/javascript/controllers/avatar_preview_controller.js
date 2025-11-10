import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview"]

  preview(event) {
    const file = event.target.files[0]

    if (file && file.type.startsWith("image/")) {
      const reader = new FileReader()

      reader.onload = (e) => {
        if (this.hasPreviewTarget) {
          this.previewTarget.src = e.target.result
        }
      }

      reader.readAsDataURL(file)
    }
  }
}
