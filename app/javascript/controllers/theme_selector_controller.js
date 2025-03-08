import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const defaultTheme = 'cardinal';
    let currentTheme = document.documentElement.classList[0]
    let parts = currentTheme.split('-')
    if (parts[1] != defaultTheme) {
      this.element.checked = true;
    } else {
      this.element.checked = false;
    }

    this.element.addEventListener('change', function() {
      let currentTheme = document.documentElement.classList[0]
      let parts = currentTheme.split('-')

      this.theme = !this.checked ? defaultTheme : 'custom';
      changeTheme(`${parts[0]}-${this.theme}`)
    });
  }
}
