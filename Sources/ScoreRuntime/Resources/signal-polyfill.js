/**
 * Minimal TC39 Signal Polyfill for Score Runtime.
 *
 * Implements Signal.State, Signal.Computed, and Signal.subtle.Watcher —
 * the subset of the TC39 Signals proposal required by score-runtime.js.
 *
 * Based on the TC39 Signal proposal (https://github.com/tc39/proposal-signals).
 */
;(function (global) {
  "use strict";

  // ── Dependency tracking ─────────────────────────────────────────────
  var currentComputed = null;

  // ── Signal.State ────────────────────────────────────────────────────
  function SignalState(initialValue) {
    this._value = initialValue;
    this._subscribers = new Set();
  }

  SignalState.prototype.get = function () {
    if (currentComputed !== null) {
      this._subscribers.add(currentComputed);
      currentComputed._sources.add(this);
    }
    return this._value;
  };

  SignalState.prototype.set = function (newValue) {
    if (this._value === newValue) return;
    this._value = newValue;
    var subs = Array.from(this._subscribers);
    for (var i = 0; i < subs.length; i++) {
      subs[i]._dirty = true;
    }
    notifyWatchers(subs);
  };

  // ── Signal.Computed ─────────────────────────────────────────────────
  function SignalComputed(fn) {
    this._fn = fn;
    this._value = undefined;
    this._dirty = true;
    this._sources = new Set();
    this._subscribers = new Set();
  }

  SignalComputed.prototype.get = function () {
    if (currentComputed !== null) {
      this._subscribers.add(currentComputed);
      currentComputed._sources.add(this);
    }
    if (this._dirty) {
      this._recompute();
    }
    return this._value;
  };

  SignalComputed.prototype._recompute = function () {
    // Unsubscribe from old sources.
    var oldSources = this._sources;
    this._sources = new Set();
    oldSources.forEach(function (src) {
      src._subscribers.delete(this);
    }.bind(this));

    var prev = currentComputed;
    currentComputed = this;
    try {
      this._value = this._fn();
    } finally {
      currentComputed = prev;
    }
    this._dirty = false;
  };

  // ── Watcher ─────────────────────────────────────────────────────────
  var allWatchers = [];

  function Watcher(notifyCallback) {
    this._callback = notifyCallback;
    this._watched = new Set();
    this._pending = [];
    allWatchers.push(this);
  }

  Watcher.prototype.watch = function () {
    for (var i = 0; i < arguments.length; i++) {
      this._watched.add(arguments[i]);
    }
  };

  Watcher.prototype.unwatch = function () {
    for (var i = 0; i < arguments.length; i++) {
      this._watched.delete(arguments[i]);
    }
  };

  Watcher.prototype.getPending = function () {
    var pending = this._pending.slice();
    this._pending.length = 0;
    return pending;
  };

  function notifyWatchers(dirtyComputeds) {
    for (var w = 0; w < allWatchers.length; w++) {
      var watcher = allWatchers[w];
      var hadPending = watcher._pending.length > 0;
      for (var c = 0; c < dirtyComputeds.length; c++) {
        if (watcher._watched.has(dirtyComputeds[c])) {
          watcher._pending.push(dirtyComputeds[c]);
        }
      }
      if (!hadPending && watcher._pending.length > 0) {
        watcher._callback();
      }
    }
  }

  function untrack(fn) {
    var prev = currentComputed;
    currentComputed = null;
    try {
      fn();
    } finally {
      currentComputed = prev;
    }
  }

  // ── Public API ──────────────────────────────────────────────────────
  global.Signal = {
    State: SignalState,
    Computed: SignalComputed,
    subtle: {
      Watcher: Watcher,
      untrack: untrack
    }
  };
})(globalThis);
