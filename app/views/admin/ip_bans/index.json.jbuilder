# frozen_string_literal: true

json.array! @ip_bans, partial: 'ip_bans/ip_ban', as: :ip_ban
