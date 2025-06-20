FactoryBot.define do
  factory :event_pattern do
    name { "MyString" }
    pattern { "" }
    description { "MyText" }
    is_active { false }
  end
end
