import { Controller } from "@hotwired/stimulus"
import 'easymde'

export default class extends Controller {
  static values = {
    focus: Boolean,
    save: Boolean,
    saveId: String
  }
  connect() {
    if (!this.saveIdValue) {
        this.saveIdValue = this.element.id
    }
    if (this.focusValue && !this.saveIdValue) {
        console.error("EasyMCE form has save enabled without saveId or element ID.");
        return;
    }
    console.log(this.focusValue);
    const easyMDE = new EasyMDE({
        element: this.element,
        autofocus: this.focusValue,
        autosave: this.saveValue ? {
            enabled: true,
            uniqueId: this.saveIdValue
        } : undefined,
        lineWrapping: true,
        sideBySideFullscreen: false,
        status: ["autosave", "lines", "words", "cursor", {
            className: "keystrokes",
            defaultValue: (el) => {
                el.setAttribute('data-keystrokes', 0);
            },
            onUpdate: (el) => {
                const keystrokes = Number(el.getAttribute('data-keystrokes')) + 1;
                el.innerHTML = `${keystrokes} Keystrokes`;
                el.setAttribute('data-keystrokes', keystrokes);
            },
        }],
        hideIcons: ['fullscreen']
    });
  }
}
