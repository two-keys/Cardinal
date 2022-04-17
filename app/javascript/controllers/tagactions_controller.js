import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["polarity", "tagType", "name"];

  connect() {
    // console.log("Hello, Stimulus!", this.element);
  }

  add() {
    let newTag = {
      polarity: this.polarityTarget.value,
      tagType: this.tagTypeTarget.value,
      name: this.nameTarget.value,
    };
    // console.log(newTag);
  
    let paramsString = document.location.search;
    // console.log(paramsString);

    let searchParams = new URLSearchParams(paramsString);

    let tags = [];
    if (searchParams.has('tags')) {
      tags = searchParams.get('tags').split(',');
    } else {
      searchParams.append('tags', '');
    }

    // console.log(`Tags: ${tags}`);

    // we wanna check there's no empty values
    if (newTag && newTag.polarity && newTag.tagType && newTag.name) {
      const { polarity, tagType, name } = newTag;
      tags.push(`${polarity}:${tagType}:${name}`);

      // no in-depth string processing here, HTTP controller handles that
      searchParams.set('tags', tags.join(','));

      // redirect, might break on some browsers
      document.location.search = '?' + searchParams.toString();
    };
  }
}
