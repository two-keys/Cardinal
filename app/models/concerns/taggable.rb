# frozen_string_literal: true

module Taggable
  extend ActiveSupport::Concern

  def tags_for(polarity)
    polarity_tags = {}
    raw_polarity_tags = tags.where(
      polarity: polarity
    )

    CardinalSettings::Tags.types.each do |tag_type, tag_hash|
      next unless tag_hash['polarities'].include? polarity

      polarity_type_tags = raw_polarity_tags.filter do |tag|
        tag.tag_type == tag_type
      end
      polarity_tags[tag_type] = polarity_type_tags unless polarity_type_tags.empty?
    end

    polarity_tags
  end

  def entries_for(polarity, tag_type)
    checked_entries = tags.where(
      name: CardinalSettings::Tags.types[tag_type]['entries']
    ).where(
      polarity: polarity, tag_type: tag_type
    ).pluck(:name)
    CardinalSettings::Tags.types[tag_type]['entries'].map do |entry|
      {
        name: entry,
        checked: checked_entries.include?(entry)
      }
    end
  end

  def fill_ins_for(polarity, tag_type)
    tags.where.not(
      name: CardinalSettings::Tags.types[tag_type]['entries']
    ).where(
      polarity: polarity, tag_type: tag_type
    ).pluck(:name)
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
    # An array of strings representing the tag types present in this prompt
    calculated_types = tags.select(:tag_type).group(:tag_type).pluck(:tag_type)
    # A hash of type hashes from our site settings. Only includes those with parents
    cardinal_types = CardinalSettings::Tags.types.select do |_k, v|
      v['parent'].present?
    end

    calculated_types.each do |calc_type|
      next unless cardinal_types.key?(calc_type)

      # Array of form [<tag_type>, <tag_lower_name>]
      tag_components = cardinal_types[calc_type]['parent']

      new_parent = Tag.find_or_create_by(
        tag_type: tag_components['type'],
        name: tag_components['name'],
        polarity: tag_components['polarity']
      )
      tags << new_parent unless tags.exists?(new_parent.id)
    end
  end

  # Should be replaced by a polymorphic function if we add tags to things besides prompts
  def remove_disabled_tags_from_prompts
    prompt_tags.includes(:tag).where(tag: { enabled: false }).delete_all
  end
end
