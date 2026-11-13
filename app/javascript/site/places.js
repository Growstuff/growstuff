const placesMapElement = document.getElementById("placesmap");
if (placesMapElement !== null) {
  var places_base_path = "/places";

  var placesmap;

  // The page of a place knows where it is, from the server; any other page, and a place we couldn't find, shows the world.
  var latitude = parseFloat(placesMapElement.dataset.latitude);
  var longitude = parseFloat(placesMapElement.dataset.longitude);
  if (location.pathname !== places_base_path && location.pathname !== '/' && !isNaN(latitude) && !isNaN(longitude)) {
    placesmap = L.map('placesmap').setView([latitude, longitude], 5);
  } else {
    placesmap = L.map('placesmap').setView([0.0, -0.0], 2);
  }
  showMap(placesmap);
}

function showMap(placesmap) {
  L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
    maxZoom: 18
  }).addTo(placesmap);

  var markers = new L.MarkerClusterGroup({showCoverageOnHover: false, maxClusterRadius: 20 });

  var members_url = location.pathname + '.json';

  // Icon documentation: https://leafletjs.com/reference-1.5.0.html#icon
  var default_marker_icon = L.icon({
    iconUrl: placesMapElement.dataset.markerIcon,
    iconSize: [48, 48],
    iconAnchor: [24, 48],
    popupAnchor: [0, -46],
  });

  $.getJSON(members_url, function(members) {
    $.each(members, function(i, m) {
      if (m.latitude && m.longitude) {
        var marker = new L.Marker(new L.LatLng(m.latitude, m.longitude), {icon: default_marker_icon});
        var link = "<p><a href='/members/" + m.slug + "'>" + m.login_name + "</a></p>";
        var where = "<p><i>" + m.location + "</i></p>";
        marker.bindPopup(link + where).openPopup();
        markers.addLayer(marker);
      }
    });
  });

  function fetchCropsForMap(url, page = 1) {
    $.getJSON(url, function(crop_data) {
      $.each(crop_data['data'], function(i, p) {
        if (p.attributes.latitude && p.attributes.longitude) {
          var crop_marker = L.icon({
            iconUrl: "/crops/" + p.attributes['crop-slug'] + '.svg',
            iconSize: [48, 48],
            iconAnchor: [24, 48],
            popupAnchor: [0, -46],
          });
          var marker = new L.Marker(new L.LatLng(p.attributes.latitude, p.attributes.longitude),
            {icon: crop_marker});
          var link = "<p><a href='/plantings/" + p.attributes.slug + "'>" + p.attributes['crop-name'] + "</a></p>";
          var where = "<p><i>" + p.attributes.location + "</i></p>";
          if (p.attributes['thumbnail']) {
            where += '<img src="' + p.attributes['thumbnail'] + '" alt="photo of planting">';
          }
          marker.bindPopup(link + where).openPopup();
          markers.addLayer(marker);
        }
      });
      // Fetch at most two pages of 100 active plantings.
      if (crop_data['links']['next'] && page < 2) {
        fetchCropsForMap(crop_data['links']['next'], page + 1);
      }
      return crop_data;
    });
  }
  fetchCropsForMap('/api/v1/plantings.json?filter[finished]=false&sort=-planted-at&page[size]=100');
  placesmap.addLayer(markers);
}
