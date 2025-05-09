import { Application } from "@hotwired/stimulus"
import EventsController from "./events_controller"

const application = Application.start()
application.register("events", EventsController)

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }
