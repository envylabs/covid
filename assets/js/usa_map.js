// import * as d3 from "d3"
import * as topojson from "topojson-client"

const color = (obj, value) => {
  return obj.x(Math.sqrt(value) + Math.sqrt(obj.maxValue) / 10);
};

const label = (obj, value) => {
  return `${value} ${obj.label}`;
};

const path = d3.geoPath();

const getData = (obj, id) => {
  const data = obj.data[window.rona.date];
  var result = 0;
  if (data) {
    result = data[id] || 0;
  }
  return Math.max(result, 0);
}

const prepareMap = (obj) => {
  obj.data = JSON.parse(obj.el.dataset.mapdata);
  obj.label = obj.el.dataset.label;

  obj.maxValue = Object.values(obj.data).map(d => Object.values(d)).flat().reduce((a, b) => Math.max(a, b));
  obj.x = d3.scaleSequential(d3.interpolateBuPu)
    .domain([0, Math.sqrt(obj.maxValue) / 2]);
}

export const initMap = (obj) => {
  obj.target = document.getElementById(obj.el.dataset.target);
  prepareMap(obj);

  d3.json("/data/us-counties.json").then((us) => {
    obj.us = us;
    obj.states = new Map(us.objects.states.geometries.map(d => [d.id, d.properties]));

    const svg = d3.select(obj.target)
      .append("svg")
      .attr("viewBox", [0, 0, 975, 610]);

    svg.append("g")
      .selectAll("path")
      .data(topojson.feature(us, us.objects.counties).features)
      .join("path")
      .attr("fill", d => color(obj, getData(obj, d.id)))
      .attr("d", path)
      .append("title")
      .text(d => `${d.properties.name}, ${obj.states.get(d.id.slice(0, 2)).name}
${label(obj, getData(obj, d.id))}`);

    svg.append("path")
      .datum(topojson.mesh(us, us.objects.states, (a, b) => a !== b))
      .attr("fill", "none")
      .attr("stroke", "white")
      .attr("stroke-linejoin", "round")
      .attr("d", path);
  });
};

export const updateMap = (obj) => {
  prepareMap(obj);

  d3.select(obj.target)
    .select("svg")
    .select("g")
    .selectAll("path")
    .attr("fill", d => color(obj, getData(obj, d.id)))
    .select("title")
    .text(d => `${d.properties.name}, ${obj.states.get(d.id.slice(0, 2)).name}
${label(obj, getData(obj, d.id))}`);
};

export default {
  mounted() {
    initMap(this);
		window.rona.map = this;
  },

  updated() {
    updateMap(this);
  }
};
