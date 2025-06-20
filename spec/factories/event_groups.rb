FactoryBot.define do
  factory :event_group do
    name { "MyString" }
    description { "MyText" }
    similarity_threshold { "9.99" }
    group_hash { "MyString" }
    is_active { false }
  end
end
