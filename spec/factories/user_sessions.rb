FactoryBot.define do
  factory :user_session do
    user { nil }
    session_token { "MyString" }
    expires_at { "2025-06-20 14:57:39" }
    ip_address { "MyString" }
    user_agent { "MyString" }
    last_activity_at { "2025-06-20 14:57:39" }
  end
end
