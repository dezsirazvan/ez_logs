FactoryBot.define do
  factory :invitation do
    email { "MyString" }
    team { nil }
    role { nil }
    invited_by { nil }
    status { "MyString" }
    expires_at { "2025-06-20 15:02:00" }
    token { "MyString" }
  end
end
