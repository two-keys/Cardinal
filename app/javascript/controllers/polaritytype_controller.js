import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["polarity", "tagType"];
  typesObj = {};

  connect() {
    // console.log("Hello, Stimulus!", this.element);

    // theoretically, we could just include this as a data attribute on the controller
    // but that would bloat our HTML
    // instead, using the schema GET route for tag types is better
    fetch('/schema/types.json')
    .then(
      (response) => response.json()
    )
    .then(
      (types) => {
        this.typesObj = types;
        this.changePolarity();
      }, (reason) => {
        console.error(reason);
      }
    );
  }

  changePolarity() {
    let polarity = this.polarityTarget.value;
    let tagType = this.tagTypeTarget.value;
    
    console.log(`${polarity}:${tagType}`);
    // console.log(this.typesObj);

    let firstValidNode;
    for (let nodeIndex = 0; nodeIndex < this.tagTypeTarget.options.length; nodeIndex++) {
      const node = this.tagTypeTarget.options[nodeIndex];

      let nodePolarities = this.typesObj[node.value];

      if (nodePolarities.includes(polarity)) {
        node.removeAttribute('disabled');
        if (!firstValidNode)
          firstValidNode = node;
      } else {
        node.setAttribute('disabled', '');
      }
    }
    // switch selected option
    let mustChange = false

    if ($(this.tagTypeTarget).find(':selected').prop('disabled'))
      mustChange = true

    if (firstValidNode && mustChange)
      this.tagTypeTarget.value = firstValidNode.value;
  }
}
