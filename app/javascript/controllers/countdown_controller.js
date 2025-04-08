import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["hours", "minutes", "seconds"];
  static values = {
    diff: Array
  }

  connect() {
    let timeValues = this.diffValue
    let hoursTarget = this.hoursTarget
    let minutesTarget = this.minutesTarget
    let secondsTarget = this.secondsTarget

    this.timer = window.setInterval(function() {
        timeValues[2]--;
        if (timeValues[2] < 0) {
            timeValues[2] = 59
            timeValues[1]--;
            if (timeValues[1] < 0) {
                timeValues[1] = 59
                timeValues[0]--;
                if (timeValues[0] < 0) {
                    timeValues[0] = 0
                    timeValues[1] = 0
                    timeValues[2] = 0
                }
            }
        }
        hoursTarget.style.setProperty('--value', timeValues[0])
        minutesTarget.style.setProperty('--value', timeValues[1])
        secondsTarget.style.setProperty('--value', timeValues[2])
    }, 1000);
  }

  disconnect() {
    window.clearInterval(this.timer);
  }
}
