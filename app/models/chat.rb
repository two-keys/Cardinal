class Chat < ApplicationRecord
    has_many :chats_users, dependent: :delete_all
    has_many :users, through: :chats_users
    has_many :messages, dependent: :destroy
    has_one :connect_code, dependent: :destroy
end
