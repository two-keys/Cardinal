import { Controller } from "@hotwired/stimulus"
import "corejs-typeahead"
import * as bh from "corejs-bloodhound"

export default class extends Controller {
    connect() {
      let Bloodhound = bh.default

      this.text_input = this.element.children[0]
      let current_element = this.element
      let lastVal = "";
      let lastPos = 0;
      let lastUpper = false;
      let vertAdjustMenu = true;

      let extractor = function(query){
        var result = (new RegExp('([^,; \r\n]+)$')).exec(query);
        if(result && result[1])
          return result[1].trim();
        return '';
      }

      let beforeReplace = function(event, data) {
        let this_element = current_element.children[0].children[0];
        //lastVal = $(this_element).val();
			  lastPos = $(this_element).caret('pos');
			  return true;
      }

      let onReplace = function(event, data) {
        let this_element =  current_element.children[0].children[0];
			  if (!data.name || !data.name.length)
			  	return;

			  if (!lastVal.length)
			  	return;

			  var root = lastVal.substr(0, lastPos);
			  var post = lastVal.substr(lastPos);

			  var typed = extractor(root);
			  if (!lastUpper && typed.length >= root.length && 0 >= post.length)
			  	return;

			  var str = root.substr(0, root.length - typed.length);
        
			  str += lastUpper ? (data.name.substr(0, 1).toUpperCase() + data.name.substr(1)) : data.name;
			  var cursorPos = str.length + 1;

			  str += post + ",";

			  $(this_element).val(str);
			  $(this_element).caret('pos', cursorPos);
        lastVal = $(this_element).val();
      }

      let onChange = function(event) {
        let this_element = current_element.children[0].children[0];

        $(this_element).val(lastVal);
      }

      let recalculatePosition = function(event) {

        let this_element = current_element.children[0].children[0];
        lastVal = $(this_element).val();
        var cpos = $(this_element).caret('position');
        $(this_element).parent().find('.tt-menu').css('left', cpos.left - 90 + 'px');
        if (vertAdjustMenu)
					$(this_element).parent().find('.tt-menu').css('top', (cpos.top + cpos.height) + 'px');
      }

      this.tag_suggestion_engine = new Bloodhound({
        datumTokenizer: datum => Bloodhound.tokenizers.obj.whitespace(datum.value),
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        remote: {
          url: '/tags/autocomplete.json',
          prepare: function (q, rq) {
            rq.type = "POST"
            rq.data = { 
              tag: "a", // We need anything here lmao
              tag_search: q,
              tag_type: current_element.dataset.tagautocompleteTagtypeValue,
              polarity: current_element.dataset.tagautocompletePolarityValue
            }
            return rq
          },
          transport: function (obj, onS, onE) {

            $.ajax(obj).done(done).fail(fail).always(always);

            function done(data, textStatus, request) {
                // Don't forget to fire the callback for Bloodhound
                onS(data);
            }

            function fail(request, textStatus, errorThrown) {
                // Don't forget the error callback for Bloodhound
                onE(errorThrown);
            }

            function always() {
              
            }
        }
        }
      })

      $(this.text_input).typeahead({
        minLength: 1,
        highlight: true,
        hint: false,
        autoselect: true
      },
      {
        name: current_element.dataset.tagautocompleteTagtypeValue + "_" + current_element.dataset.tagautocompletePolarityValue,
        displayKey: 'name',
        source: this.tag_suggestion_engine
      })
      .on("typeahead:beforeselect", beforeReplace)
      .on('typeahead:beforeautocomplete', beforeReplace)
			.on('typeahead:beforecursorchange', beforeReplace)
      .on('typeahead:selected', function(event,data){setTimeout(function(){ onReplace(event, data); }, 0);})
			.on('typeahead:autocompleted', onReplace)
			.on('typeahead:cursorchange', onReplace)
      .on('typeahead:change', onChange)
      .on('change paste input', recalculatePosition)
      .on('blur', onChange)
  
  
      // Messes with our themeing system
      $('.tt-hint').css('background', '')
    }
}