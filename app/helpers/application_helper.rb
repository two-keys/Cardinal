# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend
  require 'digest'

  def icon_for(text)
    return text if text.nil?

    name = name_for_icon(text)
    if text.start_with? '@'
      return ActionController::Base.helpers.image_tag("/#{text.sub('@', '')}.png", class: 'emoji',
                                                                                   draggable: false,
                                                                                   alt: name)
    end
    if text.start_with?('!') || text.start_with?('?')
      return ActionController::Base.helpers.image_tag(text.split('|').last.to_s, class: 'emoji',
                                                                                 draggable: false,
                                                                                 alt: name)
    end

    text
  end

  def name_for_icon(text)
    return text if text.nil?
    return text.sub('@', '').capitalize if text.start_with? '@'
    return text.split('|').first.sub('!', '').capitalize if text.start_with? '!'
    return text.split('|').first.sub('?', '').capitalize if text.start_with? '?'

    Emoji.find_by_unicode(text).name.capitalize.gsub('_', ' ') # rubocop:disable Rails/DynamicFindBy
  end

  def pluralize_without_count(count, noun, text = nil)
    return unless count != 0

    count == 1 ? "#{noun}#{text}" : "#{noun.pluralize}#{text}"
  end

  def require_admin
    return if admin?

    respond_to do |format|
      format.html { redirect_to root_url, notice: 'You are not authorized to perform this action.' }
      format.json { render json: {}, status: :unauthorized }
    end
  end

  def require_active_user
    return if !banned? && !deleted?

    respond_to do |format|
      format.html { redirect_to root_url, notice: 'You are not authorized to perform this action.' }
      format.json { render json: {}, status: :unauthorized }
    end
  end

  def sha256(text)
    Digest::SHA256.hexdigest(text)
  end

  def admin_scope?
    controller.class.name.split('::').first == 'Admin'
  end

  def admin?
    user_signed_in? && current_user.admin?
  end

  def banned?
    user_signed_in? && !current_user.unban_at.nil?
  end

  def deleted?
    user_signed_in? && !current_user.delete_at.nil?
  end
end
