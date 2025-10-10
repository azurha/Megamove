// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/megamove"
import * as L from "leaflet"
// Fix URLs for default Leaflet marker icons by pointing to static assets
L.Icon.Default.mergeOptions({
  iconRetinaUrl: "/images/leaflet/marker-icon-2x.png",
  iconUrl: "/images/leaflet/marker-icon.png",
  shadowUrl: "/images/leaflet/marker-shadow.png",
})

// Simple polyline6 decoder (Valhalla uses precision 6). Returns array of [lat, lon]
function decodePolyline6(encoded) {
  if (!encoded || typeof encoded !== "string") return []
  let index = 0, lat = 0, lon = 0, coordinates = []
  const shift5 = () => {
    let result = 0, shift = 0, b
    do {
      b = encoded.charCodeAt(index++) - 63
      result |= (b & 0x1f) << shift
      shift += 5
    } while (b >= 0x20)
    return (result & 1) ? ~(result >> 1) : (result >> 1)
  }
  while (index < encoded.length) {
    lat += shift5()
    lon += shift5()
    coordinates.push([lat / 1e6, lon / 1e6])
  }
  return coordinates
}

const MapHook = {
  mounted() {
    this._mounted = true
    const tryInit = () => {
      if (!this._mounted) return
      const el = this.el
      // Wait until element has size to avoid Leaflet sizing errors
      const hasSize = el && el.offsetWidth > 0 && el.offsetHeight > 0 && document.body.contains(el)
      if (!hasSize) {
        return requestAnimationFrame(tryInit)
      }
      // Init map once
      this.map = L.map(el).setView([46.5, 2.5], 6)
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; OpenStreetMap contributors'
      }).addTo(this.map)
      this.markerLayer = L.layerGroup().addTo(this.map)
      this.polylineLayer = L.layerGroup().addTo(this.map)

      // Keep map sized when container changes
      if (window.ResizeObserver) {
        this._resizeObserver = new ResizeObserver(() => {
          if (this.map) this.map.invalidateSize({animate: false})
        })
        this._resizeObserver.observe(el)
      }

      this.drawAll()
      // Invalidate once after first render
      setTimeout(() => this.map && this.map.invalidateSize({animate: false}), 0)
    }
    requestAnimationFrame(tryInit)
  },
  destroyed() {
    this._mounted = false
    if (this._resizeObserver) {
      try { this._resizeObserver.disconnect() } catch (_e) {}
      this._resizeObserver = null
    }
    if (this.map) {
      try { this.map.remove() } catch (_e) {}
      this.map = null
    }
  },
  updated() {
    this.drawAll()
    if (this.map) this.map.invalidateSize({animate: false})
  },
  parseJSONDataset(key, defVal) {
    const raw = this.el.dataset[key]
    if (!raw) return defVal
    try { return JSON.parse(raw) } catch (_e) { return defVal }
  },
  drawAll() {
    if (!this.map || !this.markerLayer || !this.polylineLayer) return
    const markers = this.parseJSONDataset("markers", [])
    const polylines = this.parseJSONDataset("polylines", [])
    const fit = this.el.dataset.fit !== "false"

    this.markerLayer.clearLayers()
    this.polylineLayer.clearLayers()

    const bounds = []

    // Draw markers
    markers.forEach(m => {
      if (typeof m.lat === "number" && typeof m.lon === "number") {
        const ll = [m.lat, m.lon]
        const markerOptions = {}
        if (m.color && typeof m.color === "string") {
          markerOptions.icon = L.divIcon({
            className: "mm-map-badge-marker",
            html: `<span class="mm-pin" style="--mm-pin-color: ${m.color}"></span>`,
            iconSize: [24, 36],
            iconAnchor: [12, 36],
            tooltipAnchor: [0, -28]
          })
        }
        const marker = L.marker(ll, markerOptions)
        if (m.label) marker.bindTooltip(String(m.label))
        marker.addTo(this.markerLayer)
        bounds.push(ll)
      }
    })

    // Draw polylines
    polylines.forEach(p => {
      let coords = []
      if (p && typeof p.shape === "string") {
        coords = decodePolyline6(p.shape)
      } else if (p && Array.isArray(p.shape)) {
        coords = p.shape
      }
      if (coords.length > 0) {
        const line = L.polyline(coords, {
          color: p.color || '#2563eb',
          weight: p.weight || 4,
          opacity: p.opacity || 1
        }).addTo(this.polylineLayer)
        const lb = line.getBounds()
        bounds.push(lb.getNorthWest())
        bounds.push(lb.getSouthEast())
      }
    })

    if (fit && bounds.length > 0) {
      this.map.fitBounds(bounds, {padding: [20, 20]})
    }
  }
}

const AddressAutocompleteHook = {
  mounted() {
    this.handleOutsideClick = this.handleOutsideClick.bind(this)
    this.handleKeyDown = this.handleKeyDown.bind(this)
    document.addEventListener("pointerdown", this.handleOutsideClick, true)
    document.addEventListener("keydown", this.handleKeyDown)
  },
  destroyed() {
    document.removeEventListener("pointerdown", this.handleOutsideClick, true)
    document.removeEventListener("keydown", this.handleKeyDown)
  },
  handleOutsideClick(event) {
    if (!this.el.contains(event.target)) {
      this.pushEventTo(this.el, "dismiss", {})
    }
  },
  handleKeyDown(event) {
    if (event.key === "Escape" || event.key === "Esc") {
      this.pushEventTo(this.el, "dismiss", {})
    }
  }
}

const AutosizeTextareaHook = {
  mounted() {
    this.resize = this.resize.bind(this)
    this.el.style.overflow = "hidden"
    this.resize()
    this.el.addEventListener("input", this.resize)
  },
  updated() {
    this.resize()
  },
  destroyed() {
    this.el.removeEventListener("input", this.resize)
  },
  resize() {
    const el = this.el
    if (!el) return
    el.style.height = "auto"
    el.style.height = `${Math.max(el.scrollHeight, 44)}px`
  }
}
import topbar from "../vendor/topbar"

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const hooks = {...colocatedHooks, Map: MapHook, AddressAutocomplete: AddressAutocompleteHook, AutosizeTextarea: AutosizeTextareaHook}
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks,
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

