import { Controller } from "@hotwired/stimulus"
import ShowMore from 'show-more'

export default class extends Controller {
  connect() {
    new ShowMore('.show-more', {
        config: {
          type: "text",
          limit: 300,
          more: "→ read more",
          less: "← read less"
        }
      });
  }
}
