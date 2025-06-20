import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["suggestions"]
  static values = { url: String }

  connect() {
    this.debounceTimer = null
    this.selectedIndex = -1
    
    // Add event listeners
    this.element.addEventListener('keydown', this.keydown.bind(this))
    document.addEventListener('click', this.clickOutside.bind(this))
  }

  disconnect() {
    // Clean up event listeners
    document.removeEventListener('click', this.clickOutside.bind(this))
  }

  suggest(event) {
    const query = event.target.value.trim()
    
    // Clear previous timer
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }

    // Hide suggestions if query is empty
    if (query.length === 0) {
      this.hideSuggestions()
      return
    }

    // Debounce the search
    this.debounceTimer = setTimeout(() => {
      this.fetchSuggestions(query)
    }, 300)
  }

  async fetchSuggestions(query) {
    try {
      this.showLoading()
      const response = await fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`)
      const suggestions = await response.json()
      this.hideLoading()
      this.showSuggestions(suggestions)
    } catch (error) {
      this.hideLoading()
      console.error('Error fetching suggestions:', error)
    }
  }

  showSuggestions(suggestions) {
    const suggestionsElement = this.suggestionsTarget
    
    if (suggestions.length === 0) {
      suggestionsElement.innerHTML = `
        <div class="px-4 py-2 text-sm text-gray-500">
          No suggestions found
        </div>
      `
    } else {
      suggestionsElement.innerHTML = suggestions.map((suggestion, index) => `
        <div class="suggestion-item px-4 py-2 hover:bg-gray-100 cursor-pointer text-sm" 
             data-index="${index}"
             data-value="${suggestion.value}"
             data-type="${suggestion.type}">
          <div class="flex items-center">
            <span class="text-gray-400 mr-2">${this.getTypeIcon(suggestion.type)}</span>
            <span class="font-medium">${suggestion.label}</span>
            <span class="ml-auto text-xs text-gray-500">${suggestion.type}</span>
          </div>
        </div>
      `).join('')
    }
    
    suggestionsElement.classList.remove('hidden')
    this.bindSuggestionEvents()
  }

  hideSuggestions() {
    this.suggestionsTarget.classList.add('hidden')
    this.selectedIndex = -1
  }

  bindSuggestionEvents() {
    const items = this.suggestionsTarget.querySelectorAll('.suggestion-item')
    
    items.forEach((item, index) => {
      item.addEventListener('click', () => {
        this.selectSuggestion(item.dataset.value)
      })
      
      item.addEventListener('mouseenter', () => {
        this.selectedIndex = index
        this.updateSelection()
      })
    })
  }

  selectSuggestion(value) {
    const input = this.element.querySelector('input[type="text"]')
    input.value = value
    this.hideSuggestions()
    input.focus()
  }

  updateSelection() {
    const items = this.suggestionsTarget.querySelectorAll('.suggestion-item')
    items.forEach((item, index) => {
      if (index === this.selectedIndex) {
        item.classList.add('bg-blue-50', 'border-l-4', 'border-blue-500')
      } else {
        item.classList.remove('bg-blue-50', 'border-l-4', 'border-blue-500')
      }
    })
  }

  getTypeIcon(type) {
    const icons = {
      'action': '⚡',
      'event_type': '📊',
      'actor': '👤',
      'subject': '🎯',
      'correlation': '🔗'
    }
    return icons[type] || '🔍'
  }

  // Handle keyboard navigation
  keydown(event) {
    const items = this.suggestionsTarget.querySelectorAll('.suggestion-item')
    
    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault()
        this.selectedIndex = Math.min(this.selectedIndex + 1, items.length - 1)
        this.updateSelection()
        break
      case 'ArrowUp':
        event.preventDefault()
        this.selectedIndex = Math.max(this.selectedIndex - 1, -1)
        this.updateSelection()
        break
      case 'Enter':
        if (this.selectedIndex >= 0) {
          event.preventDefault()
          const selectedItem = items[this.selectedIndex]
          this.selectSuggestion(selectedItem.dataset.value)
        }
        break
      case 'Escape':
        this.hideSuggestions()
        break
    }
  }

  // Hide suggestions when clicking outside
  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideSuggestions()
    }
  }

  showLoading() {
    const suggestionsElement = this.suggestionsTarget
    suggestionsElement.innerHTML = `
      <div class="px-4 py-3 flex items-center justify-center">
        <div class="search-loading"></div>
        <span class="ml-2 text-sm text-gray-500">Searching...</span>
      </div>
    `
    suggestionsElement.classList.remove('hidden')
  }

  hideLoading() {
    // Loading state will be replaced by suggestions or hidden
  }
} 