import { Controller } from "@hotwired/stimulus"
import "@selectize/selectize"

export default class extends Controller {
    initialize() {
      let text_input = this.element.children[1];
      let current_element = this.element;
      let $form = $('#object_tags_form')
      let $select = $(text_input).selectize({
        plugins: ["remove_button"],
        delimiter: ",",
        create: true,
        maxOptions: 5,
        hideSelected: true,
        preload: true,
        selectOnTab: true,
        valueField: 'name',
        labelField: 'name',
        searchField: 'name',
        render: {
          item: function(item, escape) {
            console.log(item)
            if (item.tooltip) {
              return '<div class="item tooltip"><div class="tooltip-content">' + escape(item.tooltip) + '</div>ⓘ '+ escape(item.name) + '</div>';
            } else {
              return '<div class="item">'+ escape(item.name) + '</div>';
            }
          }
        },
        load: function(query, callback) {
          let maxOptions = this.settings.maxOptions;
          let currentResults = this.currentResults;
          let control = this.selectize;
          if (!query.length) {
            // Preload data
            $.post("/tags/autocomplete.json", {
              tag: "prefetch",
              tag_type: current_element.dataset.tagautocompleteTagtypeValue,
              polarity: current_element.dataset.tagautocompletePolarityValue
            }, function(data, status) {
              if (status == "success") {
                callback(data)
              } else {
                callback()
              }
            }, "json");
          } else {
            console.log($select.selectize);
            if (currentResults.items.length < maxOptions) {
              console.log("Fetching more tags.")
              $.post("/tags/autocomplete.json", {
                tag: "query",
                tag_search: query,
                tag_type: current_element.dataset.tagautocompleteTagtypeValue,
                polarity: current_element.dataset.tagautocompletePolarityValue
              }, function(data, status) {
                if (status == "success") {
                  callback(data)
                } else {
                  callback()
                }
              }, "json");
            } else {
              callback()
            }
          }
        }
      });
    }
}