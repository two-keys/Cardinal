class ChatsUser < ApplicationRecord
    belongs_to :user
    belongs_to :chat

    enum status: {
        ongoing: 0,
        unanswered: 1,
        unread: 2,
        ended: 3
    }
end