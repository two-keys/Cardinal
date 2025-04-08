# frozen_string_literal: true

module Taggable
  extend ActiveSupport::Concern

  def tags_for(polarity)
    polarity_tags = {}

    tag_schema = TagSchema.get_schema(model_name.plural)
    # get valid tag types for this model's polarity section
    tag_schema.types_for(polarity).each do |tag_type|
      # add those tags falling under polarity -> tag type
      polarity_tags[tag_type] = tags.where(polarity:, tag_type:)
    end

    polarity_tags
  end

  def self.tags_for(polarity, tagset)
    return nil if tagset.nil?

    polarity_tags = {}

    tag_ids = tagset.map(&:tag_id)
    raw_tags = Tag.where(
      id: tag_ids
    )

    tag_schema = TagSchema.get_schema(model_name.plural)
    # get valid tag types for this model's polarity section
    tag_schema.types_for(polarity).each do |tag_type|
      # add those tags falling under polarity -> tag type
      polarity_tags[tag_type] = raw_tags.where(polarity:, tag_type:)
    end

    polarity_tags
  end

  def entries_for(polarity, tag_type)
    checked_entries = tags.where(
      name: TagSchema.entries_for(tag_type)
    ).where(
      polarity:, tag_type:
    ).pluck(:name)
    TagSchema.entries_for(tag_type).map do |entry|
      {
        name: entry,
        checked: checked_entries.include?(entry)
      }
    end
  end

  def fill_ins_for(polarity, tag_type)
    tags.where.not(
      name: TagSchema.entries_for(tag_type)
    ).where(
      polarity:, tag_type:
    ).pluck(:name, :tooltip, :details, :id)
  end

  private

  # Collapses our tags
  def collapse_list
    tags.each do |tag|
      if tag.synonym.nil? # If a tag has no synonym, we can just add its ancestors directly.
        add_ancestors tag
      else # If a tag has a synonym, we need to delete/replace
        tags.delete(tag)
        syn = tag.synonym
        next if tags.exists?(syn.id)

        tags << syn
        # We assume a tag only ever points to a tag without its own synonym, hence no synonym chaining.
        add_ancestors syn
      end
    end
  end

  def add_ancestors(tag)
    tag.ancestors.each do |ancy|
      tags << ancy unless tags.exists?(ancy.id) # We don't want duplicate entries.
    end
  end

  # Adds tags outside of the normal synonym/parent ecosystem.
  def add_meta_tags
    tag_schema = TagSchema.get_schema(model_name.plural)

    # An array of strings representing the tag types present in this prompt
    calculated_types = tags.pluck(:tag_type).to_a.uniq

    tag_type_hashes = TagSchema::TAG_SCHEMA_HASH['tag_types']

    # an array of tag types with parents
    cardinal_types = tag_schema.types.select do |tag_type|
      tag_type_hashes[tag_type]['parent'].present?
    end

    calculated_types.each do |calc_type|
      has_parent = cardinal_types.include?(calc_type)
      # logger.debug "#{calc_type} has_parent = #{has_parent}"
      next unless has_parent

      # get pieces of parent
      tag_components = tag_type_hashes[calc_type]['parent']

      new_parent = Tag.find_or_create_with_downcase(
        polarity: tag_components['polarity'],
        tag_type: tag_components['type'],
        name: tag_components['name']
      )
      next if tags.exists?(new_parent.id)

      tags << new_parent
    end
  end

  # Should be replaced by a polymorphic function if we add tags to things besides prompts
  def remove_disabled_tags_from_prompts
    object_tags.includes(:tag).where(tag: { enabled: false }).delete_all
  end
end
