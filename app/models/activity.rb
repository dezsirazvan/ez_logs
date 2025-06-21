class Activity < ApplicationRecord
  belongs_to :user
  belongs_to :company

  # Validations
  validates :action, presence: true, length: { maximum: 100 }
  validates :resource_type, presence: true, length: { maximum: 50 }
  validates :resource_id, presence: true
  validates :ip_address, length: { maximum: 45 }
  validates :user_agent, length: { maximum: 500 }
  validates :metadata, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user) { where(user: user) }
  scope :by_company, ->(company) { where(company: company) }
  scope :by_action, ->(action) { where(action: action) }
  scope :by_resource, ->(resource_type, resource_id) { where(resource_type: resource_type, resource_id: resource_id) }
  scope :by_resource_type, ->(resource_type) { where(resource_type: resource_type) }
  scope :today, -> { where(created_at: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :this_week, -> { where(created_at: 1.week.ago..Time.current) }
  scope :this_month, -> { where(created_at: 1.month.ago..Time.current) }
  scope :in_date_range, ->(start_date, end_date) { where(created_at: start_date..end_date) }

  # Pagination
  def self.page(page_number)
    page_num = [page_number.to_i, 1].max  # Ensure page number is at least 1
    limit(20).offset((page_num - 1) * 20)
  end

  def self.per(per_page)
    limit(per_page)
  end

  # Class methods for logging activities
  def self.log_login(user, ip_address: nil, user_agent: nil)
    create!(
      user: user,
      company: user.company,
      action: 'login',
      resource_type: 'User',
      resource_id: user.id,
      ip_address: ip_address,
      user_agent: user_agent,
      metadata: { success: true, method: 'password' }
    )
  rescue => e
    Rails.logger.error "Failed to log login activity: #{e.message}"
  end

  def self.log_logout(user, ip_address: nil)
    create!(
      user: user,
      company: user.company,
      action: 'logout',
      resource_type: 'User',
      resource_id: user.id,
      ip_address: ip_address,
      user_agent: nil,
      metadata: { success: true }
    )
  rescue => e
    Rails.logger.error "Failed to log logout activity: #{e.message}"
  end

  def self.log_profile_updated(user, changes: [], ip_address: nil, user_agent: nil)
    create!(
      user: user,
      company: user.company,
      action: 'profile_updated',
      resource_type: 'User',
      resource_id: user.id,
      ip_address: ip_address,
      user_agent: user_agent,
      metadata: { changes: changes }
    )
  rescue => e
    Rails.logger.error "Failed to log profile update activity: #{e.message}"
  end

  def self.log_events_viewed(user, filter: nil, count: 0, ip_address: nil, user_agent: nil)
    create!(
      user: user,
      company: user.company,
      action: 'events_viewed',
      resource_type: 'Event',
      resource_id: nil,
      ip_address: ip_address,
      user_agent: user_agent,
      metadata: { filter: filter, count: count }
    )
  rescue => e
    Rails.logger.error "Failed to log events viewed activity: #{e.message}"
  end

  def self.log_api_key_created(user, api_key, ip_address: nil, user_agent: nil)
    create!(
      user: user,
      company: user.company,
      action: 'api_key_created',
      resource_type: 'ApiKey',
      resource_id: api_key.id,
      ip_address: ip_address,
      user_agent: user_agent,
      metadata: { 
        api_key_name: api_key.name,
        permissions: api_key.permissions
      }
    )
  rescue => e
    Rails.logger.error "Failed to log API key creation activity: #{e.message}"
  end

  def self.log_api_key_revoked(user, api_key, ip_address: nil, user_agent: nil)
    create!(
      user: user,
      company: user.company,
      action: 'api_key_revoked',
      resource_type: 'ApiKey',
      resource_id: api_key.id,
      ip_address: ip_address,
      user_agent: user_agent,
      metadata: { 
        api_key_name: api_key.name,
        reason: 'user_request'
      }
    )
  rescue => e
    Rails.logger.error "Failed to log API key revocation activity: #{e.message}"
  end

  def self.log_backup_codes_regenerated(user, ip_address: nil, user_agent: nil)
    create!(
      user: user,
      company: user.company,
      action: 'backup_codes_regenerated',
      resource_type: 'User',
      resource_id: user.id,
      ip_address: ip_address,
      user_agent: user_agent,
      metadata: { reason: 'user_request' }
    )
  rescue => e
    Rails.logger.error "Failed to log backup codes regeneration activity: #{e.message}"
  end

  # Instance methods
  def display_action
    action.humanize
  end

  def display_resource_type
    resource_type.humanize
  end

  def short_user_agent
    return nil unless user_agent.present?
    
    if user_agent.include?('Mozilla')
      'Web Browser'
    elsif user_agent.include?('curl')
      'cURL'
    elsif user_agent.include?('Postman')
      'Postman'
    else
      user_agent.truncate(30)
    end
  end

  def formatted_created_at
    created_at.strftime('%Y-%m-%d %H:%M:%S')
  end

  def formatted_ip_address
    return 'Unknown' unless ip_address.present?
    ip_address
  end
end
