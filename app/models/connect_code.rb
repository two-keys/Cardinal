class ConnectCode < ApplicationRecord
    belongs_to :user
    belongs_to :chat

    validates :remaining_uses, numericality: { only_integer: true, less_than_or_equal_to: 10 }

    def use(user)
        if self.remaining_uses > 0
            self.remaining_uses -= 1
            self.chat.users << user
            self.save
            return true
        else
            return false
        end
    end
end
