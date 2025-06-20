// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"

// Manually load controllers since @hotwired/stimulus-loading is not available
// This will be handled by the importmap pin_all_from directive
