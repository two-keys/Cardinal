import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

    disconnect() {
      let text_input = this.element.children[1];
      $(text_input).select2('destroy');
    }

    connect() {
      let text_input = this.element.children[1];
      let current_element = this.element;

      function formatTag (tag) {
        if (!tag.id) {
          return tag.name;
        }

        $(tag.element).attr('data-tooltip', tag.tooltip);
        $(tag.element).attr('data-details', tag.details);

        var tooltip = $(tag.element).data('tooltip') || tag.tooltip
        var details = $(tag.element).data('details') || tag.details
        var canonical = $(tag.element).data('canonical') || tag.canonical
        

        var $item = null
        
        if (tooltip) {

        }
        var $item = $(
          '<div class="item inline"><span></span></div>'
        );

        if (tooltip) {
          $item = $(
            '<div class="item inline tooltip"><span></span></div>'
          )
          $item.prepend(
            '<div class="tooltip-content"></div>'
          )
        }

        if (details) {
          var $modal = $('<dialog id="tag_' + canonical +'_modal" class="modal"></dialog>')
          $modal.append('<div class="modal-box"><p class="py-4"><turbo-frame id="tag_' + canonical + '_details" src="/tags/' + canonical + '/details"></turbo-frame></div>')
          $modal.append('<form method="dialog" class="modal-backdrop"><button>close</button></form>')
          var $modalButton = $('<span> </span><button type="button"><svg class="inline-block h-3 w-3 mb-[3px] fill-current" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512"><!--!Font Awesome Free 6.7.2 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free Copyright 2025 Fonticons, Inc.--><path d="M96 0C43 0 0 43 0 96L0 416c0 53 43 96 96 96l288 0 32 0c17.7 0 32-14.3 32-32s-14.3-32-32-32l0-64c17.7 0 32-14.3 32-32l0-320c0-17.7-14.3-32-32-32L384 0 96 0zm0 384l256 0 0 64L96 448c-17.7 0-32-14.3-32-32s14.3-32 32-32zm32-240c0-8.8 7.2-16 16-16l192 0c8.8 0 16 7.2 16 16s-7.2 16-16 16l-192 0c-8.8 0-16-7.2-16-16zm16 48l192 0c8.8 0 16 7.2 16 16s-7.2 16-16 16l-192 0c-8.8 0-16-7.2-16-16s7.2-16 16-16z"/></svg></button>')
          $item.append(
            $modalButton
          )
          $item.append(
            $modal
          )
          $modalButton.on('click', function(e) {
            e.preventDefault();
            $modal[0].showModal();
          })
        }

        var name = tag.text;
        if (tooltip) {
          $item.find(".tooltip-content").first().text(tooltip)
          name = name + ' ⓘ'
        }

        $item.find('span').first().text(name);
      
        return $item;
      };

      let $select = $(text_input).select2(
        {
          cache: true,
          tags: true,
          tokenSeparators: [','],
          templateSelection: formatTag,
          ajax: {
            url: '/tags/autocomplete.json',
            delay: 250,
            type: "POST",
            dataType: 'json',
            params: {
              contentType: "application/json; charset=utf-8",
            },
            data: function (params) {
              var query = {
                tag_search: params.term,
                tag_type: current_element.dataset.tagautocompleteTagtypeValue,
                polarity: current_element.dataset.tagautocompletePolarityValue
              }
              return query;
            },
            processResults: function (data, params) {
              return {
                results: $.map(data, function(obj) {
                  obj.canonical = obj.id
                  obj.id = obj.name
                  obj.text = obj.name;
                  obj.tooltip = obj.tooltip
                  obj.details = obj.details

                  return obj
                })
              };
            },
          },
        }
      );
    }
}