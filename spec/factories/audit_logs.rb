FactoryBot.define do
  factory :audit_log do
    user { nil }
    action { "MyString" }
    resource_type { "MyString" }
    resource_id { "MyString" }
    details { "" }
    ip_address { "MyString" }
    user_agent { "MyString" }
  end
end
