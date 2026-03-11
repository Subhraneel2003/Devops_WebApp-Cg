<%@ page contentType="text/html;charset=UTF-8" language="java"%>
<!doctype html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Simple Weather</title>

<style>
:root {
	font-family: system-ui, -apple-system, Segoe UI, Roboto, Ubuntu,
		'Helvetica Neue', Arial;
	color: #0b2545
}

body {
	display: flex;
	align-items: center;
	justify-content: center;
	min-height: 100vh;
	background: linear-gradient(180deg, #e6f0ff, white);
	margin: 0
}

.card {
	width: 360px;
	padding: 20px;
	border-radius: 12px;
	box-shadow: 0 6px 22px rgba(11, 37, 69, .12);
	background: #fff
}

h1 {
	font-size: 18px;
	margin: 0 0 12px
}

.row {
	display: flex;
	gap: 8px;
	align-items: center
}

input[type="text"] {
	flex: 1;
	padding: 8px;
	border: 1px solid #d7e2f5;
	border-radius: 8px
}

button {
	padding: 8px 12px;
	border-radius: 8px;
	border: 0;
	background: #0b63ff;
	color: white;
	cursor: pointer
}

.meta {
	margin-top: 14px;
	display: flex;
	justify-content: space-between;
	align-items: center
}

.big {
	font-size: 40px;
	font-weight: 600
}

.small {
	font-size: 13px;
	color: #415b87
}

.hint {
	font-size: 12px;
	color: #7b8fb2;
	margin-top: 10px
}
</style>
</head>

<body>

	<div class="card">
		<h1>Weather — Simple</h1>

		<div class="row">
			<input id="q" type="text" placeholder="Enter city (e.g. London)">
			<button id="go">Get</button>
		</div>

		<div id="out" class="meta" style="margin-top: 16px">
			<div>
				<div id="place" class="small">—</div>
				<div id="desc" class="hint">No data yet</div>
			</div>

			<div style="text-align: right">
				<div id="temp" class="big">--°C</div>
				<div id="extra" class="small">—</div>
			</div>
		</div>

		<div class="hint">Powered by Open-Meteo API</div>
	</div>

	<script>

const el = id => document.getElementById(id);
const qEl = el("q");
const go = el("go");

async function fetchWeatherByCoords(lat, lon, placeName){

el("place").textContent = placeName || `${lat.toFixed(3)}, ${lon.toFixed(3)}`;
el("desc").textContent = "Loading...";

try{

const url ='https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current_weather=true';

const res = await fetch(url);
const data = await res.json();

const cur = data.current_weather;

el("temp").textContent = Math.round(cur.temperature) + "°C";
el("extra").textContent =
"Wind " + Math.round(cur.windspeed) + " km/h";

el("desc").textContent = weatherCodeToText(cur.weathercode);

}catch(err){

el("desc").textContent = "Unable to load weather";
el("temp").textContent = "--°C";
el("extra").textContent = "";

}

}

function weatherCodeToText(code){

const map = {
0:"Clear sky",
1:"Mainly clear",
2:"Partly cloudy",
3:"Overcast",
45:"Fog",
51:"Drizzle",
61:"Rain",
71:"Snow",
80:"Rain showers",
95:"Thunderstorm"
};

return map[code] || "Unknown";

}

async function geocodeCity(name){

const url =
`https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(name)}&limit=1`;

const res = await fetch(url);
const data = await res.json();

if(!data || data.length===0)
throw new Error("Location not found");

return {
lat:parseFloat(data[0].lat),
lon:parseFloat(data[0].lon),
name:data[0].display_name
};

}

async function handle(){

const q = qEl.value.trim();

if(q){

el("desc").textContent = "Searching...";

try{

const loc = await geocodeCity(q);
await fetchWeatherByCoords(loc.lat,loc.lon,loc.name);

}catch(e){

el("desc").textContent = e.message;

}

}else{

el("desc").textContent = "Enter a city name";

}

}

go.addEventListener("click",handle);

qEl.addEventListener("keydown",e=>{
if(e.key==="Enter") handle();
});

</script>

</body>
</html>