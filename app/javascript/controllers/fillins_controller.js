import { Controller } from "@hotwired/stimulus"

// app/views/[model_name]/form_tags/_fill_ins
export default class extends Controller {
  connect() {
    console.log("Hello, Stimulus!", this.element);
  }

  static targets = ["grow"];

  /**
   * Called when someone types into an input OR pastes from a browser menu
   * @param {*} event 
   */
  tidyInputEvent(event) {
    console.log(event.type, Date.now(), event.data);
    let text = event.target.value;
    if (event.data == ',' && text[text.length - 1] == ',') { // general typing
      event.target.value = text.substring(0, text.length - 1); // we could preventDefault, but that'd be inconsistent with mobile devices
      this._grow(event, 'right');
    } else if(event.data != null && event.data.includes(",")) { // paste from a browser/mobile menu
      this._split(event, event.data);
    }
  }

  /**
   * Called when someone hits enter on an input
   * If the input is empty, tidyKeypressEvent kills the input. Else, it grows the list.
   * @param {*} event 
   */
  tidyKeypressEvent(event) {
    console.log(event.type, Date.now(), event.target.value, event.code);
    if (event.code == 'Enter') {
      event.preventDefault();
      if (event.target.value == '') {
        this._kill(event.target);
      } else {
        this._grow(event, 'right');
      }
    }
  }

  /**
   * Called when someone pastes on an input
   * If incoming paste is not empty, we'll 1. split that paste around commas and 2. add non-empty values from that split array as new inputs.
   * @param {*} event 
   */
  tidyPasteEvent(event) {
    var clipboardData, paste;
    // the clipboard api is finicky, so we have to do Weird Stuff with it
    clipboardData = event.clipboardData || window.clipboardData;
    paste = clipboardData.getData('Text');

    console.log(event.type, Date.now(), paste, paste.split(','));
    if (paste.includes(",")) {
      this._split(event, paste);
    }
  }

  /**
   * Called when someone clicks the '+' or '-' buttons.
   * If the button is '-', tidyButton shrinks the list. Else, it grows the list.
   * @param {*} event 
   */
  tidyButton(event) {
    console.log(Date.now(), event.target.textContent);
    event.preventDefault();
    if (event.target.textContent == '-') {
      this._shrink();
    } else {
      this._grow(event, 'right');
    }
  }

  _grow() {
    // console.log("Hello, you're growing the input list!", this.element);

    let lastInput = this._getLastKillableInput();
  
    if (lastInput.value == '') {
      console.error('Last input is already empty');
      return false;
    }

    // generate input
    var input = this._inputTagFromValue();
    
    console.log(this.element.getAttribute('data-tag_type'), this.element.getAttribute('data-polarity'));

    let target = this.growTarget; // grabs the + button
    target.before(input);

    input.focus();
    return true;
  }

  /**
   * Split a string into multiple tags, if possible
   */
  _split(event, inputString)  {
    let tagPointer = event.target; // don't kill until we're done adding tags

    // add a tag for each valid value in the split array
    let tagsFromSplit = inputString.split(",");
    for (let tagIndex = 0; tagIndex < tagsFromSplit.length; tagIndex++) {
      const tagValue = tagsFromSplit[tagIndex];
      // console.log(tagValue);
      if (tagValue.length > 0) {
        const tag = this._inputTagFromValue(tagValue);

        tagPointer.before(tag);
      }
    }

    this._kill(event.target);
  }

  _shrink() {
    // console.log("Hello, you're shrinking the input list!", this.element);
    
    let target = this._getLastKillableInput();

    this._kill(target)
  }

  _getLastKillableInput() {
    let target = this.growTarget; // grabs the + button
    target = target.previousElementSibling; // grab last killable input
    return target;
  }

  _kill(node) {
    // console.log(node);
    let victims = this.element.getElementsByTagName('input'); // LIVE, only gets element nodes
    
    if (victims.length > 1 ) {
      node.previousElementSibling.focus();
      node.remove()
    } else {
      console.error('Would destroy list');
    }
  }

  /**
   * @param {String} value Leave empty to create an empty input
   * @returns {HTMLInputElement}
   */
  _inputTagFromValue(value) {
    let tag_type = this.element.getAttribute('data-tag_type');
    let polarity = this.element.getAttribute('data-polarity');
    
    var input = document.createElement("input");

    if (typeof value != 'undefined') input.value = value;
    
    input.setAttribute('class', 'killable');
    input.setAttribute('multiple', 'multiple');
    
    input.type = 'text';
    input.name = `tags[${polarity}][${tag_type}][]`;
    
    input.setAttribute('data-action', 'input->fillins#tidyInputEvent keypress->fillins#tidyKeypressEvent paste->fillins#tidyPasteEvent');
    return input;
  }
}
