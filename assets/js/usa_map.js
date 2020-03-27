// import * as d3 from "d3"
import * as topojson from "topojson-client"

const colors = [
	"#52b2c7", "#4e236c"
]

const color = (obj, value) => {
	if (!value) return "#ccc";
	let [a, b] = value;
	if (a == 0) return "#ccc";
	return obj.x(a);
};

const format = (obj, value) => {
	if (!value) return "N/A";
	let [a, b] = value;
	return `${a} cases
${b} deaths`;
};

const path = d3.geoPath();

const getData = (obj, id) => {
	const data = obj.data[obj.date];
	if (data) {
		return data[id];
	} else {
		return [0, 0];
	}
}

const initMap = (obj) => {
	obj.target = document.getElementById(obj.el.dataset.target);
	obj.data = JSON.parse(obj.el.dataset.mapdata);
	obj.date = obj.el.dataset.date;

	obj.x = d3.scaleLinear([0, obj.el.dataset.maxConfirmed], colors);
	obj.y = d3.scaleLinear([0, obj.el.dataset.maxDeceased], colors);

	d3.json("/data/us-counties.json").then((us) => {
		obj.us = us;
		obj.states = new Map(us.objects.states.geometries.map(d => [d.id, d.properties]));

		const svg = d3.select(obj.target)
			.append("svg")
			.attr("viewBox", [0, 0, 975, 610]);

		const date = obj.target.dataset.date;

		svg.append("g")
			.selectAll("path")
			.data(topojson.feature(us, us.objects.counties).features)
			.join("path")
			.attr("fill", d => color(obj, getData(obj, d.id)))
			.attr("d", path)
			.append("title")
			.text(d => `${d.properties.name}, ${obj.states.get(d.id.slice(0, 2)).name}
${format(obj, getData(obj, d.id))}`);

		svg.append("path")
			.datum(topojson.mesh(us, us.objects.states, (a, b) => a !== b))
			.attr("fill", "none")
			.attr("stroke", "white")
			.attr("stroke-linejoin", "round")
			.attr("d", path);
	});
};

const updateMap = (obj) => {
	obj.date = obj.el.dataset.date;

	d3.select(obj.target)
		.select("svg")
		.select("g")
		.selectAll("path")
		.attr("fill", d => color(obj, getData(obj, d.id)))
		.select("title")
		.text(d => `${d.properties.name}, ${obj.states.get(d.id.slice(0, 2)).name}
${format(obj, getData(obj, d.id))}`);
};

export default {
	mounted() {
		initMap(this);
	},

	updated() {
		updateMap(this);
	}
};
