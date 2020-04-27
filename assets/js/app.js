// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"

import {Socket} from "phoenix"
import LiveSocket from "phoenix_live_view"

import AreaChart from "./area_chart"
import AreaBarChart from "./area_bar_chart"
import DateRange from "./date_range"
import Play from "./play"
import USAMap from "./usa_map"

import NProgress from "nprogress"

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => NProgress.done())

window.rona = {
	dates: [],
	date: null,
	map: null,
	slider: null
};

let Hooks = {
	AreaChart: AreaChart,
	AreaBarChart: AreaBarChart,
	DateRange: DateRange,
	Play: Play,
	USAMap: USAMap
};
let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks: Hooks});
liveSocket.connect();
