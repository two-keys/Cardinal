import { Controller } from "@hotwired/stimulus"
import EasyMDE from "easymde"

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
        forceSync: true,
        status: ["autosave", "lines", "words", "cursor"],
        hideIcons: ['fullscreen']
    });
    this.element.easymde = easyMDE;
  }
}
