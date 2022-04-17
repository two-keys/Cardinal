# frozen_string_literal: true

require 'yaml'

# A collection of static classes which allow access to the SETTINGS_HASH
module CardinalSettings
  default_hash = YAML.load_file(Rails.root.join('config/default_settings.yml'))

  # if FORCE_DEFAULT is set, rails will load default settings
  use_dynamic = Rails.root.join('config/dynamic_settings.yml').exist?
  use_dynamic = false if ENV['FORCE_DEFAULT'].present?

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

  # A collection of methods simplifying access to the tags hash within SETTINGS_HASH
  class Tags
    # rubocop:disable Style/ClassVars

    # Better to do thsi once instead of every time we call polarities in Tags
    # Since we aren't going to inherit this class anywhere, it's fine to use class variables here.
    @@calculated_polarities = []
    # rubocop:enable Style/ClassVars
    SETTINGS_HASH['tags']['types'].each_key do |key|
      type = SETTINGS_HASH['tags']['types'][key]
      type['polarities'].each do |polarity|
        @@calculated_polarities << polarity unless @@calculated_polarities.include?(polarity)
      end
    end

    def self.tags_hash
      SETTINGS_HASH['tags']
    end

    def self.types
      tags_hash['types']
    end

    # This generates a hash of symbols to arrays based on the keys in CardinalSettings::Tags.types
    # Using the double splat operator through params, this allows us to limit tag input to
    # 1. in keys in types hash and 2. one of PERMITTED_SCALAR_TYPES see https://api.rubyonrails.org/classes/ActionController/Parameters.html
    # Anything else fails.
    def self.allowed_type_params
      atp = {}
      polarities.each do |polarity|
        allowed_types = {}

        types.each do |key, type_hash|
          # Add each tag_type to polarity
          allowed_types[key.to_sym] = [] if type_hash['polarities'].include?(polarity)
        end
        atp[polarity] = allowed_types
      end
      atp.symbolize_keys
    end

    def self.polarities
      @@calculated_polarities
    end

    def self.polarities_for(tag_type)
      return [] unless types.key? tag_type

      types[tag_type]['polarities']
    end

    def self.null_tag
      null_hash = tags_hash['nullify_tag']
      Tag.create_or_find_by(
        name: null_hash['name'],
        tag_type: null_hash['type'],
        polarity: null_hash['polarity'],
        enabled: false
      )
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
