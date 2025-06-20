module EventsHelper
  def severity_color(severity)
    case severity&.downcase
    when 'info'
      'bg-blue-100'
    when 'warning'
      'bg-yellow-100'
    when 'error'
      'bg-red-100'
    when 'critical'
      'bg-purple-100'
    else
      'bg-gray-100'
    end
  end

  def severity_badge_color(severity)
    case severity&.downcase
    when 'info'
      'bg-blue-100 text-blue-800'
    when 'warning'
      'bg-yellow-100 text-yellow-800'
    when 'error'
      'bg-red-100 text-red-800'
    when 'critical'
      'bg-purple-100 text-purple-800'
    else
      'bg-gray-100 text-gray-800'
    end
  end

  def severity_icon_color(severity)
    case severity&.downcase
    when 'info'
      'text-blue-600'
    when 'warning'
      'text-yellow-600'
    when 'error'
      'text-red-600'
    when 'critical'
      'text-purple-600'
    else
      'text-gray-600'
    end
  end

  def event_type_color_class(event_type)
    case event_type
    when 'http.request'
      'bg-blue-500'
    when 'data.change'
      'bg-green-500'
    when 'job.execution'
      'bg-purple-500'
    when 'user.action'
      'bg-yellow-500'
    when 'system.event'
      'bg-red-500'
    else
      'bg-gray-500'
    end
  end

  def event_type_icon(event_type)
    case event_type
    when 'http.request'
      '<svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path></svg>'.html_safe
    when 'data.change'
      '<svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4"></path></svg>'.html_safe
    when 'job.execution'
      '<svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>'.html_safe
    when 'user.action'
      '<svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path></svg>'.html_safe
    when 'system.event'
      '<svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path></svg>'.html_safe
    else
      '<svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>'.html_safe
    end
  end
end
