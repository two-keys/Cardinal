class Message < ApplicationRecord
    belongs_to :chat
    belongs_to :user, optional: true

    validates :content, presence: true, length: { minimum: 10, maximum: 10000 }
end
