FactoryBot.define do
  factory :alert do
    name { "MyString" }
    description { "MyText" }
    alert_type { "MyString" }
    severity { "MyString" }
    conditions { "" }
    enabled { false }
    user { nil }
  end
end
