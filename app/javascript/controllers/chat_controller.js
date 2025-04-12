import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages"];
  connect() {
    const messages = this.messagesTarget;
    var pending = false;
    var originalTitle = document.title;

    var MutationObserver = window.MutationObserver || window.WebKitMutationObserver;

    function mutationHandler(_mutationRecords) {
        if (pending) {
          return;
        }
  
        if (!document.hidden) {
          return;
        }
   
        pending = true;
        document.title = "(!) " + originalTitle;
      }

    if (!MutationObserver) {
        console.log ("This browser does not support MutationObserver.");
        return;
    }
    var myObserver = new MutationObserver(mutationHandler);
    var obsConfig = {
        childList: true
    };

    myObserver.observe(messages, obsConfig);

    addEventListener("visibilitychange", (event) => {
        if (!document.hidden) {
            if (pending) {
                document.title = originalTitle;
                pending = false;
            }
        }
    });

    let lastMessage = $(messages).children().last()[0]
    console.log(lastMessage);

    lastMessage.scrollIntoView({behavior: "smooth", block: "center"});
  }
}
