import { Controller } from "@hotwired/stimulus"
import ReadSmore from 'read-smore/dist/index.esm'

export default class extends Controller {
  connect() {
    ReadSmore([this.element], {
      lessText: 'Less',
      moreText: 'More',
      blockClassName: 'show-more'
    }).init()
    /*
    $(this.element).readmore({
        moreLink: '<a href="#" class="button show-more more">More</a>',
        lessLink: '<a href="#" class="button show-more less">Less</a>',
        collapsedHeight: 210,
        beforeToggle: () => {
          console.log("test");
        }
    });
    */
  }
}
