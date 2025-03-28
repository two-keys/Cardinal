# frozen_string_literal: true

require 'yaml'

# A collection of static classes which allow access to the TAG_SCHEMA_HASH
module TagSchema
  default_hash = YAML.load_file(Rails.root.join('config/default_tag_schema.yml'))

  # if FORCE_DEFAULT is set, rails will load default tags
  use_dynamic = Rails.root.join('config/dynamic_tag_schema.yml').exist?
  use_dynamic = false if ENV['FORCE_DEFAULT'].present? || ENV['RAILS_ENV'] == 'test'

  # A hash storing implementation-specific settings, such as tag categories and the site use pages.
  # storing this as a constant. we should avoid directly referencing it unless strictly necessary, though, since method
  # getters are more human readable
  TAG_SCHEMA_HASH = (use_dynamic ? YAML.load_file(Rails.root.join('config/dynamic_tag_schema.yml')) : default_hash)
  logger = Logger.new($stdout)

  logger.debug(
    "#{TAG_SCHEMA_HASH['type']} tag schema hash v#{TAG_SCHEMA_HASH['version']} with keys: #{TAG_SCHEMA_HASH.keys}"
  )

  def self.get_schema(controller_name)
    schema = nil

    case controller_name
    when 'prompts'
      schema = PromptTagSchema
    when 'characters'
      schema = CharacterTagSchema
    end

    schema
  end

  def self.allowed_types
    types = []

    TagSchema::TAG_SCHEMA_HASH['tag_models'].each do |_m_key, model|
      model['polarities'].each do |_p_key, polarity|
        types.concat(polarity['tag_types'])
      end
    end

    types.uniq
  end

  def self.allowed_types_for(polarity)
    types = []

    TagSchema::TAG_SCHEMA_HASH['tag_models'].each do |_m_key, model|
      types.concat(model['polarities'][polarity]['tag_types']) if model['polarities'].include?(polarity)
    end

    types.uniq
  end

  def self.entries_for(tag_type)
    entries = []

    type_hash = TagSchema::TAG_SCHEMA_HASH['tag_types'][tag_type]
    entries = type_hash['entries'] if type_hash.key?('entries')

    entries
  end

  class BaseTagSchema
    @class_obj = nil

    def self.model_hash
      TAG_SCHEMA_HASH['tag_models'][@class_obj.downcase]
    end

    def self.polarities
      model_hash['polarities'].keys
    end

    def self.types_for(polarity)
      model_hash['polarities'][polarity]['tag_types']
    end

    # Using the double splat operator through params, this allows us to limit tag input to
    # 1. tag_schema types for model and 2. one of PERMITTED_SCALAR_TYPES see https://api.rubyonrails.org/classes/ActionController/Parameters.html
    # Anything else fails.
    def self.allowed_type_params
      atp = {}
      polarities.each do |polarity|
        allowed_types = {}
        types_for(polarity).each do |key|
          allowed_types[key.to_sym] = []
        end
        atp[polarity] = allowed_types
      end
      atp.symbolize_keys
    end
  end

  # A collection of methods simplifying access to the prompt tag schema
  class PromptTagSchema < BaseTagSchema
    @class_obj = 'Prompt'
  end

  # A collection of methods simplifying access to the prompt tag schema
  class CharacterTagSchema < BaseTagSchema
    @class_obj = 'Character'
  end
end
