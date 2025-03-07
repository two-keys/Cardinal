import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["content", "inner", "button"];

    static values = {
      moreText: String,
      lessText: String
    }

    isTextClamped = elm => elm.scrollHeight > elm.clientHeight

    connect() {
        this.open = false;
        if (this.isTextClamped(this.contentTarget)) {
          this.buttonTarget.classList.remove("hide");
        }
        this.truncateEl = this.contentTarget;
        this.truncateInnerEl = this.innerTarget;
        this.truncateRect = this.truncateEl.getBoundingClientRect();
        this.truncateInnerRect = this.truncateInnerEl.getBoundingClientRect();

        this.truncateEl.style.setProperty("--truncate-height", `${this.truncateRect.height}px`);
    }
    toggle(event) {
        this.open === false ? this.show(event) : this.hide(event);
        this.buttonTarget.innerHTML = this.open ? "Less..." : "More..."
    }
    show(event) {
        this.open = true;
        this.truncateEl.classList.remove('truncate--line-clamped');
        window.requestAnimationFrame(() => {
          this.truncateInnerRect = this.truncateInnerEl.getBoundingClientRect();
          this.truncateEl.style.setProperty("--truncate-height-expanded", `${this.truncateInnerRect.height}px`);
          this.truncateEl.classList.add('truncate--expanded');
        });
        
    }
    hide(event) {
        this.open = false;
        this.truncateEl.classList.remove('truncate--expanded');
        setTimeout(() => {
          this.truncateEl.classList.add('truncate--line-clamped');
        }, 300);
    }
}
