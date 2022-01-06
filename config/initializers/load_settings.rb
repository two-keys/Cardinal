# frozen_string_literal: true

require 'yaml'

# A collection of static classes which allow access to the SETTINGS_HASH
module CardinalSettings
  attr_accessor :settings_hash

  default_hash = Rails.root.join('config/default_settings.yml')

  # A hash storing implementation-specific settings, such as tag categories and the site use pages.
  has_dynamic_settings = Rails.root.join('config/dynamic_settings.yml').exist?

  # storing this as a constant. we should avoid directly referencing it unless strictly necessary, though, since method
  # getters are more human readable
  SETTINGS_HASH = (has_dynamic_settings ? YAML.load_file(Rails.root.join('config/dynamic_settings.yml')) : default_hash)
  if ENV.fetch('RAILS_ENV', 'development') == 'development'
    logger = Logger.new($stdout)

    logger.debug "settings hash: #{SETTINGS_HASH.keys}"
    logger.debug "Rules have entries: #{SETTINGS_HASH['use']['pages']['rules'].key?('entries')}"
  end

  # A collection of methods simplifying access to the tags hash within SETTINGS_HASH
  class Tags
    def self.tags_hash
      SETTINGS_HASH['tags']
    end

    def self.types
      tags_hash['types']
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
  end
end

CardinalSettings::Tags.methods
