# frozen_string_literal: true

class Integer
  def to_filesize
    {
      'B' => 1024,
      'KB' => 1024 * 1024,
      'MB' => 1024 * 1024 * 1024,
      'GB' => 1024 * 1024 * 1024 * 1024,
      'TB' => 1024 * 1024 * 1024 * 1024 * 1024
    }.each_pair { |e, s| return "#{(to_f / (s / 1024)).round(2)}#{e}" if self < s }
  end
end

module ApplicationHelper
  include Pagy::Frontend
  require 'digest'

  def full_title(page_title = '')
    base_title = 'Cardinal'
    if page_title.empty?
      base_title
    else
      "#{page_title} | #{base_title}"
    end
  end

  def icon_for(text)
    return text if text.nil?

    name = name_for_icon(text)
    if text.start_with? '@'
      return ActionController::Base.helpers.image_tag("/#{text.sub('@', '')}.png", class: 'emoji not-prose',
                                                                                   draggable: false,
                                                                                   alt: name)
    end
    if text.start_with?('!') || text.start_with?('?')
      return ActionController::Base.helpers.image_tag(text.split('|').last.to_s, class: 'emoji not-prose',
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

  def user_time(time)
    time.in_time_zone(current_user.time_zone)
  end

  def system_time(time)
    time.in_time_zone(Time.zone)
  end

  def hms_between(start_time, end_time: Time.zone.now)
    seconds_diff = (start_time - end_time).to_i.abs

    days = seconds_diff / 86_400
    seconds_diff -= days * 86_400

    hours = seconds_diff / 3600
    seconds_diff -= hours * 3600

    minutes = seconds_diff / 60
    seconds_diff -= minutes * 60

    seconds = seconds_diff

    [(days * 24) + hours, minutes, seconds]
  end

  def readable_time(time)
    time.strftime('%a %b %e %Y %r (%Z)')
  end

  def system_time_from_form(dt_param)
    dt = DateTime.iso8601(dt_param).strftime('%F %T')
    ActiveSupport::TimeZone[current_user.time_zone].parse(dt)
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
