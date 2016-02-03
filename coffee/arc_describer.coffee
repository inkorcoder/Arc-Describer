# ---------------------------------------------------------
# 
# author: 	Inkor
# date: 		02.02.2016
#
# This script can paint, animate and make adaptive radial
# bars.
# 
# ---------------------------------------------------------
# 
# OPTIONS:   (object)
#   start    [int|str] - start angle (degrees)
#   end      [int|str] - end angle (degrees)
#   rdiuses  [arr] - Inner and outer radius.
#                Both can change line width.
#   fill     [str] - Line background color (HEX).
# 
# METHODS:   (function)
#   .get() => object, {rect,options}
#   .set([options,delay,callback])
#       options  [obj] - start (degrees)
#                        end (degrees)
#                        easing (string)
#       delay    [int] - miliseconds
#       callback [fn]
# 
# ---------------------------------------------------------
# 
# CALLING:
# myArc = document.getElementById('myId');
# myArc.arArcDescriber({
# 	start: 90
# 	end: 190
# 	radiuses: ['90%','100%']
# 	fill: '#099'
# });
# 
# GETTING:
# console.log(myArc.get());
# 
# SETTING:
# myArc.set(
# {start:20, end:340, easing:'easeInQuad'}, 700, function(){
#    console.log('ok!');
# });
# 
# ---------------------------------------------------------
# 
# EASING:
# linear, easeInQuad, easeOutQuad, easeInOutQuad,
# easeInCubic, easeOutCubic, easeInOutCubic, easeInQuart,
# easeOutQuart, easeInOutQuart, easeInQuint, easeOutQuint,
# easeInOutQuint
# 
# examples: http://easings.net/
# 
# ---------------------------------------------------------
# 
# !!! --- !!! --- !!! --- !!! - !!! --- !!! --- !!! --- !!!
# !!! --- !!! --- !!! --- IMPORTANT --- !!! --- !!! --- !!!
# !!! --- !!! --- !!! --- !!! - !!! --- !!! --- !!! --- !!!
# You must write all necessary properties in data-attribute
# or in options object.
# 
# ---------------------------------------------------------
Object.prototype.ArcDescriber = (options)->

	# main object
	ctx = {}

	# initializing by data-attribute
	if this.getAttribute('data-options') isnt null and this.getAttribute('data-options').trim().length > 0 and !options
		# options string
		str = this.getAttribute('data-options').replace /\ /gim, ''
		# options object
		options = {}
		# parse
		options.start = parseFloat str.match(/start:(.+?)(\ |\n|\r|\t|,|\})/gim)[0].substr 6, 10
		options.end = parseFloat str.match(/end:(.+?)(\ |\n|\r|\t|,|\})/gim)[0].substr 4, 10
		options.radiuses = str.match(/\[(.+?)\]/gim)[0].split ','
		options.radiuses[0] = parseFloat options.radiuses[0].replace(/(\'|\"|\[|\]|\ |\%)/gim, '')
		options.radiuses[1] = parseFloat options.radiuses[1].replace(/(\'|\"|\[|\]|\ |\%)/gim, '')
		options.fill = str.match(/fill:(.+?)'/gi)[0].replace(/(\'|\"|\[|\]|\ |\%|fill\:)/gim, '')

	# initializing by options
	else if options
		ctx.options = options

	# Error
	else console.error('ArcDescriber :: It is no options!'); return

	# defines
	ctx.orientation = 'default'
	ctx.options = options
	ctx.startOptions = JSON.parse JSON.stringify options
	ctx.element = this

	# easing functions
	easing =
		linear: (t) ->
			t
		easeInQuad: (t) ->
			t * t
		easeOutQuad: (t) ->
			t * (2 - t)
		easeInOutQuad: (t) ->
			(if t < .5 then 2 * t * t else -1 + (4 - 2 * t) * t)
		easeInCubic: (t) ->
			t * t * t
		easeOutCubic: (t) ->
			(--t) * t * t + 1
		easeInOutCubic: (t) ->
			(if t < .5 then 4 * t * t * t else (t - 1) * (2 * t - 2) * (2 * t - 2) + 1)
		easeInQuart: (t) ->
			t * t * t * t
		easeOutQuart: (t) ->
			1 - (--t) * t * t * t
		easeInOutQuart: (t) ->
			(if t < .5 then 8 * t * t * t * t else 1 - 8 * (--t) * t * t * t)
		easeInQuint: (t) ->
			t * t * t * t * t
		easeOutQuint: (t) ->
			1 + (--t) * t * t * t * t
		easeInOutQuint: (t) ->
			(if t < .5 then 16 * t * t * t * t * t else 1 + 16 * (--t) * t * t * t * t)

	# -------------------------------------------------------
	# functions
	# -------------------------------------------------------

	# getting bounding box and center
	(ctx.getRect = ->
		# rect object
		ctx.rect = {
			width: ctx.element.clientWidth
			height: ctx.element.clientHeight
			center: {
				x: ctx.element.clientWidth / 2
				y: ctx.element.clientHeight / 2
			}
		}
		# find out orientation
		ctx.orientation = if ctx.rect.width > ctx.rect.height then 'horizontal' else 'vertical'
		# for inner radius
		if ctx.startOptions.radiuses[0].toString().indexOf('%') isnt -1
			ctx.options.radiuses[0] = (
				if ctx.orientation is 'horizontal'
					(ctx.rect.height / 2) * (parseFloat(ctx.startOptions.radiuses[0]) / 100)
				else (ctx.rect.width / 2) * (parseFloat(ctx.startOptions.radiuses[0]) / 100)
			)
		# for outer radius
		if ctx.startOptions.radiuses[1].toString().indexOf('%') isnt -1
			ctx.options.radiuses[1] = (
				if ctx.orientation is 'horizontal'
					(ctx.rect.height / 2) * (parseFloat(ctx.startOptions.radiuses[1]) / 100)
				else (ctx.rect.width / 2) * (parseFloat(ctx.startOptions.radiuses[1]) / 100)
			)
		# returns
		ctx.rect
	)()

	# change degrees
	ctx.polarToCartesian = (cx, cy, r, angle) ->
		angle = (angle - 90) * Math.PI / 180
		x: cx + r * Math.cos angle
		y: cy + r * Math.sin angle

	# function make the arc
	ctx.describeArc = (x, y, r, startAngle, endAngle, continueLine) ->
		start = ctx.polarToCartesian x, y, r, startAngle %= 360
		end = ctx.polarToCartesian x, y, r, endAngle %= 360
		large = Math.abs(endAngle - startAngle) >= 180
		alter = endAngle > startAngle
		"#{if continueLine then 'L' else 'M'}#{start.x},#{start.y}
		A#{r},#{r},0,
		#{if large then 1 else 0},
		#{if alter then 1 else 0},#{end.x},#{end.y}"

	# get the sector
	ctx.describeSector = (x, y, r, r2, startAngle, endAngle) ->
		"#{ctx.describeArc x, y, r, startAngle, endAngle}
		#{ctx.describeArc x, y, r2, endAngle, startAngle, on}Z"

	# draw the line
	ctx.paint = ->
		ctx.paper.setAttribute 'd', ctx.describeSector(
			ctx.rect.center.x,
			ctx.rect.center.y,
			ctx.options.radiuses[0],
			ctx.options.radiuses[1],
			options.start,
			options.end
		)
		ctx.paper.setAttribute 'fill', if options.fill then options.fill else '#000'

	# setter
	ctx.set = (defs, time, callbackFunction)->

		dif = []
		steps = []

		dif[0] = defs.start - ctx.options.start
		dif[1] = defs.end - ctx.options.end

		steps[0] = dif[0] / time
		steps[1] = dif[1] / time

		i = 0
		interval = setInterval ->
			if i <= 1
				ctx.paper.setAttribute 'd', ctx.describeSector(
					ctx.rect.center.x,
					ctx.rect.center.y,
					options.radiuses[0],
					options.radiuses[1],
					ctx.options.start + (steps[0] * (easing[if defs.easing then defs.easing else 'linear'] i) * time)
					ctx.options.end + (steps[1] * (easing[if defs.easing then defs.easing else 'linear'] i) * time)
				)
				i = i + (30) / time
			else
				clearInterval interval
				ctx.options.start = ctx.options.start + (steps[0] * (easing[if defs.easing then defs.easing else 'linear'] i) * time)
				ctx.options.end = ctx.options.end + (steps[1] * (easing[if defs.easing then defs.easing else 'linear'] i) * time)

				do callbackFunction if callbackFunction
		, time/(30)

	# getter
	ctx.get = ->
		{
			rect: ctx.rect
			options: ctx.options
		}

	# adaptive
	window.addEventListener 'resize', ->
		ctx.getRect()
		ctx.paint()

	# adding paper
	ctx.paper = document.createElementNS "http://www.w3.org/2000/svg", 'path'
	this.appendChild ctx.paper

	# first drawing
	ctx.paint()

	ctx