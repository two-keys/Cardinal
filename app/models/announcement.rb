# frozen_string_literal: true

class Announcement < ApplicationRecord
  validates :title, presence: true
  validates :content, presence: true
end
