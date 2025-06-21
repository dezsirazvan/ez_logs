module ApplicationHelper
  def severity_color(severity)
    # Since we removed severity enum, default to info color
    'bg-blue-100'
  end

  def severity_badge_color(severity)
    # Since we removed severity enum, default to info badge
    'bg-blue-100 text-blue-800'
  end
end
