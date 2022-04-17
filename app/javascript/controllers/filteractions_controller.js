import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["group"];

  connect() {
    // console.log("Hello, Stimulus!", this.element);
  }

  add() {
    let group = this.groupTarget.value;
    console.log(group);
  
    let paramsString = document.location.search;
    // console.log(paramsString);

    let searchParams = new URLSearchParams(paramsString);

    // we wanna check there's no empty values
    if (group) {
      // no in-depth string processing here, HTTP controller handles that
      searchParams.set('group', group);

      // redirect, might break on some browsers
      document.location.search = '?' + searchParams.toString();
    };
  }
}
