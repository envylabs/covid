const classes = ["chart-svg", "chart-large"];

const width = [230, 400];
const height = [160, 230];

const margin = [
  {top: 10, right: 0, bottom: 20, left: 40},
  {top: 10, right: 0, bottom: 20, left: 60}
];

const colors = [
  ["rgb(136, 68, 157)", "rgb(204, 221, 236)"],
  ["rgb(33, 139, 72)", "rgb(193, 232, 224)"]
];

const xAxis = (g, obj) => {
  g.attr("transform", `translate(0,${height[obj.size] - margin[obj.size].bottom})`)
    .call(d3.axisBottom(obj.x).tickFormat(d3.timeFormat("%b %d")).tickSizeOuter(0).tickValues([obj.date]));
}

const yAxis = (g, obj) => {
  g.attr("transform", `translate(${width[obj.size] + margin[obj.size].left},0)`)
    .call(d3.axisLeft(obj.y).tickSize(width[obj.size]).tickValues([0, obj.max]))
    .call(g => g.select(".domain").remove());
}

const prepareChart = (obj) => {
  const data = JSON.parse(obj.el.dataset.chartdata).map(d => ({t: new Date(d.t), c: d.c, d: d.d}));
  obj.data = d3.stack().keys(["d", "c"])(data);
  obj.date = data[data.length - 1].t;
  obj.max = obj.el.dataset.max;
  obj.size = obj.el.dataset.size || 0;

  obj.color = d3.scaleOrdinal()
    .range(colors[obj.el.dataset.colorScheme]);

  obj.x = d3.scaleUtc()
    .domain(d3.extent(data, d => d.t))
    .range([margin[obj.size].left, width[obj.size] - margin[obj.size].right]);

  obj.y = d3.scaleLinear()
    .domain([0, obj.max]).nice()
    .range([height[obj.size] - margin[obj.size].bottom, margin[obj.size].top]);

  obj.area = d3.area()
    .x(d => obj.x(d.data.t))
    .y0(d => obj.y(d[0]))
    .y1(d => obj.y(d[1]));
}

export const initChart = (obj) => {
  prepareChart(obj);

  const svg = d3.select(obj.el)
    .append("svg")
    .attr("class", classes[obj.size])
    .attr("viewBox", [0, 0, width[obj.size], height[obj.size]]);

  svg.append("g")
    .selectAll("path")
    .data(obj.data)
    .join("path")
    .attr("fill", ({key}) => obj.color(key))
    .attr("d", obj.area);

  svg.append("g")
    .call(xAxis, obj);

  svg.append("g")
    .call(yAxis, obj);
};

export const updateChart = (obj) => {
};

export default {
  mounted() {
    initChart(this);
  },

  updated() {
    updateChart(this);
  }
};
