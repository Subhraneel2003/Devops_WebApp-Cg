<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Simple Weather</title>
  <style>
    :root{font-family:system-ui,-apple-system,Segoe UI,Roboto,Ubuntu,'Helvetica Neue',Arial;color:#0b2545}
    body{display:flex;align-items:center;justify-content:center;min-height:100vh;background:linear-gradient(180deg,#e6f0ff,white);margin:0}
    .card{width:360px;padding:20px;border-radius:12px;box-shadow:0 6px 22px rgba(11,37,69,.12);background:#fff}
    h1{font-size:18px;margin:0 0 12px}
    .row{display:flex;gap:8px;align-items:center}
    input[type="text"]{flex:1;padding:8px;border:1px solid #d7e2f5;border-radius:8px}
    button{padding:8px 12px;border-radius:8px;border:0;background:#0b63ff;color:white;cursor:pointer}
    .meta{margin-top:14px;display:flex;justify-content:space-between;align-items:center}
    .big{font-size:40px;font-weight:600}
    .small{font-size:13px;color:#415b87}
    .hint{font-size:12px;color:#7b8fb2;margin-top:10px}
  </style>
</head>
<body>
  <div class="card">
    <h1>Weather — Simple</h1>
    <div class="row">
      <input id="q" type="text" placeholder="Enter city (e.g. London) or leave blank for current location">
      <button id="go">Get</button>
    </div>
    <div id="out" class="meta" style="margin-top:16px">
      <div>
        <div id="place" class="small">—</div>
        <div id="desc" class="hint">No data yet</div>
      </div>
      <div style="text-align:right">
        <div id="temp" class="big">--°C</div>
        <div id="extra" class="small">—</div>
      </div>
    </div>
    <div class="hint">Powered by Open-Meteo (no API key required). City search uses Nominatim.</div>
  </div>

  <script>
    const el = id=>document.getElementById(id);
    const qEl = el('q'), go = el('go');

    async function fetchWeatherByCoords(lat, lon, placeName){
      el('place').textContent = placeName || `${lat.toFixed(3)}, ${lon.toFixed(3)}`;
      el('desc').textContent = 'Loading…';
      try{
        const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current_weather=true&temperature_unit=celsius&windspeed_unit=kmh`;
        const res = await fetch(url);
        if(!res.ok) throw new Error('Weather fetch failed');
        const data = await res.json();
        const cur = data.current_weather;
        if(!cur) throw new Error('No current weather');
        el('temp').textContent = `${Math.round(cur.temperature)}°C`;
        el('extra').textContent = `Wind ${Math.round(cur.windspeed)} km/h • ${cur.winddirection}°`;
        el('desc').textContent = weatherCodeToText(cur.weathercode || 0);
      }catch(err){
        el('desc').textContent = 'Unable to load weather';
        el('temp').textContent = '--°C';
        el('extra').textContent = '';
        console.error(err);
      }
    }

    // Minimal mapping from Open-Meteo weather codes to text
    function weatherCodeToText(code){
      const map = {
        0:'Clear sky',1:'Mainly clear',2:'Partly cloudy',3:'Overcast',
        45:'Fog',48:'Depositing rime fog',
        51:'Light drizzle',53:'Moderate drizzle',55:'Dense drizzle',
        61:'Slight rain',63:'Moderate rain',65:'Heavy rain',
        71:'Slight snow',73:'Moderate snow',75:'Heavy snow',
        80:'Rain showers',81:'Moderate showers',82:'Violent showers',
        95:'Thunderstorm',96:'Thunderstorm with hail'
      };
      return map[code] || 'Unknown';
    }

    async function geocodeCity(name){
      const url = `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(name)}&limit=1`;
      const res = await fetch(url, {headers:{'User-Agent':'simple-weather-app'}});
      if(!res.ok) throw new Error('Geocode failed');
      const arr = await res.json();
      if(!arr || arr.length===0) throw new Error('Location not found');
      return {lat:parseFloat(arr[0].lat), lon:parseFloat(arr[0].lon), name:arr[0].display_name};
    }

    async function handle(){
      const q = qEl.value.trim();
      el('desc').textContent = 'Searching…';
      if(q){
        try{
          const loc = await geocodeCity(q);
          await fetchWeatherByCoords(loc.lat, loc.lon, loc.name);
        }catch(e){
          el('desc').textContent = e.message || 'Search failed';
        }
      }else if(navigator.geolocation){
        el('desc').textContent = 'Getting location…';
        navigator.geolocation.getCurrentPosition(async pos=>{
          await fetchWeatherByCoords(pos.coords.latitude, pos.coords.longitude, 'Your location');
        }, err=>{
          el('desc').textContent = 'Geolocation denied — enter a city';
        });
      }else{
        el('desc').textContent = 'No geolocation — enter a city';
      }
    }

    go.addEventListener('click', handle);
    qEl.addEventListener('keydown', e=>{ if(e.key==='Enter') handle(); });

    // Try to load by geolocation on open
    (async ()=>{ if(!qEl.value) { try { if(navigator.geolocation) navigator.geolocation.getCurrentPosition(async pos=>{ await fetchWeatherByCoords(pos.coords.latitude,pos.coords.longitude,'Your location'); }); } catch(e){} } })();
  </script>
</body>
</html>
