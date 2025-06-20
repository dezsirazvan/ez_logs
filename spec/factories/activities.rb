FactoryBot.define do
  factory :activity do
    user { nil }
    company { nil }
    action { "MyString" }
    resource_type { "MyString" }
    resource_id { "" }
    ip_address { "MyString" }
    user_agent { "MyString" }
    metadata { "" }
  end
end
