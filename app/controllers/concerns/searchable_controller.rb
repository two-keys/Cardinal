# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module SearchableController
  extend ActiveSupport::Concern

  # there's probably a better way to do this but my brain is fried
  included do
    before_action :set_searchable, only: %i[update_tags]
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity

  # this isnt actually an action
  #
  # @param obj_class [ApplicationRecord]
  # @param query This can be the object in question or an instance of ActiveRecord::Relation
  # @return [ActiveRecord::Relation]
  def add_search(obj_class)
    # brakeman really hates string interpolation in sql, even when its 99% safe
    # so we have to roundabout this
    object_tag_string =
      case obj_class.name
      when 'Prompt'
        'object_type = \'Prompt\' AND object_id = "prompts"."id"'
      when 'Character'
        'object_type = \'Character\' AND object_id = "characters"."id"'
      end

    query = obj_class.accessible_by(current_ability)

    # GET /prompts?before=2022-02-17
    if search_params.key?(:before)
      query = if obj_class.method_defined?(:bumpable?)
                query.where(bumped_at: ..search_params[:before])
              else
                query.where(updated_at: ..search_params[:before])
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
        query_tag_ids, ObjectTag.where(object_tag_string).select(:tag_id)
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
        query_tag_ids, ObjectTag.where(object_tag_string).select(:tag_id)
      )
    end

    # GET /prompts
    # This is the ugliest code I've ever written,
    # but it should be fine as long we don't do string interpolation anywhere
    if Filter.exists?(user: current_user)
      f2 = Filter.arel_table.alias
      query = query.where.not(
        # We want prompts that don't have a tag mathcing a Rejection filter
        Filter.where(
          # Do any of the prompt's tags hit the rejection filter?
          '"filters"."tag_id" IN (?)',
          ObjectTag.where(object_tag_string).select(:tag_id)
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
            '"filters_2"."tag_id" IN (?)',
            ObjectTag.where(object_tag_string).select(:tag_id)
          ).where(
            '"filters_2"."filter_type" = ?', 'Exception'
          ).where(
            # as above so below
            '"filters_2"."group" = "filters"."group"',
            '"filters_2"."user_id" = "filters"."user_id"'
          ).where(
            # An exception filter with a higher priority always wins within a filter group
            '"filters_2"."priority" >= "filters"."priority"'
          ).arel.exists
        ).arel.exists
      )
    end

    query # return for further processing
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity

  # GET /prompts/search
  def search; end

  # POST /prompts/search
  def generate_search
    tags = Tag.from_tag_params(tag_params)
    tag_strings = tags.map do |tag|
      "#{tag[:polarity]}:#{tag[:tag_type]}:#{tag[:name]}"
    end

    previous_tag_param_string = search_params.key?('tags') ? "#{search_params[:tags]}," : ''

    new_params = search_params.merge(
      tags: "#{previous_tag_param_string}#{tag_strings.join(',')}"
    ).to_hash # to_hash removes unpermitted keys
    new_url = url_for(
      action: :index,
      controller: self.class.name.downcase.chomp('controller'),
      **new_params
    ).to_s

    redirect_to(
      new_url
    )
  end

  # PATCH/PUT /prompts/1/tags
  def update_tags
    added_tags = @searchable.add_tags(tag_params)

    respond_to do |format|
      if added_tags && @searchable.save
        format.html { redirect_to url_for(@searchable), notice: 'Tags were successfully updated.' }
        format.json { render :show, status: :ok, location: @searchable }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @searchable.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def tag_params
    params.require(:tags).permit(**CardinalSettings::Tags.allowed_type_params)
  end

  def search_params
    params.permit(:before, :tags, :nottags)
  end

  def set_searchable
    case self.class.name
    when 'PromptsController'
      set_prompt
    else
      logger.debug "my case statement name is '#{self.class.name}'"
    end
    @searchable = [@prompt, @character].find(&:present?)
  end
end
# rubocop:enable Metrics/ModuleLength
