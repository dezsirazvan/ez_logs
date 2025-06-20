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
    const actor = e.actor_type && e.actor_id ? `${e.actor_type}: ${e.actor_id}` : 'Unknown Actor'
    const subject = e.subject_type && e.subject_id ? `${e.subject_type}: ${e.subject_id}` : 'N/A'
    
    return `
      <tr>
        <td>${new Date(e.timestamp || e.created_at).toLocaleString()}</td>
        <td>${actor}</td>
        <td>${e.action}</td>
        <td>${subject}</td>
        <td>${e.event_type}</td>
        <td>${e.correlation_id || 'N/A'}</td>
      </tr>
    `
  }
}
