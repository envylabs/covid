// import * as d3 from "d3"
import * as topojson from "topojson-client"

const viewboxes = {
  "00": [0, 0, 975, 610], // Entire US
  "01": [570, 375, 200, 125.13], // Alabama
  "02": [-25, 460, 240, 150.15], // Alaska
  "04": [80, 310, 240, 150.15], // Arizona
  "05": [496, 350, 140, 87.59], // Arkansas
  "06": [-100, 160, 400, 250.26], // California
  "08": [240, 233, 180, 112.62], // Colorado
  "09": [862, 177, 50, 31.28], // Connecticut
  "10": [824, 238, 60, 37.54], // Delaware
  "11": [823, 264, 10, 6.26], // DC
  "12": [630, 460, 240, 150.15], // Florida
  "13": [645, 370, 180, 112.62], // Georgia
  "15": [203, 523, 140, 87.59], // Hawaii
  "16": [60, 32, 290, 181.44], // Idaho
  "17": [505, 208, 220, 137.64], // Illinois
  "18": [580, 222, 160, 100.10], // Indiana
  "19": [480, 191, 120, 75.08], // Iowa
  "20": [376, 260, 160, 100.10], // Kansas
  "21": [610, 275, 140, 87.59], // Kentucky
  "22": [507, 431, 150, 93.85], // Louisiana
  "23": [835, 44, 170, 106.36], // Maine
  "24": [778, 238, 90, 56.31], // Maryland
  "25": [866, 151, 70, 43.79], // Massachusetts
  "26": [540, 96, 220, 137.64], // Michigan
  "27": [420, 60, 220, 137.64], // Minnesota
  "28": [520, 378, 200, 125.13], // Mississippi
  "29": [475, 258, 170, 106.36], // Missouri
  "30": [186, 35, 200, 125.13], // Montana
  "31": [354, 190, 160, 100.10], // Nebraska
  "32": [0, 178, 290, 181.44], // Nevada
  "33": [845, 102, 100, 62.56], // New Hampshire
  "34": [818, 204, 90, 56.31], // New Jersey
  "35": [185, 318, 240, 150.15], // New Mexico
  "36": [745, 113, 180, 112.62], // New York
  "37": [708, 300, 170, 106.36], // North Carolina
  "38": [360, 60, 140, 87.59], // North Dakota
  "39": [650, 205, 150, 93.85], // Ohio
  "40": [360, 324, 180, 112.62], // Oklahoma
  "41": [0, 68, 200, 125.13], // Oregon
  "42": [748, 188, 120, 75.08], // Pennsylvania
  "44": [890, 176, 30, 18.77], // Rhode Island
  "45": [710, 360, 130, 81.33], // South Carolina
  "46": [360, 132, 140, 87.59], // South Dakota
  "47": [600, 310, 160, 100.10], // Tennessee
  "48": [220, 350, 400, 250.26], // Texas
  "49": [125, 199, 210, 131.38], // Utah
  "50": [825, 108, 100, 62.56], // Vermont
  "51": [710, 250, 160, 100.10], // Virginia
  "53": [45, 10, 160, 100.10], // Washington
  "54": [695, 235, 150, 93.85], // West Virginia
  "55": [510, 108, 180, 112.62], // Wisconsin
  "56": [215, 140, 180, 112.62], // Wyoming
}

const color = (obj, value) => {
  if (value == null) { return "#ffffff" }
  return obj.x(Math.sqrt(value) + Math.sqrt(obj.maxValue) / 10);
};

const label = (obj, d, value) => {
  if (value == null) { return "" }

  var value_str = `${value} ${obj.label}`;
  if (obj.percent) {
    value_str = `${value} ${obj.label} per 100,000`;
  }

  return `${d.properties.name}, ${obj.states.get(d.id.slice(0, 2)).name}\n${value_str}`;
};

const path = d3.geoPath();

const getData = (obj, id) => {
  if (obj.zoom == "00" || id.substring(0, 2) === obj.zoom) {
    const data = obj.data[window.rona.date];
    var result = 0;
    if (data) {
      result = data[id] || 0;
    }
    return Math.max(result, 0);
  } else {
    return null;
  }
}

const prepareMap = (obj) => {
  obj.data = JSON.parse(obj.el.dataset.mapdata);
  obj.label = obj.el.dataset.label;
  obj.percent = obj.el.dataset.percent;
  obj.zoom = obj.el.dataset.zoom;

  obj.maxValue = Object.values(obj.data).map(d => Object.values(d)).flat().reduce((a, b) => Math.max(a, b));
  const colorScheme = obj.zoom === "00" ? d3.interpolateBuPu : d3.interpolateBuGn;
  obj.x = d3.scaleSequential(colorScheme)
    .domain([0, Math.sqrt(obj.maxValue) / 2]);
}

export const initMap = (obj) => {
  prepareMap(obj);

  d3.json("/data/us-counties.json").then((us) => {
    obj.us = us;
    obj.states = new Map(us.objects.states.geometries.map(d => [d.id, d.properties]));

    const svg = d3.select(obj.el)
      .append("svg")
      .attr("class", "map")
      .attr("viewBox", viewboxes[obj.zoom]);

    svg.append("g")
      .selectAll("path")
      .data(topojson.feature(us, us.objects.counties).features)
      .join("path")
      .attr("fill", d => color(obj, getData(obj, d.id)))
      .attr("d", path)
      .append("title")
      .text(d => label(obj, d, getData(obj, d.id)));

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

  const svg = d3.select(obj.el)
    .select("svg")
    .attr("viewBox", viewboxes[obj.zoom]);

  svg.select("g")
    .selectAll("path")
    .attr("fill", d => color(obj, getData(obj, d.id)))
    .select("title")
    .text(d => label(obj, d, getData(obj, d.id)));
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
