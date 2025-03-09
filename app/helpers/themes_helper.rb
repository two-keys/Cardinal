# frozen_string_literal: true

module ThemesHelper
  require 'sanitize'

  def sanitize_user_css(css)
    valid_properties = %w[
      --main-bg-color
      --main-text-color
      --header-bg-color
      --card-bg-color
      --card-text-color
      --card-bg-color-secondary
      --card-text-color-secondary
      --card-textarea-bg-color
      --card-textarea-text-color
      --tag-generic
      --tag-generic-text
      --tag-genre
      --tag-genre-text
      --tag-gender
      --tag-gender-text
      --tag-character
      --tag-character-text
      --tag-characteristic
      --tag-characteristic-text
      --tag-setting
      --tag-setting-text
      --tag-post-length
      --tag-post-length-text
      --tag-rp-length
      --tag-rp-length-text
      --tag-character-pref
      --tag-character-pref-text
      --tag-plot
      --tag-plot-text
      --tag-theme
      --tag-theme-text
      --tag-detail
      --tag-detail-text
      --tag-fandom
      --tag-fandom-text
      --tag-light-warning
      --tag-light-warning-text
      --tag-heavy-warning
      --tag-heavy-warning-text
      --ongoing-color
      --unread-color
      --unanswered-color
      --ended-color
      --nav-bg-color
    ]

    css = sanitize(css, tags: [])

    Sanitize::CSS.stylesheet(css, Sanitize::Config.merge(Sanitize::Config::RELAXED,
                                                         css: { properties: Sanitize::Config::RELAXED[:css][:properties] + valid_properties }, # rubocop:disable Layout/LineLength
                                                         remove_contents: true))
  end
end
