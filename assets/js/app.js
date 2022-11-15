// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).
import '../css/app.scss'

// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "./vendor/some-package.js"
//
// Alternatively, you can `npm install some-package` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import 'phoenix_html'
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from 'phoenix'
import {LiveSocket} from 'phoenix_live_view'
import topbar from '../vendor/topbar'

let timerId = null;
let timer = null;

const displayTimer = (number) => {
  const countdowns = document.getElementsByClassName('countdown');

  let seconds = parseInt(number % 60, 10);
  if (seconds < 0) {
    seconds = 0;
  }

  seconds = seconds < 10 ? '0' + seconds : seconds;

  for (let element of countdowns) {
    element.textContent = seconds
  }
}

const startTimer = function(elem) {
  timer = elem.dataset.countdown - 1;
  timerId = setInterval(function () {
    displayTimer(timer);
    timer--;
  }, 1000);
};

const Hooks = {};

/*Hooks.Global = {
  reconnected() {
    const space_codename = document.querySelector('body').dataset.space;
    window.location.href = `/${space_codename}`;
  }
};*/

Hooks.Game = {
  mounted() {
    this.handleEvent('update_name', ({name}) => document.cookie = `name=${name}; Expires=Sat, 2 Mar 2035 20:30:40 GMT; path=/`);
  }
};

Hooks.Countdown = {
  mounted() {
    // we don't do the timer through handleEvent as the delay it introduces makes it impractical
    if (this.el.innerHTML !== "0" && this.el.innerHTML !== "00" && this.el.dataset.state === "start") {
      startTimer(this.el)
    }
  },
  updated() {
    if (timerId !== null && this.el.dataset.state === "stop") {
      displayTimer(timer);
      clearInterval(timerId);
      timerId = null;
    }
    else if (timerId === null && this.el.dataset.state === "start" && this.el.innerHTML !== "0") {
      startTimer(this.el)
    }
    else {
      displayTimer(timer);
    }
  }
};

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {hooks: Hooks, params: {_csrf_token: csrfToken}})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", info => topbar.show())
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
