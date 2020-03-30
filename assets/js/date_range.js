import {updateMap} from "./usa_map";

export const updateSlider = (obj, index) => {
  if (index < 0) { index = window.rona.dates.length - 1 }
  if (index >= window.rona.dates.length) { index = 0 }
  obj.el.value = index;
  window.rona.date = window.rona.dates[index];
  document.getElementById("current-date").textContent = window.rona.date;
  updateMap(window.rona.map);
}

export default {
  mounted() {
    window.rona.slider = this;
    window.rona.dates = JSON.parse(this.el.dataset.dates);
    window.rona.date = window.rona.dates[this.el.value];

    this.el.addEventListener("input", e => {
      updateSlider(this, e.target.valueAsNumber);
    });
  }
}
