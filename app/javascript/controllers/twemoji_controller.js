import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    twemoji.parse(
        this.element,
        { base: 'https://cdn.jsdelivr.net/gh/twitter/twemoji@latest/assets/' }
    );
  }
}
