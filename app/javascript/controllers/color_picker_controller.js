import { Controller } from "@hotwired/stimulus"
import Coloris from "@melloware/coloris";

export default class extends Controller {
  connect() {
    Coloris.init();
    Coloris({
        el: this.element,
        theme: 'large',
        format: 'hex',
        alpha: false
    });
  }
}
