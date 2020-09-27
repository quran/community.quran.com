var bind = function (fn, me) {
    return function () {
        return fn.apply(me, arguments);
    };
};

Utility.ImageZoomer = (function () {
    function ImageZoomer(imgUrl) {
        this.trackTransforms = bind(this.trackTransforms, this);
        this.redraw = bind(this.redraw, this);
        this.bindEvents = bind(this.bindEvents, this);
        this.handleScroll = bind(this.handleScroll, this);
        this.zoom = bind(this.zoom, this);
        this.savePosition = bind(this.savePosition, this);
        this.transform = bind(this.transform, this);
        this.changeImage = bind(this.changeImage, this);
        this.zoomVal = 0;
        this.canvas = document.getElementsByTagName('canvas')[0];
        this.image = new Image;
        this.ctx = this.canvas.getContext('2d');
        this.image.src = imgUrl;
        this.lastX = this.canvas.width / 2;
        this.lastY = this.canvas.height / 2;
        this.trackTransforms(this.ctx);
        this.redraw();
        this.bindEvents();
        return this;
    }

    ImageZoomer.prototype.changeImage = function (newUrl) {
        this.image.src = newUrl;
        return this.redraw();
    };

    ImageZoomer.prototype.transform = function (x, y) {
        this.lastX = x;
        return this.lastY = y;
    };

    ImageZoomer.prototype.savePosition = function (x, y) {
        $(".pos-x").val(x);
        return $(".pos-y").val(y);
    };

    ImageZoomer.prototype.zoom = function (clicks) {
        var factor, pt, scaleFactor;
        this.zoomVal += clicks;
        $(".zoom").val(this.zoomVal);
        scaleFactor = 1.1;
        pt = this.ctx.transformedPoint(this.lastX, this.lastY);
        this.ctx.translate(pt.x, pt.y);
        factor = Math.pow(scaleFactor, clicks);
        this.ctx.scale(factor, factor);
        this.ctx.translate(-pt.x, -pt.y);
        this.redraw();
    };

    ImageZoomer.prototype.handleScroll = function (evt) {
        var delta;
        delta = evt.wheelDelta ? evt.wheelDelta / 40 : evt.detail ? -evt.detail : 0;
        if (delta) {
            this.zoom(delta);
        }
        return evt.preventDefault() && false;
    };

    ImageZoomer.prototype.bindEvents = function () {
        var dragStart, dragged, that;
        dragStart = void 0;
        dragged = void 0;
        this.canvas.addEventListener('DOMMouseScroll', this.handleScroll, false);
        this.canvas.addEventListener('mousewheel', this.handleScroll, false);
        that = this;
        this.canvas.addEventListener('mousedown', (function (evt) {
            document.body.style.mozUserSelect = document.body.style.webkitUserSelect = document.body.style.userSelect = 'none';
            that.lastX = evt.offsetX || evt.pageX - that.canvas.offsetLeft;
            that.lastY = evt.offsetY || evt.pageY - that.canvas.offsetTop;
            that.savePosition(that.lastX, that.lastY);
            dragStart = that.ctx.transformedPoint(that.lastX, that.lastY);
            dragged = false;
        }), false);
        this.canvas.addEventListener('mousemove', (function (evt) {
            var lastX, lastY, pt;
            lastX = evt.offsetX || evt.pageX - that.canvas.offsetLeft;
            lastY = evt.offsetY || evt.pageY - that.canvas.offsetTop;
            dragged = true;
            if (dragStart) {
                pt = that.ctx.transformedPoint(lastX, lastY);
                that.ctx.translate(pt.x - dragStart.x, pt.y - dragStart.y);
                that.redraw();
            }
        }), false);
        return this.canvas.addEventListener('mouseup', (function (evt) {
            document.body.style.mozUserSelect = document.body.style.webkitUserSelect = document.body.style.userSelect = 'auto';
            dragStart = null;
            if (!dragged) {
                that.zoom(evt.shiftKey ? -1 : 1);
            }
        }), false);
    };

    ImageZoomer.prototype.redraw = function () {
        var p1, p2;
        p1 = this.ctx.transformedPoint(0, 0);
        p2 = this.ctx.transformedPoint(this.canvas.width, this.canvas.height);
        this.ctx.save();
        this.ctx.setTransform(1, 0, 0, 1, 0, 0);
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        this.ctx.restore();
        this.ctx.drawImage(this.image, 0, 0);
    };

    ImageZoomer.prototype.trackTransforms = function (ctx) {
        var pt, restore, rotate, save, savedTransforms, scale, setTransform, svg, transform, translate, xform;
        svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
        xform = svg.createSVGMatrix();
        ctx.getTransform = function () {
            return xform;
        };
        savedTransforms = [];
        save = ctx.save;
        ctx.save = function () {
            savedTransforms.push(xform.translate(0, 0));
            return save.call(ctx);
        };
        restore = ctx.restore;
        ctx.restore = function () {
            xform = savedTransforms.pop();
            return restore.call(ctx);
        };
        scale = ctx.scale;
        ctx.scale = function (sx, sy) {
            xform = xform.scaleNonUniform(sx, sy);
            return scale.call(ctx, sx, sy);
        };
        rotate = ctx.rotate;
        ctx.rotate = function (radians) {
            xform = xform.rotate(radians * 180 / Math.PI);
            return rotate.call(ctx, radians);
        };
        translate = ctx.translate;
        ctx.translate = function (dx, dy) {
            xform = xform.translate(dx, dy);
            return translate.call(ctx, dx, dy);
        };
        transform = ctx.transform;
        ctx.transform = function (a, b, c, d, e, f) {
            var m2;
            m2 = svg.createSVGMatrix();
            m2.a = a;
            m2.b = b;
            m2.c = c;
            m2.d = d;
            m2.e = e;
            m2.f = f;
            xform = xform.multiply(m2);
            return transform.call(ctx, a, b, c, d, e, f);
        };
        setTransform = ctx.setTransform;
        ctx.setTransform = function (a, b, c, d, e, f) {
            xform.a = a;
            xform.b = b;
            xform.c = c;
            xform.d = d;
            xform.e = e;
            xform.f = f;
            return setTransform.call(ctx, a, b, c, d, e, f);
        };
        pt = svg.createSVGPoint();
        return ctx.transformedPoint = function (x, y) {
            pt.x = x;
            pt.y = y;
            return pt.matrixTransform(xform.inverse());
        };
    };

    return ImageZoomer;

})();
