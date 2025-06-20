FactoryBot.define do
  factory :api_key do
    user { nil }
    name { "MyString" }
    key_hash { "MyString" }
    permissions { "" }
    last_used_at { "2025-06-20 14:57:45" }
    expires_at { "2025-06-20 14:57:45" }
  end
end
