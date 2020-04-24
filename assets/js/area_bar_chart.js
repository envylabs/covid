const width = 270;
const height = 230;
const margin = {top: 0, right: 0, bottom: 20, left: 0};
const colors = ["rgb(137, 209, 188)", "rgb(0, 69, 27)"];

const formatComma = d3.format(",");

const xAxis = (g, obj) => {
  g.attr("transform", `translate(0,${height - margin.bottom})`)
    .attr('class', 'chart-xaxis')
    .call(d3.axisBottom(obj.x).tickFormat(d3.timeFormat("%b %d")).tickSize(2).tickValues([obj.date]));
}

const yAxis = (g, obj) => {
  g.attr("transform", `translate(${width + margin.left},0)`)
    .attr('class', 'chart-yaxis')
    .call(d3.axisLeft(obj.y).tickSize(width).tickValues([0, obj.max]).tickPadding(0).tickFormat(d => d > 0 ? `${formatComma(d)} total` : d));
}

const yAxis2 = (g, obj) => {
  g.attr("transform", `translate(${width + margin.left},0)`)
    .attr('class', 'chart-yaxis')
    .call(d3.axisLeft(obj.y2).tickSize(width).tickValues([0, obj.maxDelta]).tickPadding(0).tickFormat(d => d > 0 ? `${formatComma(d)} per day` : d));
}

const prepareChart = (obj) => {
  const data = JSON.parse(obj.el.dataset.chartdata).map(d => ({t: new Date(`${d.t}T12:00:00Z`), c: d.c, d: d.d}));
  obj.data = d3.stack().keys(["c"])(data);
  obj.date = data[data.length - 1].t;
  obj.max = obj.el.dataset.max;
  obj.maxDelta = d3.max(data.map(d => d.d));

  obj.color = d3.scaleOrdinal()
    .range(colors);

  obj.x = d3.scaleUtc()
    .domain(d3.extent(data, d => d.t))
    .range([margin.left, width - margin.right]);

  obj.y = d3.scaleLinear()
    .domain([0, obj.max])
    .range([height - margin.bottom - 60, margin.top]);

  obj.y2 = d3.scaleLinear()
    .domain([0, obj.maxDelta])
    .range([height - margin.bottom, height - margin.bottom - 60]);

  obj.area = d3.area()
    .x(d => obj.x(d.data.t))
    .y0(d => obj.y(d[0]))
    .y1(d => obj.y(d[1]));
}

export const initChart = (obj) => {
  prepareChart(obj);

  const svg = d3.select(obj.el)
    .append("svg")
    .attr("class", "chart-svg")
    .attr("viewBox", [0, 0, width, height]);

  svg.append("g")
    .selectAll("path")
    .data(obj.data)
    .join("path")
    .attr("fill", ({key}) => obj.color(key))
    .attr("d", obj.area);

  svg.selectAll("bar")
    .data(obj.data[0].map(d => d.data))
    .enter().append("rect")
    .style("fill", colors[1])
    .attr("x", d => obj.x(d.t))
    .attr("width", 3)
    .attr("y", d => obj.y2(d.d))
    .attr("height", d => height - margin.bottom - obj.y2(d.d));

  svg.append("g")
    .call(xAxis, obj);

  svg.append("g")
    .call(yAxis, obj);

  svg.append("g")
    .call(yAxis2, obj);
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
