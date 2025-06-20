FactoryBot.define do
  factory :role do
    name { "MyString" }
    description { "MyText" }
    permissions { "" }
    is_active { false }
  end
end
