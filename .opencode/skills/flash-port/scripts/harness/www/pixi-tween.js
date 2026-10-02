(() => {
  // ../kadokadeo/resources/js/pixi-tween/Easing.js
  var Easing = {
    linear: function() {
      return function(t) {
        return t;
      };
    },
    inQuad: function() {
      return function(t) {
        return t * t;
      };
    },
    outQuad: function() {
      return function(t) {
        return t * (2 - t);
      };
    },
    inOutQuad: function() {
      return function(t) {
        t *= 2;
        if (t < 1) return 0.5 * t * t;
        return -0.5 * (--t * (t - 2) - 1);
      };
    },
    inCubic: function() {
      return function(t) {
        return t * t * t;
      };
    },
    outCubic: function() {
      return function(t) {
        return --t * t * t + 1;
      };
    },
    inOutCubic: function() {
      return function(t) {
        t *= 2;
        if (t < 1) return 0.5 * t * t * t;
        t -= 2;
        return 0.5 * (t * t * t + 2);
      };
    },
    inQuart: function() {
      return function(t) {
        return t * t * t * t;
      };
    },
    outQuart: function() {
      return function(t) {
        return 1 - --t * t * t * t;
      };
    },
    inOutQuart: function() {
      return function(t) {
        t *= 2;
        if (t < 1) return 0.5 * t * t * t * t;
        t -= 2;
        return -0.5 * (t * t * t * t - 2);
      };
    },
    inQuint: function() {
      return function(t) {
        return t * t * t * t * t;
      };
    },
    outQuint: function() {
      return function(t) {
        return --t * t * t * t * t + 1;
      };
    },
    inOutQuint: function() {
      return function(t) {
        t *= 2;
        if (t < 1) return 0.5 * t * t * t * t * t;
        t -= 2;
        return 0.5 * (t * t * t * t * t + 2);
      };
    },
    inSine: function() {
      return function(t) {
        return 1 - Math.cos(t * Math.PI / 2);
      };
    },
    outSine: function() {
      return function(t) {
        return Math.sin(t * Math.PI / 2);
      };
    },
    inOutSine: function() {
      return function(t) {
        return 0.5 * (1 - Math.cos(Math.PI * t));
      };
    },
    inExpo: function() {
      return function(t) {
        return t === 0 ? 0 : Math.pow(1024, t - 1);
      };
    },
    outExpo: function() {
      return function(t) {
        return t === 1 ? 1 : 1 - Math.pow(2, -10 * t);
      };
    },
    inOutExpo: function() {
      return function(t) {
        if (t === 0) return 0;
        if (t === 1) return 1;
        t *= 2;
        if (t < 1) return 0.5 * Math.pow(1024, t - 1);
        return 0.5 * (-Math.pow(2, -10 * (t - 1)) + 2);
      };
    },
    inCirc: function() {
      return function(t) {
        return 1 - Math.sqrt(1 - t * t);
      };
    },
    outCirc: function() {
      return function(t) {
        return Math.sqrt(1 - --t * t);
      };
    },
    inOutCirc: function() {
      return function(t) {
        t *= 2;
        if (t < 1) return -0.5 * (Math.sqrt(1 - t * t) - 1);
        return 0.5 * (Math.sqrt(1 - (t - 2) * (t - 2)) + 1);
      };
    },
    inElastic: function(a = 0.1, p = 0.4) {
      return function(t) {
        let s;
        if (t === 0) return 0;
        if (t === 1) return 1;
        if (!a || a < 1) {
          a = 1;
          s = p / 4;
        } else s = p * Math.asin(1 / a) / (2 * Math.PI);
        return -(a * Math.pow(2, 10 * (t - 1)) * Math.sin((t - 1 - s) * (2 * Math.PI) / p));
      };
    },
    outElastic: function(a = 0.1, p = 0.4) {
      return function(t) {
        let s;
        if (t === 0) return 0;
        if (t === 1) return 1;
        if (!a || a < 1) {
          a = 1;
          s = p / 4;
        } else s = p * Math.asin(1 / a) / (2 * Math.PI);
        return a * Math.pow(2, -10 * t) * Math.sin((t - s) * (2 * Math.PI) / p) + 1;
      };
    },
    inOutElastic: function(a = 0.1, p = 0.4) {
      return function(t) {
        let s;
        if (t === 0) return 0;
        if (t === 1) return 1;
        if (!a || a < 1) {
          a = 1;
          s = p / 4;
        } else s = p * Math.asin(1 / a) / (2 * Math.PI);
        t *= 2;
        if (t < 1) return -0.5 * (a * Math.pow(2, 10 * (t - 1)) * Math.sin((t - 1 - s) * (2 * Math.PI) / p));
        return a * Math.pow(2, -10 * (t - 1)) * Math.sin((t - 1 - s) * (2 * Math.PI) / p) * 0.5 + 1;
      };
    },
    inBack: function(v) {
      return function(t) {
        let s = v || 1.70158;
        return t * t * ((s + 1) * t - s);
      };
    },
    outBack: function(v) {
      return function(t) {
        let s = v || 1.70158;
        return --t * t * ((s + 1) * t + s) + 1;
      };
    },
    inOutBack: function(v) {
      return function(t) {
        let s = (v || 1.70158) * 1.525;
        t *= 2;
        if (t < 1) return 0.5 * (t * t * ((s + 1) * t - s));
        return 0.5 * ((t - 2) * (t - 2) * ((s + 1) * (t - 2) + s) + 2);
      };
    },
    inBounce: function() {
      return function(t) {
        return 1 - Easing.outBounce()(1 - t);
      };
    },
    outBounce: function() {
      return function(t) {
        if (t < 1 / 2.75) {
          return 7.5625 * t * t;
        } else if (t < 2 / 2.75) {
          t = t - 1.5 / 2.75;
          return 7.5625 * t * t + 0.75;
        } else if (t < 2.5 / 2.75) {
          t = t - 2.25 / 2.75;
          return 7.5625 * t * t + 0.9375;
        } else {
          t -= 2.625 / 2.75;
          return 7.5625 * t * t + 0.984375;
        }
      };
    },
    inOutBounce: function() {
      return function(t) {
        if (t < 0.5) return Easing.inBounce()(t * 2) * 0.5;
        return Easing.outBounce()(t * 2 - 1) * 0.5 + 0.5;
      };
    },
    customArray: function(arr) {
      if (!arr) return Easing.linear();
      return function(t) {
        return t;
      };
    }
  };
  var Easing_default = Easing;

  // ../kadokadeo/resources/js/pixi-tween/Tween.js
  var Tween = class _Tween extends window.PIXI.utils.EventEmitter {
    constructor(target, manager) {
      super();
      this.target = target;
      if (manager) this.addTo(manager);
      this.clear();
    }
    addTo(manager) {
      this.manager = manager;
      this.manager.addTween(this);
      return this;
    }
    chain(tween2) {
      if (!tween2) tween2 = new _Tween(this.target);
      this._chainTween = tween2;
      return tween2;
    }
    start() {
      this.active = true;
      return this;
    }
    stop() {
      this.active = false;
      this.emit("stop");
      return this;
    }
    to(data) {
      this._to = data;
      return this;
    }
    from(data) {
      this._from = data;
      return this;
    }
    remove() {
      if (!this.manager) return this;
      this.manager.removeTween(this);
      return this;
    }
    clear() {
      this.time = 0;
      this.active = false;
      this.easing = Easing_default.linear();
      this.expire = false;
      this.repeat = 0;
      this.loop = false;
      this.delay = 0;
      this.pingPong = false;
      this.isStarted = false;
      this.isEnded = false;
      this._to = null;
      this._from = null;
      this._delayTime = 0;
      this._elapsedTime = 0;
      this._repeat = 0;
      this._pingPong = false;
      this._chainTween = null;
      this.path = null;
      this.pathReverse = false;
      this.pathFrom = 0;
      this.pathTo = 0;
    }
    reset() {
      this._elapsedTime = 0;
      this._repeat = 0;
      this._delayTime = 0;
      this.isStarted = false;
      this.isEnded = false;
      if (this.pingPong && this._pingPong) {
        let _to = this._to;
        let _from = this._from;
        this._to = _from;
        this._from = _to;
        this._pingPong = false;
      }
      return this;
    }
    update(delta, deltaMS) {
      if (!this._canUpdate() && (this._to || this.path)) return;
      let _to, _from;
      if (this.delay > this._delayTime) {
        this._delayTime += deltaMS;
        return;
      }
      if (!this.isStarted) {
        this._parseData();
        this.isStarted = true;
        this.emit("start");
      }
      let time = this.pingPong ? this.time / 2 : this.time;
      if (time > this._elapsedTime) {
        let t = this._elapsedTime + deltaMS;
        let ended = t >= time;
        this._elapsedTime = ended ? time : t;
        this._apply(time);
        let realElapsed = this._pingPong ? time + this._elapsedTime : this._elapsedTime;
        this.emit("update", realElapsed);
        if (ended) {
          if (this.pingPong && !this._pingPong) {
            this._pingPong = true;
            _to = this._to;
            _from = this._from;
            this._from = _to;
            this._to = _from;
            if (this.path) {
              _to = this.pathTo;
              _from = this.pathFrom;
              this.pathTo = _from;
              this.pathFrom = _to;
            }
            this.emit("pingpong");
            this._elapsedTime = 0;
            return;
          }
          if (this.loop || this.repeat > this._repeat) {
            this._repeat++;
            this.emit("repeat", this._repeat);
            this._elapsedTime = 0;
            if (this.pingPong && this._pingPong) {
              _to = this._to;
              _from = this._from;
              this._to = _from;
              this._from = _to;
              if (this.path) {
                _to = this.pathTo;
                _from = this.pathFrom;
                this.pathTo = _from;
                this.pathFrom = _to;
              }
              this._pingPong = false;
            }
            return;
          }
          this.isEnded = true;
          this.active = false;
          this.emit("end");
          if (this._chainTween) {
            this._chainTween.addTo(this.manager);
            this._chainTween.start();
          }
        }
        return;
      }
    }
    _parseData() {
      if (this.isStarted) return;
      if (!this._from) this._from = {};
      _parseRecursiveData(this._to, this._from, this.target);
      if (this.path) {
        let distance = this.path.totalDistance();
        if (this.pathReverse) {
          this.pathFrom = distance;
          this.pathTo = 0;
        } else {
          this.pathFrom = 0;
          this.pathTo = distance;
        }
      }
    }
    _apply(time) {
      _recursiveApplyTween(this._to, this._from, this.target, time, this._elapsedTime, this.easing);
      if (this.path) {
        let time2 = this.pingPong ? this.time / 2 : this.time;
        let b = this.pathFrom;
        let c = this.pathTo - this.pathFrom;
        let d = time2;
        let t = this._elapsedTime / d;
        let distance = b + c * this.easing(t);
        let pos = this.path.getPointAtDistance(distance);
        this.target.position.set(pos.x, pos.y);
      }
    }
    _canUpdate() {
      return this.time && this.active && this.target;
    }
  };
  function _recursiveApplyTween(to, from, target, time, elapsed, easing) {
    for (let k in to) {
      if (!_isObject(to[k])) {
        let b = from[k];
        let c = to[k] - from[k];
        let d = time;
        let t = elapsed / d;
        target[k] = b + c * easing(t);
      } else {
        _recursiveApplyTween(to[k], from[k], target[k], time, elapsed, easing);
      }
    }
  }
  function _parseRecursiveData(to, from, target) {
    for (let k in to) {
      if (from[k] !== 0 && !from[k]) {
        if (_isObject(target[k])) {
          from[k] = JSON.parse(JSON.stringify(target[k]));
          _parseRecursiveData(to[k], from[k], target[k]);
        } else {
          from[k] = target[k];
        }
      }
    }
  }
  function _isObject(obj) {
    return Object.prototype.toString.call(obj) === "[object Object]";
  }

  // ../kadokadeo/resources/js/pixi-tween/TweenManager.js
  var TweenManager = class {
    constructor() {
      this.tweens = [];
      this._tweensToDelete = [];
      this._last = 0;
    }
    update(delta) {
      let deltaMS;
      if (!delta && delta !== 0) {
        deltaMS = this._getDeltaMS();
        delta = deltaMS / 1e3;
      } else {
        deltaMS = delta * 1e3;
      }
      for (let i = 0; i < this.tweens.length; i++) {
        let tween2 = this.tweens[i];
        if (tween2.active) {
          tween2.update(delta, deltaMS);
        }
        if (tween2.isEnded && tween2.expire) {
          tween2.remove();
        }
      }
      if (this._tweensToDelete.length) {
        for (let i = 0; i < this._tweensToDelete.length; i++) this._remove(this._tweensToDelete[i]);
        this._tweensToDelete.length = 0;
      }
    }
    getTweensForTarget(target) {
      let tweens = [];
      for (let i = 0; i < this.tweens.length; i++) {
        if (this.tweens[i].target === target) tweens.push(this.tweens[i]);
      }
      return tweens;
    }
    createTween(target) {
      return new Tween(target, this);
    }
    addTween(tween2) {
      tween2.manager = this;
      this.tweens.push(tween2);
    }
    removeTween(tween2) {
      this._tweensToDelete.push(tween2);
    }
    _remove(tween2) {
      let index = this.tweens.indexOf(tween2);
      if (index !== -1) this.tweens.splice(index, 1);
    }
    _getDeltaMS() {
      if (this._last === 0) this._last = Date.now();
      let now = Date.now();
      let deltaMS = now - this._last;
      this._last = now;
      return deltaMS;
    }
  };

  // ../kadokadeo/resources/js/pixi-tween/TweenPath.js
  var TweenPath = class {
    constructor() {
      this._colsed = false;
      this.polygon = new window.PIXI.Polygon();
      this.polygon.closed = false;
      this._tmpPoint = new window.PIXI.Point();
      this._tmpPoint2 = new window.PIXI.Point();
      this._tmpDistance = [];
      this.currentPath = null;
      this.graphicsData = [];
      this.dirty = true;
    }
    moveTo(x, y) {
      window.PIXI.Graphics.prototype.moveTo.call(this, x, y);
      this.dirty = true;
      return this;
    }
    lineTo(x, y) {
      window.PIXI.Graphics.prototype.lineTo.call(this, x, y);
      this.dirty = true;
      return this;
    }
    bezierCurveTo(cpX, cpY, cpX2, cpY2, toX, toY) {
      window.PIXI.Graphics.prototype.bezierCurveTo.call(this, cpX, cpY, cpX2, cpY2, toX, toY);
      this.dirty = true;
      return this;
    }
    quadraticCurveTo(cpX, cpY, toX, toY) {
      window.PIXI.Graphics.prototype.quadraticCurveTo.call(this, cpX, cpY, toX, toY);
      this.dirty = true;
      return this;
    }
    arcTo(x1, y1, x2, y2, radius) {
      window.PIXI.Graphics.prototype.arcTo.call(this, x1, y1, x2, y2, radius);
      this.dirty = true;
      return this;
    }
    arc(cx, cy, radius, startAngle, endAngle, anticlockwise) {
      window.PIXI.Graphics.prototype.arc.call(this, cx, cy, radius, startAngle, endAngle, anticlockwise);
      this.dirty = true;
      return this;
    }
    drawShape(shape) {
      window.PIXI.Graphics.prototype.drawShape.call(this, shape);
      this.dirty = true;
      return this;
    }
    getPoint(num) {
      this.parsePoints();
      let len = this.closed && num >= this.length - 1 ? 0 : num * 2;
      this._tmpPoint.set(this.polygon.points[len], this.polygon.points[len + 1]);
      return this._tmpPoint;
    }
    distanceBetween(num1, num2) {
      this.parsePoints();
      let { x: p1X, y: p1Y } = this.getPoint(num1);
      let { x: p2X, y: p2Y } = this.getPoint(num2);
      let dx = p2X - p1X;
      let dy = p2Y - p1Y;
      return Math.sqrt(dx * dx + dy * dy);
    }
    totalDistance() {
      this.parsePoints();
      this._tmpDistance.length = 0;
      this._tmpDistance.push(0);
      let len = this.length;
      let distance = 0;
      for (let i = 0; i < len - 1; i++) {
        distance += this.distanceBetween(i, i + 1);
        this._tmpDistance.push(distance);
      }
      return distance;
    }
    getPointAt(num) {
      this.parsePoints();
      if (num > this.length) {
        return this.getPoint(this.length - 1);
      }
      if (num % 1 === 0) {
        return this.getPoint(num);
      } else {
        this._tmpPoint2.set(0, 0);
        let diff = num % 1;
        let { x: ceilX, y: ceilY } = this.getPoint(Math.ceil(num));
        let { x: floorX, y: floorY } = this.getPoint(Math.floor(num));
        let xx = -((floorX - ceilX) * diff);
        let yy = -((floorY - ceilY) * diff);
        this._tmpPoint2.set(floorX + xx, floorY + yy);
        return this._tmpPoint2;
      }
    }
    getPointAtDistance(distance) {
      this.parsePoints();
      if (!this._tmpDistance) this.totalDistance();
      let len = this._tmpDistance.length;
      let n = 0;
      let totalDistance = this._tmpDistance[this._tmpDistance.length - 1];
      if (distance < 0) {
        distance = totalDistance + distance;
      } else if (distance > totalDistance) {
        distance = distance - totalDistance;
      }
      for (let i = 0; i < len; i++) {
        if (distance >= this._tmpDistance[i]) {
          n = i;
        }
        if (distance < this._tmpDistance[i]) break;
      }
      if (n === this.length - 1) {
        return this.getPointAt(n);
      }
      let diff1 = distance - this._tmpDistance[n];
      let diff2 = this._tmpDistance[n + 1] - this._tmpDistance[n];
      return this.getPointAt(n + diff1 / diff2);
    }
    parsePoints() {
      if (!this.dirty) return this;
      this.dirty = false;
      this.polygon.points.length = 0;
      for (let i = 0; i < this.graphicsData.length; i++) {
        let shape = this.graphicsData[i].shape;
        if (shape && shape.points) {
          this.polygon.points = this.polygon.points.concat(shape.points);
        }
      }
      return this;
    }
    clear() {
      this.graphicsData.length = 0;
      this.currentPath = null;
      this.polygon.points.length = 0;
      this._closed = false;
      this.dirty = false;
      return this;
    }
    get closed() {
      return this._closed;
    }
    set closed(value) {
      if (this._closed === value) return;
      this.polygon.closed = value;
      this._closed = value;
      this.dirty = true;
    }
    get length() {
      return this.polygon.points.length ? this.polygon.points.length / 2 + (this._closed ? 1 : 0) : 0;
    }
  };

  // ../kadokadeo/resources/js/pixi-tween/index.js
  window.PIXI.Graphics.prototype.drawPath = function(path) {
    path.parsePoints();
    this.drawShape(path.polygon);
    return this;
  };
  var tween = {
    TweenManager,
    Tween,
    Easing: Easing_default,
    TweenPath
  };
  if (!window.PIXI.tweenManager) {
    window.PIXI.tweenManager = new TweenManager();
    window.PIXI.tween = tween;
  }
  var index_default = tween;
})();
