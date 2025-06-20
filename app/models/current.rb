class Current < ActiveSupport::CurrentAttributes
  attribute :user
  attribute :user_agent
  attribute :ip_address
  attribute :request_id
end
