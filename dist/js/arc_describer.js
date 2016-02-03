Object.prototype.ArcDescriber = function(options) {
  var ctx, easing, str;
  ctx = {};
  if (this.getAttribute('data-options') !== null && this.getAttribute('data-options').trim().length > 0 && !options) {
    str = this.getAttribute('data-options').replace(/\ /gim, '');
    options = {};
    options.start = parseFloat(str.match(/start:(.+?)(\ |\n|\r|\t|,|\})/gim)[0].substr(6, 10));
    options.end = parseFloat(str.match(/end:(.+?)(\ |\n|\r|\t|,|\})/gim)[0].substr(4, 10));
    options.radiuses = str.match(/\[(.+?)\]/gim)[0].split(',');
    options.radiuses[0] = parseFloat(options.radiuses[0].replace(/(\'|\"|\[|\]|\ |\%)/gim, ''));
    options.radiuses[1] = parseFloat(options.radiuses[1].replace(/(\'|\"|\[|\]|\ |\%)/gim, ''));
    options.fill = str.match(/fill:(.+?)'/gi)[0].replace(/(\'|\"|\[|\]|\ |\%|fill\:)/gim, '');
  } else if (options) {
    ctx.options = options;
  } else {
    console.error('ArcDescriber :: It is no options!');
    return;
  }
  ctx.orientation = 'default';
  ctx.options = options;
  ctx.startOptions = JSON.parse(JSON.stringify(options));
  ctx.element = this;
  easing = {
    linear: function(t) {
      return t;
    },
    easeInQuad: function(t) {
      return t * t;
    },
    easeOutQuad: function(t) {
      return t * (2 - t);
    },
    easeInOutQuad: function(t) {
      if (t < .5) {
        return 2 * t * t;
      } else {
        return -1 + (4 - 2 * t) * t;
      }
    },
    easeInCubic: function(t) {
      return t * t * t;
    },
    easeOutCubic: function(t) {
      return (--t) * t * t + 1;
    },
    easeInOutCubic: function(t) {
      if (t < .5) {
        return 4 * t * t * t;
      } else {
        return (t - 1) * (2 * t - 2) * (2 * t - 2) + 1;
      }
    },
    easeInQuart: function(t) {
      return t * t * t * t;
    },
    easeOutQuart: function(t) {
      return 1 - (--t) * t * t * t;
    },
    easeInOutQuart: function(t) {
      if (t < .5) {
        return 8 * t * t * t * t;
      } else {
        return 1 - 8 * (--t) * t * t * t;
      }
    },
    easeInQuint: function(t) {
      return t * t * t * t * t;
    },
    easeOutQuint: function(t) {
      return 1 + (--t) * t * t * t * t;
    },
    easeInOutQuint: function(t) {
      if (t < .5) {
        return 16 * t * t * t * t * t;
      } else {
        return 1 + 16 * (--t) * t * t * t * t;
      }
    }
  };
  (ctx.getRect = function() {
    ctx.rect = {
      width: ctx.element.clientWidth,
      height: ctx.element.clientHeight,
      center: {
        x: ctx.element.clientWidth / 2,
        y: ctx.element.clientHeight / 2
      }
    };
    ctx.orientation = ctx.rect.width > ctx.rect.height ? 'horizontal' : 'vertical';
    if (ctx.startOptions.radiuses[0].toString().indexOf('%') !== -1) {
      ctx.options.radiuses[0] = (ctx.orientation === 'horizontal' ? (ctx.rect.height / 2) * (parseFloat(ctx.startOptions.radiuses[0]) / 100) : (ctx.rect.width / 2) * (parseFloat(ctx.startOptions.radiuses[0]) / 100));
    }
    if (ctx.startOptions.radiuses[1].toString().indexOf('%') !== -1) {
      ctx.options.radiuses[1] = (ctx.orientation === 'horizontal' ? (ctx.rect.height / 2) * (parseFloat(ctx.startOptions.radiuses[1]) / 100) : (ctx.rect.width / 2) * (parseFloat(ctx.startOptions.radiuses[1]) / 100));
    }
    return ctx.rect;
  })();
  ctx.polarToCartesian = function(cx, cy, r, angle) {
    angle = (angle - 90) * Math.PI / 180;
    return {
      x: cx + r * Math.cos(angle),
      y: cy + r * Math.sin(angle)
    };
  };
  ctx.describeArc = function(x, y, r, startAngle, endAngle, continueLine) {
    var alter, end, large, start;
    start = ctx.polarToCartesian(x, y, r, startAngle %= 360);
    end = ctx.polarToCartesian(x, y, r, endAngle %= 360);
    large = Math.abs(endAngle - startAngle) >= 180;
    alter = endAngle > startAngle;
    return "" + (continueLine ? 'L' : 'M') + start.x + "," + start.y + " A" + r + "," + r + ",0, " + (large ? 1 : 0) + ", " + (alter ? 1 : 0) + "," + end.x + "," + end.y;
  };
  ctx.describeSector = function(x, y, r, r2, startAngle, endAngle) {
    return (ctx.describeArc(x, y, r, startAngle, endAngle)) + " " + (ctx.describeArc(x, y, r2, endAngle, startAngle, true)) + "Z";
  };
  ctx.paint = function() {
    ctx.paper.setAttribute('d', ctx.describeSector(ctx.rect.center.x, ctx.rect.center.y, ctx.options.radiuses[0], ctx.options.radiuses[1], options.start, options.end));
    return ctx.paper.setAttribute('fill', options.fill ? options.fill : '#000');
  };
  ctx.set = function(defs, time, callbackFunction) {
    var dif, i, interval, steps;
    dif = [];
    steps = [];
    dif[0] = defs.start - ctx.options.start;
    dif[1] = defs.end - ctx.options.end;
    steps[0] = dif[0] / time;
    steps[1] = dif[1] / time;
    i = 0;
    return interval = setInterval(function() {
      if (i <= 1) {
        ctx.paper.setAttribute('d', ctx.describeSector(ctx.rect.center.x, ctx.rect.center.y, options.radiuses[0], options.radiuses[1], ctx.options.start + (steps[0] * (easing[defs.easing ? defs.easing : 'linear'](i)) * time), ctx.options.end + (steps[1] * (easing[defs.easing ? defs.easing : 'linear'](i)) * time)));
        return i = i + 30. / time;
      } else {
        clearInterval(interval);
        ctx.options.start = ctx.options.start + (steps[0] * (easing[defs.easing ? defs.easing : 'linear'](i)) * time);
        ctx.options.end = ctx.options.end + (steps[1] * (easing[defs.easing ? defs.easing : 'linear'](i)) * time);
        if (callbackFunction) {
          return callbackFunction();
        }
      }
    }, time / 30.);
  };
  ctx.get = function() {
    return {
      rect: ctx.rect,
      options: ctx.options
    };
  };
  window.addEventListener('resize', function() {
    ctx.getRect();
    return ctx.paint();
  });
  ctx.paper = document.createElementNS("http://www.w3.org/2000/svg", 'path');
  this.appendChild(ctx.paper);
  ctx.paint();
  return ctx;
};
