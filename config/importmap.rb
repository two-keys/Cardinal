# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

pin 'application', preload: true
pin '@hotwired/turbo-rails', to: 'turbo.min.js', preload: true
pin '@hotwired/stimulus', to: 'stimulus.min.js', preload: true
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js', preload: true

pin 'jquery', to: 'https://ga.jspm.io/npm:jquery@1.12.4/dist/jquery.js', preload: true
pin 'jquery.caret', to: 'https://ga.jspm.io/npm:jquery.caret@0.3.1/dist/jquery.caret.js', preload: true
pin 'selectize.js', to: 'https://ga.jspm.io/npm:selectize.js@0.12.12/dist/js/selectize.js', preload: true
pin 'microplugin', to: 'https://ga.jspm.io/npm:microplugin@0.0.3/src/microplugin.js', preload: true
pin 'sifter', to: 'https://ga.jspm.io/npm:sifter@0.5.4/sifter.js', preload: true
pin 'ahoy', to: 'ahoy.js', preload: true
pin 'chartkick', to: 'chartkick.js', preload: true
pin 'Chart.bundle', to: 'Chart.bundle.js', preload: true

pin_all_from 'app/javascript/controllers', under: 'controllers'
