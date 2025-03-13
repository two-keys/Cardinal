import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    $(this.element).readmore({
        moreLink: '<a href="#" class="button show-more more">More</a>',
        lessLink: '<a href="#" class="button show-more less">Less</a>',
        collapsedHeight: 210
    });
  }
}
