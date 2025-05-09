import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["body"]
  static values  = { per: Number }

  connect() {
    this.perValue ||= 50
    this.loadEvents()
    this.interval = setInterval(() => this.loadEvents(), 5000)
  }

  disconnect() {
    clearInterval(this.interval)
  }

  loadEvents() {
    fetch(`/api/events?per=${this.perValue}`)
      .then(res => res.json())
      .then(events => {
        this.bodyTarget.innerHTML =
          events.map(e => this.rowTemplate(e)).join("")
      })
      .catch(err => console.error("Error fetching events:", err))
  }

  rowTemplate(e) {
    return `
      <tr>
        <td>${new Date(e.timestamp).toLocaleString()}</td>
        <td>${e.actor}</td>
        <td>${e.action}</td>
        <td>${e.resource}</td>
        <td>${e.event_type}</td>
        <td>${e.correlation_id}</td>
      </tr>
    `
  }
}
