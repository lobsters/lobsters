(function(window) {
  if (window.autosize !== undefined) {
    return;
  }

  // You can tune this if you'd like, purpose is to avoid thrashing the renderer
  const DEBOUNCE_RATE = 50;

  // Naive debounce
  function debounce(fn) {
    let timeout;
    return function(...args) {
      clearTimeout(timeout);
      timeout = setTimeout(() => { timeout = null; fn.apply(this, ...args) }, DEBOUNCE_RATE);
    }
  }

  function ua(regex) {
    return regex.test(window.navigator.userAgent)
  }

  window.autosize = function autosize(el) {

    // Dropping ES5 only means we can remove a lot of polyfill code.
    if (ua(/msie|trident/i)) {
      return;
    }

    const { lineHeight, borderTopWidth, borderBottomWidth } = getComputedStyle(el);

    function resize () {
      el.style.height = 'auto';
      el.style.height = el.scrollHeight + parseInt(borderTopWidth, 10) + parseInt(borderBottomWidth, 10) + 'px';
    }

    // Cleaning up event handlers isn't needed as lobste.rs only applies autosize on load.
    ['input', 'cut', 'paste'].forEach(event => {
      el.addEventListener(event, resize, false);
    });

    window.addEventListener('resize', debounce(resize), false);
  }
}

})(window);
