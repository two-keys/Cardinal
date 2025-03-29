# frozen_string_literal: true

require 'yaml'

# A collection of static classes which allow access to the SETTINGS_HASH
module CardinalSettings
  default_hash = YAML.load_file(Rails.root.join('config/default_settings.yml'))

  # if FORCE_DEFAULT is set, rails will load default settings
  use_dynamic = Rails.root.join('config/dynamic_settings.yml').exist?
  use_dynamic = false if ENV['FORCE_DEFAULT'].present? || ENV['RAILS_ENV'] == 'test'

  # A hash storing implementation-specific settings, such as tag categories and the site use pages.
  # storing this as a constant. we should avoid directly referencing it unless strictly necessary, though, since method
  # getters are more human readable
  SETTINGS_HASH = (use_dynamic ? YAML.load_file(Rails.root.join('config/dynamic_settings.yml')) : default_hash)
  logger = Logger.new($stdout)

  logger.debug "#{SETTINGS_HASH['type']} settings hash v#{SETTINGS_HASH['version']} with keys: #{SETTINGS_HASH.keys}"

  # A collection of of methods simplifying access to the icons hash within SETTINGS_HASH
  class Icons
    def self.icons_hash
      SETTINGS_HASH['icons']
    end

    def self.icon_blacklist
      icons_hash['icon_blacklist']
    end

    def self.system_icon
      icons_hash['system_icon']
    end
  end

  # A collection of methods simplifying access to the donation hash within SETTINGS_HASH
  class Donation
    def self.donation_hash
      SETTINGS_HASH['donation']
    end

    def self.prices
      donation_hash['prices']
    end

    def self.goals
      donation_hash['goals']
    end

    def self.funding
      donation_hash['funding']
    end
  end

  # A collection of methods simplifying access to the use hash within SETTINGS_HASH
  class Use
    def self.use_hash
      SETTINGS_HASH['use']
    end

    def self.pages
      use_hash['pages']
    end

    def self.get_page(key)
      pages[key]
    end

    def self.get_page_entries(key)
      page = get_page(key)

      entries = []
      entries = get_page(page)['entries'] if page.key?('entries')
      entries
    end

    def self.get_page_titles(key)
      page = get_page(key)

      titles = []
      titles = get_page(page)['titles'] if page.key?('titles')
      titles
    end
  end
end
