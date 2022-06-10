# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

pin 'application', preload: true
pin '@hotwired/turbo-rails', to: 'turbo.min.js', preload: true
pin '@hotwired/stimulus', to: 'stimulus.min.js', preload: true
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js', preload: true

pin 'corejs-typeahead', to: 'https://ga.jspm.io/npm:corejs-typeahead@1.3.1/dist/typeahead.bundle.js'
pin 'corejs-bloodhound', to: 'https://ga.jspm.io/npm:corejs-typeahead@1.3.1/dist/bloodhound.js'
pin 'jquery', to: 'https://ga.jspm.io/npm:jquery@3.6.0/dist/jquery.js'
pin 'jquery.caret', to: 'https://ga.jspm.io/npm:jquery.caret@0.3.1/dist/jquery.caret.js'
pin 'process', to: 'https://ga.jspm.io/npm:@jspm/core@2.0.0-beta.24/nodelibs/browser/process-production.js'

pin_all_from 'app/javascript/controllers', under: 'controllers'
