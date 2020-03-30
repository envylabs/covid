import {updateSlider} from "./date_range";

export default {
  mounted() {
    this.playing = false;

    this.el.addEventListener("click", e => {
      this.playing = !this.playing;
      if (this.playing) {
        this.el.textContent = "\u25a0"
        this.interval = window.setInterval(() => {
          updateSlider(window.rona.slider, window.rona.slider.el.valueAsNumber + 1);
        }, 100);
      } else {
        if (this.interval) {
          window.clearInterval(this.interval);
          this.interval = null;
        }
        this.el.textContent = "\u25b6"
      }
    });
  }
}
