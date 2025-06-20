FactoryBot.define do
  factory :event_translation do
    event { nil }
    translated_text { "MyText" }
    ai_model { "MyString" }
    ai_version { "MyString" }
    confidence { "9.99" }
    cache_hash { "MyString" }
    expires_at { "2025-06-20 14:56:55" }
  end
end
