const width = 200;
const height = 100;

const margin = ({top: 10, right: 10, bottom: 30, left: 40});

const colors = [
	["rgb(136, 68, 157)", "rgb(204, 221, 236)"],
	["rgb(33, 139, 72)", "rgb(193, 232, 224)"]
];

const xAxis = (g, obj) => {
  g.attr("transform", `translate(0,${height - margin.bottom})`)
    .call(d3.axisBottom(obj.x).ticks(2).tickSizeOuter(0));
}

const yAxis = (g, obj) => {
  g.attr("transform", `translate(${margin.left},0)`)
    .call(d3.axisLeft(obj.y).ticks(3))
    .call(g => g.select(".domain").remove());
}

const prepareChart = (obj) => {
  const data = JSON.parse(obj.el.dataset.chartdata).map(d => ({t: new Date(d.t), c: d.c, d: d.d}));
  obj.data = d3.stack().keys(["d", "c"])(data);
  obj.max = obj.el.dataset.max;

  obj.color = d3.scaleOrdinal()
    .range(colors[obj.el.dataset.colorScheme]);

  obj.x = d3.scaleUtc()
    .domain(d3.extent(data, d => d.t))
    .range([margin.left, width - margin.right]);

  obj.y = d3.scaleLinear()
    .domain([0, obj.max]).nice()
    .range([height - margin.bottom, margin.top]);

  obj.area = d3.area()
    .x(d => obj.x(d.data.t))
    .y0(d => obj.y(d[0]))
    .y1(d => obj.y(d[1]));
}

export const initChart = (obj) => {
  prepareChart(obj);

  const svg = d3.select(obj.el)
    .append("svg")
    .attr("class", "chart")
    .attr("viewBox", [0, 0, width, height]);

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
