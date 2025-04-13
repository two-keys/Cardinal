# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module SearchHelper
  def self.get_oc_string(obj_class)
    oc_string = ''
    # brakeman really hates string interpolation being used to construct strings
    # even when its 99% safe, so we have to roundabout this
    case obj_class.name
    when 'Prompt'
      oc_string = '"object_characters"."object_type" = \'Prompt\'
        AND "object_characters"."object_id" = "prompts"."id"'
    end

    oc_string
  end

  def self.get_ot_string(obj_class)
    ot_string = ''
    # brakeman really hates string interpolation being used to construct strings
    # even when its 99% safe, so we have to roundabout this
    case obj_class.name
    when 'Prompt'
      ot_string = '"object_tags"."object_type" = \'Prompt\' AND "object_tags"."object_id" = "prompts"."id"'
    when 'Character'
      ot_string =
        '"object_tags"."object_type" = \'Character\' AND "object_tags"."object_id" = "characters"."id"'
    end

    ot_string
  end

  # This is the ugliest code I've ever written,
  # but it should be fine as long we don't do string interpolation anywhere
  def self.filter_query(
    query,
    current_user,
    obj_class,
    characterized
  )
    object_tag_string = get_ot_string(obj_class)
    object_character_string = get_oc_string(obj_class)

    f2 = Filter.arel_table.alias
    query.where.not(
      # We want prompts that don't have a tag mathcing a Rejection filter
      Filter.where(
        # Do any of the prompt's tags hit the rejection filter?
        '"filters"."target_type" = \'Tag\' AND "filters"."target_id" IN (?)',
        ObjectTag.where(object_tag_string).or(
          # sub-search for character tags if characterized
          ObjectTag.where('? = TRUE', characterized)
          .where(
            object_type: 'Character',
            object_id: ObjectCharacter.where(
              object_character_string
            ).select(:character_id)
          )
        ).select(:tag_id)
      ).where(
        # We could theoretically let people specify the specific filters they want to match,
        # but that sounds like a pain
        # `group: ['default', etc...]`
        filter_type: 'Rejection',
        user: current_user
      ).where.not(
        # If a prompt DOES have a tag matching a Rejection filter,
        # we can let that slide IF an Exception filter in the same group overrides that
        Filter.from(f2).select('"filters_2".*').where(
          # Same check as above, but Rails doesn't have a clean table alias feature even with arel_table
          '"filters_2"."target_type" = \'Tag\' AND "filters_2"."target_id" IN (?)',
          ObjectTag.where(object_tag_string).or(
            # sub-search for character tags if characterized
            ObjectTag.where('? = TRUE', characterized)
            .where(
              object_type: 'Character',
              object_id: ObjectCharacter.where(
                object_character_string
              ).select(:character_id)
            )
          ).select(:tag_id)
        ).where(
          '"filters_2"."filter_type" = ?', 'Exception'
        ).where(
          # as above so below
          '"filters_2"."group" = "filters"."group"
          AND "filters_2"."user_id" = "filters"."user_id"'
        ).where(
          # An exception filter with a higher priority always wins within a filter group
          '"filters_2"."priority" >= "filters"."priority"'
        ).arel.exists
      ).arel.exists
    )
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity

  # this is here to help with automated testing
  #
  # @param obj_class [ApplicationRecord]
  # @param query This can be the object in question or an instance of ActiveRecord::Relation
  # @return [ActiveRecord::Relation]
  def self.add_search(
    obj_class,
    current_user,
    current_ability,
    search_params,
    characterized
  )
    object_tag_string = get_ot_string(obj_class)
    object_character_string = get_oc_string(obj_class)

    query = obj_class.accessible_by(current_ability)

    # is this yours?
    if search_params.key?(:ismine)
      query = if search_params[:ismine] == 'true'
                query.where(user: current_user)
              else
                query.where.not(user: current_user)
              end
    end

    # GET /prompts?nottags=meta:type:Violent,polarity:tag_type:name,...
    # NOT search, should run before general AND
    # this ensures you won't see prompts with ANY of the tags in nottags
    if search_params.key?(:nottags)
      # logger.debug search_params[:nottags]
      query_tags = Tag.from_search_params(search_params[:nottags])
      query_tag_ids = query_tags.map(&:id)
      # logger.debug query_tag_ids
      query = query.where(
        'NOT(ARRAY[?]::bigint[] && array(?))', # no overlap
        query_tag_ids,
        # main search for tags
        ObjectTag.where(object_tag_string).or(
          # sub-search for character tags if characterized
          ObjectTag.where('? = TRUE', characterized)
          .where(
            object_type: 'Character',
            object_id: ObjectCharacter.where(
              object_character_string
            ).select(:character_id)
          )
        ).select(:tag_id)
      )
    end

    # GET /prompts?tags=meta:type:Violent,polarity:tag_type:name,...
    # AND search
    if search_params.key?(:tags)
      # logger.debug search_params[:tags]
      query_tags = Tag.from_search_params(search_params[:tags])
      query_tag_ids = query_tags.map(&:id)
      # logger.debug query_tag_ids
      query = query.where(
        'ARRAY[?]::bigint[] <@ array(?)',
        query_tag_ids,
        # main search for tags
        ObjectTag.where(object_tag_string).or(
          # sub-search for character tags if characterized
          ObjectTag.where('? = TRUE', characterized)
          .where(
            object_type: 'Character',
            object_id: ObjectCharacter.where(
              object_character_string
            ).select(:character_id)
          )
        ).select(:tag_id)
      )
    end

    only_showing_mine = search_params.key?(:ismine) && search_params[:ismine] == 'true'
    unless Filter.where(user: current_user).none? || only_showing_mine
      # start filtering
      query = filter_query(query, current_user, obj_class, characterized)
    end

    query # return for further processing
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity
end
# rubocop:enable Metrics/ModuleLength
