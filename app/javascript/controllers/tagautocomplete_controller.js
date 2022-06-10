import { Controller } from "@hotwired/stimulus"
import "selectize.js"

export default class extends Controller {
    initialize() {
      let text_input = this.element.children[1];
      let current_element = this.element;
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