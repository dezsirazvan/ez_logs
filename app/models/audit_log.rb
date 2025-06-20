class AuditLog < ApplicationRecord
  belongs_to :company
  belongs_to :user, optional: true

  validates :action, presence: true
end
