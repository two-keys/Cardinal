// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import jQuery from 'jquery'
import 'jquery.caret'

window.$ = jQuery
window.jQuery = jQuery

