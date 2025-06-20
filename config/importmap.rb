# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo", to: "@hotwired--turbo.js" # @8.0.13
pin "@hotwired/turbo-rails", to: "@hotwired--turbo-rails.js" # @8.0.16
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js" # @3.2.2
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@rails/actioncable/src", to: "@rails--actioncable--src.js" # @8.0.200
