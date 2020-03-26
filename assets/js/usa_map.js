import * as d3 from "d3"
import * as topojson from "topojson-client"

const colors = [
	"#e8e8e8", "#b5c0da", "#6c83b5",
	"#b8d6be", "#90b2b3", "#567994",
	"#73ae80", "#5a9178", "#2a5a5b"
]

const color = (obj, value) => {
	if (!value) return "#ccc";
	let [a, b] = value;
	return colors[obj.y(b) + obj.x(a) * obj.n];
};

const labels = ["low", "", "high"];

const format = (obj, value, titles) => {
	if (!value) return "N/A";
	let [a, b] = value;
	return `${a}% ${titles[0]}${labels[obj.x(a)] && ` (${labels[obj.x(a)]})`}
${b}% ${titles[1]}${labels[obj.y(b)] && ` (${labels[obj.y(b)]})`}`;
};

const path = d3.geoPath();

const initMap = (obj) => {
	obj.target = document.getElementById(obj.el.dataset.target);
	const data = Object.assign(new Map(Object.entries(JSON.parse(obj.el.dataset.mapdata))), {title: ["Diabetes", "Obesity"]});

	obj.n = Math.floor(Math.sqrt(colors.length));
	obj.x = d3.scaleQuantile(Array.from(data.values(), d => d[0]), d3.range(obj.n));
	obj.y = d3.scaleQuantile(Array.from(data.values(), d => d[1]), d3.range(obj.n));

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
			.attr("fill", d => color(obj, data.get(d.id)))
			.attr("d", path)
			.append("title")
			.text(d => `${d.properties.name}, ${obj.states.get(d.id.slice(0, 2)).name}
${format(obj, data.get(d.id), data.title)}`);

		svg.append("path")
			.datum(topojson.mesh(us, us.objects.states, (a, b) => a !== b))
			.attr("fill", "none")
			.attr("stroke", "white")
			.attr("stroke-linejoin", "round")
			.attr("d", path);
	});
};

const updateMap = (obj) => {
	const data = Object.assign(new Map(Object.entries(JSON.parse(obj.el.dataset.mapdata))), {title: ["Diabetes", "Obesity"]});

	d3.select(obj.target)
		.select("svg")
		.select("g")
		.selectAll("path")
		.attr("fill", d => color(obj, data.get(d.id)))
		.select("title")
		.text(d => `${d.properties.name}, ${obj.states.get(d.id.slice(0, 2)).name}
${format(obj, data.get(d.id), data.title)}`);
};

const USAMap = {
	mounted() {
		console.log("MOUNTED");
		initMap(this);
	},

	updated() {
		console.log("UPDATED");
		updateMap(this);
	}
};

export default USAMap;
