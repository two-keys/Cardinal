import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = {
        id: String,
        url: String
    }
    static targets = ["image", "text", "yes", "no"];
    connect() {
        console.log("Attached Ad")
        const adId = this.idValue;
        const image = this.imageTarget;
        const text = this.textTarget;
        const yes = this.yesTarget;
        const no = this.noTarget;
        if (this.urlValue && this.urlValue != "") {
            $(image).on("click", (e) => {
                $(text).removeClass('hidden')
                $(image).addClass('unfocused')
            })
            $(no).on("click", (e) => {
                $(image).removeClass('unfocused')
                $(text).addClass('hidden')
            })
            $(yes).on("click", (e) => {
                window.open('/ads/' + adId + '/click', '_blank').focus();
                return false;
            })

        }
    }
}
