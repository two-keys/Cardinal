# frozen_string_literal: true

module ThemesHelper
  require 'sanitize'

  def sanitize_user_css(css)
    valid_at_rules = %w[
      apply
      font-face
    ]
    valid_properties = %w[
      --color-primary
      --color-primary-content
      --color-header
      --color-header-content
      --color-secondary
      --color-secondary-content
      --color-tertiary
      --color-tertiary-content
      --color-input
      --color-input-content
      --color-ongoing
      --color-unread
      --color-unanswered
      --color-ended
      --color-generic
      --color-generic-content
      --color-genre
      --color-genre-content
      --color-gender
      --color-gender-content
      --color-character
      --color-character-content
      --color-characteristic
      --color-characteristic-content
      --color-setting
      --color-setting-content
      --color-post-length
      --color-post-length-content
      --color-rp-length
      --color-rp-length-content
      --color-character-pref
      --color-character-pref-content
      --color-plot
      --color-plot-content
      --color-theme
      --color-theme-content
      --color-detail
      --color-detail-content
      --color-fandom
      --color-fandom-content
      --color-light-warning
      --color-light-warning-content
      --color-heavy-warning
      --color-heavy-warning-content
      --color-nav
      --color-nav-content
      --radius-primary
      --radius-secondary
      --home-image
      --directory-image
      --notifications-image
      --admin-image
      --user-image
      --donate-image
      --use-image
      --community-image
      --logout-image
      --login-image
      --register-image
      row-gap
    ]

    css = sanitize(css, tags: [])

    sanitized_css = Sanitize::CSS.stylesheet(css, Sanitize::Config.merge(Sanitize::Config::RELAXED,
                                                                         css: {
                                                                           properties: Sanitize::Config::RELAXED[:css][:properties] + valid_properties, # rubocop:disable Layout/LineLength
                                                                           at_rules_with_properties: Sanitize::Config::RELAXED[:css][:at_rules_with_properties] + valid_at_rules # rubocop:disable Layout/LineLength
                                                                         },
                                                                         remove_contents: true))
    sanitized_css.gsub('{}', ';')
  end
end
