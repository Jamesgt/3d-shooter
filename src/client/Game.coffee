class Game

	w: 12
	h: 10
	tileSize: 60
	delay: 600
	temps: []
	lastStepTime: 0
	lastMoveTime: 0

	constructor: (@parentId) ->
		@map = new Array @h
		(@map[i] = new Array @w) for i in [0...@h]
		@x = Math.floor @w / 2
		@lastX = @x

		@initGui()

	initGui: ->
		@renderer = new THREE.WebGLRenderer antialias: yes
		@fillWindow()
		($ "##{@parentId}").append @renderer.domElement
		@renderer.domElement.style.backgroundImage = "url('res/lavatile.jpg')"

		jQuery('body').keydown (e) => @keydown(e) 
		$(window).bind 'resize', => @fillWindow()

		@scene = new THREE.Scene()
		@scene.add new THREE.AmbientLight 0xffffff

		@container = new THREE.Object3D()
		@scene.add @container

		material = @getMaterial 0x999999, 'res/water.jpg', true
		geometry = new THREE.PlaneGeometry @w * @tileSize, @h * @tileSize, 1, 1
		@base = new THREE.Mesh geometry, material
		@container.add @base

		material = @getMaterial 0xffffff, 'res/disturb.jpg'
		geometry = new THREE.SphereGeometry @tileSize/2-2, @tileSize, @tileSize
		@player = new THREE.Mesh geometry, material
		@container.add @player

		@enemyMaterial = @getMaterial 0xffffff, 'res/crate.gif'
		@enemyGeometry = new THREE.CubeGeometry @tileSize-2, @tileSize-2, @tileSize

		@bulletMaterial = @getMaterial 0xff0000, 'res/lavatile.jpg'
		@bulletGeometry = new THREE.SphereGeometry @tileSize/4, @tileSize/2, @tileSize/2

	getMaterial: (color, url, repeat = false) ->
		material = new THREE.MeshLambertMaterial color: color, shading: THREE.FlatShading
		if url?
			texture = THREE.ImageUtils.loadTexture url, {}, ->
				material.needsUpdate = yes
			if repeat
				texture.wrapS = texture.wrapT = THREE.RepeatWrapping;
				texture.premultiplyAlpha = true
				texture.repeat.set( 4, 4 );
			material.map = texture

		return material

	fillWindow: ->
		@renderer.setSize window.innerWidth, window.innerHeight
		@camera = new THREE.PerspectiveCamera 50, window.innerWidth / window.innerHeight, 1, 5000
		@camera.position.z = 500
		@camera.position.y = -550
		@camera.rotation.x = Math.PI / 4

	setPosition: (mesh, x, y) ->
		mesh.position.set (x - (Math.floor @w / 2) + 0.5) * @tileSize, (y - (Math.floor @h / 2) + 0.5) * @tileSize, @tileSize / 2

	keydown: (e) ->
		if @lastX is @x then switch e.keyCode
			when 37, 65 then if @x > 0 # left  arrow or 'a'
				@x--
				@lastMoveTime = e.timeStamp
			when 39, 68 then if @x < @w - 1 # right arrow or 'd'
				@x++
				@lastMoveTime = e.timeStamp
			when 32 # space
				@map[1][@lastX] = '*'

	step: ->
		#@statSurvive++ for x in [0...@w] when @map[0][x]
		@map.push @map.shift()

		for y in [@h-1..0] then for x in [0...@w]
			switch @map[y][x]
				when 'X'
					@map[y][x] = no
				when '*'
					@map[y][x] = no
					if @map[y+1]?[x] is 'E'
						@map[y+1]?[x] = 'X'
						continue
					@map[y+2]?[x] = if @map[y+2][x] is 'E' then 'X' else '*'

		for x in [0...@w]
			@map[@h-1][x] = if Math.random() > 0.95 then 'E' else no

		return

	render: ->
		requestAnimationFrame => @render()

		now = Date.now()
		if now - @lastStepTime > @delay
			@lastStepTime = now
			@step()
		progress = (now - @lastStepTime) / @delay

		@container.remove temp for temp in @temps
		@temps = []
		for y in [0...@h] then for x in [0...@w]
			switch @map[y][x]
				when 'E'
					enemy = new THREE.Mesh @enemyGeometry, @enemyMaterial
					@setPosition enemy, x, y
					enemy.position.y -= progress * @tileSize - 2
					if y is 0
						enemy.position.z -= 2 * progress * @tileSize - 2
						enemy.rotation.x += progress * Math.PI / 2
						enemy.scale.set 1-progress/2, 1-progress/2, 1-progress/2
					@container.add enemy
					@temps.push enemy
				when 'X'
					enemy = new THREE.Mesh @enemyGeometry, @enemyMaterial
					@setPosition enemy, x, y
					enemy.position.y -= progress * @tileSize - 2
					enemy.scale.set 1-progress, 1-progress, 1-progress
					@container.add enemy
					@temps.push enemy
				when '*'
					bullet = new THREE.Mesh @bulletGeometry, @bulletMaterial
					@setPosition bullet, x, y
					bullet.position.y += (progress - 0.5) * @tileSize - 2
					@container.add bullet
					@temps.push bullet

		oy = ( now * 0.00025 * -0.2 * 4 ) % 1;
		@base.material.map.offset.y = -oy

		moveProgress = (now - @lastMoveTime) / (@delay / 3)
		@setPosition @player, @lastX, 0
		if @lastX isnt @x
			diff = @lastX - @x
			@player.position.x -= @tileSize * diff * moveProgress
			moveProgress = 1 - moveProgress if moveProgress > 0.5
			@player.scale.x = 1 + moveProgress * Math.abs diff
			@player.material.transparent = yes
			@player.material.opacity = 1 - moveProgress
			@player.material.needsUpdate = yes

		if now - @lastMoveTime > @delay / 3
			@lastX = @x
			@player.scale.set 1, 1, 1
			@player.material.transparent = no
			@player.material.opacity = 1
			@player.material.needsUpdate = yes

		@renderer.render @scene, @camera
