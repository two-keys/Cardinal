import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["icons", "input"];
  typesObj = {};

  connect() {
    const icons = this.iconsTargets;
    const input = this.inputTarget;
    const self = this;

    for (const icon of icons) {
        icon.addEventListener("click", () => {
            input.value = icon.dataset.icon;
            let elements = $(".sidebar_user_icon.selected");
            for (const el of elements) {
                $(el).removeClass("selected");
            }
            $(icon).addClass("selected");
        });
    }
  }
}
