import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["ooc", "alert", "container", "colorpick"];
  connect() {
    const color = this.colorpickTarget;
    const container = this.containerTarget;
    var marksmith = $(container).find('#markdown-preview-content');

    if (marksmith[0] && color) {
      var MutationObserver = window.MutationObserver || window.WebKitMutationObserver;

      var mutationHandler = function(mutationRecords) {
        marksmith = $(container).find('#markdown-preview-content').children(':first');
        $(marksmith[0]).css('color', color.value);
        color.removeEventListener('input')
        color.addEventListener('input', function() {
          $(marksmith[0]).css('color', color.value);
        })
      }

      var observer = new MutationObserver(mutationHandler);
      var obsConfig = {
        childList: true,
        characterData: true,
        attributes: true,
        subtree: true
      };

      observer.observe(marksmith[0], obsConfig);
    }
  }

  submitForm(e){
    const alertBox = this.alertTarget;
    const container = this.containerTarget;

    $.ajax({
        url : $(e.target).attr('action') || window.location.pathname,
        type: "POST",
        data: $(e.target).serialize(),
        dataType: 'json',
        success: function (data) {
            $(container).removeClass("error");
            alertBox.innerHTML = "";
            $(alertBox).addClass("hidden");
            container.editor.setHTML("");
            container.editor.focus();
        },
        error: function (jXHR, textStatus, errorThrown) {
            $(container).removeClass("animate");
            $(container).addClass("error");
            $(container).addClass("animate");
            window.setTimeout(() => {
                $(container).removeClass("animate");
            }, "200");
            alertBox.innerHTML = jXHR.responseJSON.content;
            $(alertBox).removeClass("hidden");
        }
    });
  }
}
