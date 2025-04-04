import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["ooc", "alert", "container"];
  connect() {
    //
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
        }
    });
  }
}
