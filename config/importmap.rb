# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

pin 'application', preload: true
pin '@hotwired/turbo-rails', to: 'turbo.min.js', preload: true
pin '@hotwired/stimulus', to: 'stimulus.min.js', preload: true
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js', preload: true

pin 'jquery', to: 'https://ga.jspm.io/npm:jquery@1.12.4/dist/jquery.js', preload: true
pin 'jquery.caret', to: 'https://ga.jspm.io/npm:jquery.caret@0.3.1/dist/jquery.caret.js', preload: true
pin '@selectize/selectize', to: 'https://ga.jspm.io/npm:@selectize/selectize@0.15.2/dist/js/selectize.js', preload: true
pin 'ahoy', to: 'ahoy.js', preload: true
pin 'chartkick', to: 'chartkick.js', preload: true
pin 'Chart.bundle', to: 'Chart.bundle.js', preload: true
pin 'show-more', to: 'https://cdn.jsdelivr.net/gh/tomickigrzegorz/show-more@1.1.8/dist/js/showMore.esm.min.js',
                 preload: true

pin_all_from 'app/javascript/controllers', under: 'controllers'
