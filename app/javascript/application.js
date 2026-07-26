// @ts-check

"use strict";

/** @type {(...args: ( [ string ] | [ParentNode,string] )) => Element|null} */
export const qS = (...args) => {
  return args.length === 1 ?
    document.querySelector(args[0]) :
    args[0].querySelector(args[1]);
};

/** @type {(...args: ( [ string ] | [ParentNode,string] )) => NodeListOf<Element>} */
export const qSA = (...args) => {
  return args.length === 1 ?
    document.querySelectorAll(args[0]) :
    args[0].querySelectorAll(args[1]);
}

document.addEventListener("DOMContentLoaded", () => {
  // replace absolute <time> with relative
  const now = parseInt(qS('body').dataset.nowUnix) || Date.now();
  for (const t of qSA('time[data-at-unix]')) {
    // parallel implementation in lib/time_ago_in_words.rb
    const secs = now - parseInt(t.dataset.atUnix);
    if (secs <= 5) {
      t.innerText = "just now"
    } else if (secs < 60) {
      t.innerText = "less than a minute ago"
    } else if (secs < (60 * 60)) {
      const mins = Math.floor(secs / 60.0)
      t.innerText = mins + " minute" + (mins > 1 ? "s" : "") + " ago"
    } else if (secs < (60 * 60 * 48)) {
      const hours = Math.floor(secs / 60.0 / 60.0)
      t.innerText = hours + " hour" + (hours > 1 ? "s" : "") + " ago"
    } else if (secs < (60 * 60 * 24 * 30)) {
      const days = Math.floor(secs / 60.0 / 60.0 / 24.0)
      t.innerText = days + " day" + (days > 1 ? "s" : "") + " ago"
    } else if (secs < (60 * 60 * 24 * 365)) {
      const months = Math.floor(secs / 60.0 / 60.0 / 24.0 / 30.0)
      t.innerText = months + " month" + (months > 1 ? "s" : "") + " ago"
    } else {
      const years = Math.floor(secs / 60.0 / 60.0 / 24.0 / 365.0)
      t.innerText = years + " year" + (years > 1 ? "s" : "") + " ago"
    }
  }
});
