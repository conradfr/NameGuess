// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"

var $ = require("jquery");
import {Dropdown, DropdownMenu} from 'foundation-sites';

$(document).foundation();

// Import local files
//
// Local files can be imported directly using relative paths, for example:
// import socket from "./socket"

import {Socket} from "phoenix"
import LiveSocket from "phoenix_live_view"

let timerId = null;
let timer = null;

const startTimer = function(element) {
  const countdowns = document.getElementsByClassName('countdown');
  const duration = element.dataset.countdown - 1;
  timer = duration;
  timerId = setInterval(function () {
    let seconds = parseInt(timer % 60, 10);
    seconds = seconds < 10 ? "0" + seconds : seconds;

    for (let element of countdowns) {
      element.textContent = seconds
    }

    timer--;
  }, 1000);
};

let Hooks = {};
Hooks.Global = {
  reconnected() {
    const space_codename = document.querySelector('body').dataset.space;
    window.location.href = `/${space_codename}`;
  }
};

Hooks.UpdateName = {
  mounted() {
    document.cookie = `name=${this.el.dataset.name}; Expires=Sat, 2 Mar 2030 20:30:40 GMT; path=/`
  }
};

Hooks.Countdown = {
  mounted() {
    if (this.el.innerHTML !== "0" && this.el.dataset.state === "start") {
      startTimer(this.el)
    }
  },
  updated() {
    if (timerId !== null && this.el.dataset.state === "stop") {
      this.el.innerHTML = timer;
      clearInterval(timerId);
      timerId = null;
    }
    else if (timerId === null && this.el.dataset.state === "start" && this.el.innerHTML !== "0") {
      startTimer(this.el)
    }
    else {
      this.el.innerHTML = timer;
    }
  }
};

let liveSocket = new LiveSocket("/live", Socket, {hooks: Hooks});
liveSocket.connect();
