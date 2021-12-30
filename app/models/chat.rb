class Chat < ApplicationRecord
    require 'securerandom'

    has_many :messages, dependent: :delete_all
    has_many :chat_users, dependent: :delete_all
    has_many :users, through: :chat_users
    has_one :connect_code, dependent: :destroy

    self.implicit_order_column = "created_at"

    before_validation :generate_uuid, on: :create
    validates :uuid, presence: true, uniqueness: true

    def get_user_info(user)
        self.chat_users.find_by(user: user)
    end

    private
        def generate_uuid
            self.uuid = SecureRandom.uuid
        end
end
