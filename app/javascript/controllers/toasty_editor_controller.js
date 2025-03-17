import { Controller } from "@hotwired/stimulus"
import Editor from '@toast-ui/editor';
import colorSyntax from '@toast-ui/editor-plugin-color-syntax';

export default class extends Controller {
  static targets = ["editor", "textarea"];
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
        console.error("Toasty Editor form has save enabled without saveId or element ID.");
        return;
    }

    let textArea = this.textareaTarget

    const editor = new Editor({
        el: this.editorTarget,
        height: '300px',
        initialEditType: 'wysiwyg',
        previewStyle: 'vertical',
        initialValue: this.textareaTarget.value,
        events: {
          change: function() {
            textArea.value = editor.getMarkdown()
          }
        },
        plugins: [colorSyntax]
    });

    editor.removeToolbarItem('table');
    editor.removeToolbarItem('code');
    editor.removeToolbarItem('codeblock');
    editor.removeToolbarItem('task');
    editor.removeToolbarItem('image');



    this.editorTarget.editor = editor;

    /*
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
    */
  }
}
