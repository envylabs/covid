const classes = ["chart-svg", "chart-large"];

const width = [185, 410];
const height = [160, 220];

const margin = [
  {top: 0, right: 0, bottom: 20, left: 0},
  {top: 0, right: 0, bottom: 20, left: 0}
];

const colors = [
  ["rgb(136, 68, 157)", "rgb(168, 194, 221)"],
  ["rgb(0, 69, 27)", "rgb(137, 209, 188)"]
];

const xAxis = (g, obj) => {
  g.attr("transform", `translate(0,${height[obj.size] - margin[obj.size].bottom})`)
    .attr('class', 'chart-xaxis')
    .call(d3.axisBottom(obj.x).tickFormat(d3.timeFormat("%b %d")).tickSize(2).tickValues([obj.date]));
}

const yAxis = (g, obj) => {
  g.attr("transform", `translate(${width[obj.size] + margin[obj.size].left},0)`)
    .attr('class', 'chart-yaxis')
    .call(d3.axisLeft(obj.y).tickSize(width[obj.size]).tickValues([0, obj.max]).tickPadding(0));
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
    .domain([0, obj.max])
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
