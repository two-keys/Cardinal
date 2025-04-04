import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["editor"];
  static values = {
    focus: Boolean,
    save: Boolean,
    saveId: String
  }

  connect() {
    const naturallyStretchy = CSS && CSS.supports('field-sizing', 'content');
    console.log(naturallyStretchy)
    if (!this.saveIdValue) {
        this.saveIdValue = this.element.id
    }
    if (this.saveValue && !this.saveIdValue) {
        console.error("Marksmith Editor form has save enabled without saveId or element ID.");
        return;
    }
    let textArea = $(this.element).find('textarea')[0];
    let saveValue = this.saveValue
    let saveIdValue = this.saveIdValue

    if (!naturallyStretchy) {
      textArea.style.overflowY = "scroll";
    }

    textArea.setHTML = function(input) {
        this.value = input;
        if (saveValue) {
            textArea.save(saveIdValue);
            window.setTimeout(function() {
                textArea.scrollIntoView({behavior: "smooth", block: "center"});
                textArea.focus();
            }, 300)
        }
    };

    textArea.save = function(saveId) {
        localStorage.setItem(saveId, textArea.value);
    }

    this.element.editor = textArea;
    this.element.editor.focus();
    
    if (this.saveValue) {
      textArea.value = localStorage.getItem(this.saveIdValue);
      textArea.oninput = () => {
        textArea.save(this.saveIdValue);
      };
    }
  }
}
