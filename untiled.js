p5.disableFriendlyErrors = true; // disables FES for better performance

// grid
var tiles = [];
var tileSize;
var gap;
var tilesPerRow = 16;				// needs to be an even number, maybe?
var limitedWidth = 800;
var limitedHeight = 800;

// switch between modes / shapes / blobs
var areOverlapping = true;
var areMorphing = false;
var morphCounter = 0;
var morphTime = 180;
var mode = 1;
const maxSwitchTime = 30; 		// in seconds
var nextModeSwitch = 10; 		// init with 10 seconds
var modeSwitchCounter = 0;
var nextShapeSwitch = 10; 		// init with 10 seconds
var shapeSwitchCounter = 0;
var nextBlobSwitch = 10; 		// init with 10 seconds
var blobSwitchCounter = 0;
var nextRotationSwitch = 10; 	// init with 10 seconds
var rotationSwitchCounter = 0;

// global rotation
var globalRotation = 0;
var rotationMode = 1;
var areRotating = false;
var areRotatingRandomDirections = false;

// blob mode
var blobMode = 0;
var areBlobbing;

// global stroke thickness
var strokeW; // strokeWeight
var strT = 0;   // strokeWeight noise value

// lerping
var lerpCount;
const lerpTime = 480;   // in frames

// background color lerping
var bgColor = 360;
var bgColorTarget;

// fill color alpha lerping
var fillAlpha = 0;
var fillAlphaTarget;

// fill color brightness lerping
var fillBrightness = 0;
var fillBrightnessTarget;

// stroke color brightness lerping
var strokeBrightness = 0;
var strokeBrightnessTarget;

// stroke color alpha lerping
var strokeAlpha = 100;
var strokeAlphaTarget;

// debug
var debug = false;

function setup() {
    createCanvas(limitedWidth, limitedHeight);      // limit for performance
	colorMode(HSB, 100, 100, 100, 100);
    rectMode(CENTER);
    frameRate(60);
    pixelDensity(1);    							// limit for performance

    buildGrid();
    pushTiles();
    randomMode();
	// rotationMode = 2;
	// applyRotationMode();							// set manual rotation mode
    randomRotationMode();
	// applyBlobMode(2); 							// for testing blobs
	randomBlobMode();
}

function draw() {
    background(bgColor);

    timedEvents();

    incMorphCounter();

    // translate tiles to middle of their position in grid
    translate(tileSize/2, tileSize/2);

    computeLerping();

    drawTiles();

    if (debug) showDebug();
}

// push tiles to list
function pushTiles() {
    for (let i = -1; i < (width / tileSize) + 1; i++) {
        for (let j = -1; j < (height / tileSize) + 1; j++) {
            tiles.push(new Tile(tileSize, i * tileSize, (j * tileSize), tiles.length));
        }
    }
    // shuffle once at beginning in order to not get fish scale effect
    shuffleArrayRandomly(tiles);
}

// draw all tiles in list
function drawTiles() {
    
    // reset bool
    areOverlapping = false;

    // change strokeWeight globally with noise
    strT += Math.random() * (.005 - .0005) + .0005; // use JS native random function for performance
    strokeW = map(noise(this.strT), 0, 1, -10, tileSize * (0.6)); // map from -10 so that it will "stick" to 1 sometimes
    if (strokeW <= 2) strokeW = 2;

    // increment globalRotation
    globalRotation += .02;

    // display tiles and check for scale
    for (let i = 0; i < tiles.length; i++) {
        let b = tiles[i];
        b.draw();
        
        // are any tiles overlapping? (if the scale is over 1 and it is not only circles then they are not overlapping); only set areOverlapping to true if it is false for performance
        if (((b.scale >= 1) || (b.state == 1)) && areOverlapping == false) areOverlapping = true;
    }
}

// determine grid
function buildGrid() {
    // determine size of single tiles
    tileSize = (width / tilesPerRow);

    // determine size of gap
    gap = - (tileSize / 5);
}

// switch the shapes in time interval
function switchShapes() {
    areMorphing = true;
    if (tiles[0].state == 1) console.log("circles");
    else console.log("squares");
    for (let i = 0; i < tiles.length; i++) {
        let b = tiles[i];
        b.state++;
        if (b.state > 1) {
            b.state = 0;
        }
    }
}

// increment counter to check if shapes are morphing or not (for rotationMode switching)
function incMorphCounter() {
    // increment counter and reset after 3 seconds (180 frames)
    morphCounter++;
    if (morphCounter > morphTime) {
        morphCounter = 0;
        areMorphing = false;
    }
    
}

// change between modes and rotation modes after X seconds if some conditions are met
function timedEvents() {
    modeSwitchCounter++;
    shapeSwitchCounter++;
	blobSwitchCounter++;
	rotationSwitchCounter++;
	
	//console.log(rotationSwitchCounter);

    //modes
    if (modeSwitchCounter > (nextModeSwitch * 60)) {
        randomMode();
        nextModeSwitch = floor(random(10, maxSwitchTime));
        modeSwitchCounter = 0;

        //console.log("next mode switch: + nextModeSwitch")
    }

    // shapes
    if (shapeSwitchCounter > (nextShapeSwitch * 60)) {
        switchShapes();
        if (tiles[0].state == 1) nextShapeSwitch = floor(random(10, maxSwitchTime));
        else nextShapeSwitch = floor(random(10, maxSwitchTime/2))     // circles should be there for less time than squares
        shapeSwitchCounter = 0;

        //console.log("next shape switch: " + nextShapeSwitch);
    }

	// blobs
	if (blobSwitchCounter > (nextBlobSwitch * 60)) {
        randomBlobMode();
        nextBlobSwitch = floor(random(10, maxSwitchTime));
        blobSwitchCounter = 0;

        //console.log("next blob switch: " + nextBlobSwitch);
    }

    // rotation modes
    // if only circles are there, and if the shapes aren't currently morphing or blobbing, switch between rotation modes
    // (to hide the transition between rotation and no rotation)
	if (rotationSwitchCounter > (nextRotationSwitch * 60) ) {
		//enhanced condition: wait for shapes to fully settle
		if (tiles[0].state == 0 && areMorphing == false && areBlobbing == false && areShapesSettled()) {
			// try to set to rotationMode 1 (not rotating) half of the time if mapping to actual tiles
			// if (rotationMode != 1) { 
			// 	rotationMode = 1;
			// 	applyRotationMode();
			// } else { 
			// 	randomRotationMode() 
			// };	
			randomRotationMode();
			nextRotationSwitch = floor(random(10, maxSwitchTime));
			rotationSwitchCounter = 0;
		}
		//console.log("next rotation switch: " + nextRotationSwitch);
	}

    // once every second, if no tiles are overlapping, shuffle the tiles so they will overlap differently 
    // (because they are drawn on top of each other in the order of the array index)
    if ((frameCount % 60 == 0) && (!areOverlapping)) {
        shuffleArrayRandomly(tiles);
    }

    // reset noise values for all tiles, only when there is no color (to mask the change), try this every 30 seconds
    if ((strokeBrightnessTarget == 0) && (fillBrightnessTarget == 0) && (frameCount % (60 * 30) == 0)) resetNoise();
}

// lerp value to target over time
function lerpOverTime(value, target) {
    //console.log(lerpCount);
    if (value != target && lerpCount < lerpTime) {
        lerpCount++;
        let amt = lerpCount/lerpTime;
        let lerped = lerp(value, target, amt)
        value = floor(lerped);

        //keep lerp from "hanging" at the last digits
        if (target > value) value += 1;
        else if (target < value) value -= 1;
    } else {
        lerpCount = 0;
        value = target;
    }
    return value;
}

// lerp color values to their targets
function computeLerping() {
    //console.log("bgColorTarget: " + bgColorTarget + "\n" + "fillAlphaTarget: " + fillAlphaTarget + "\n" +  "fillBrightnessTarget: " + fillBrightnessTarget + "\n" +  "strokeAlphaTarget: " + strokeAlphaTarget + "\n" +  "strokeBrightnessTarget: " + strokeBrightnessTarget);

    bgColor = lerpOverTime(bgColor, bgColorTarget);
    fillAlpha = lerpOverTime(fillAlpha, fillAlphaTarget);
    fillBrightness = lerpOverTime(fillBrightness, fillBrightnessTarget);
    strokeAlpha = lerpOverTime(strokeAlpha, strokeAlphaTarget);
    strokeBrightness = lerpOverTime(strokeBrightness, strokeBrightnessTarget);
}

// assign values depending on mode
function applyMode() {
    console.log("mode: " + mode);
    switch (mode) {
        case 1:
            bgColorTarget = 360;
            fillAlphaTarget = 0;
            fillBrightnessTarget = 0;
            strokeAlphaTarget = 100;
            strokeBrightnessTarget = 0;
        break;
        case 2:
            bgColorTarget = 360;
            fillAlphaTarget = 0;
            fillBrightnessTarget = 0;
            strokeAlphaTarget = 50;
            strokeBrightnessTarget = 0;
        break;
        case 3:
            bgColorTarget = 360;
            fillAlphaTarget = 50;
            fillBrightnessTarget = 0;
            strokeAlphaTarget = 0;
            strokeBrightnessTarget = 0;
        break;
        case 4:
            bgColorTarget = 360;
            fillAlphaTarget = 50;
            fillBrightnessTarget = 100;
            strokeAlphaTarget = 0;
            strokeBrightnessTarget = 0;
        break;
        case 5:
            bgColorTarget = 0;
            fillAlphaTarget = 0;
            fillBrightnessTarget = 0;
            strokeAlphaTarget = 100;
            strokeBrightnessTarget = 100;
        break;
        case 6:
            bgColorTarget = 0;
            fillAlphaTarget = 100;
            fillBrightnessTarget = 100;
            strokeAlphaTarget = 100;
            strokeBrightnessTarget = 0;
        break;
        case 7:
            bgColorTarget = 0;
            fillAlphaTarget = 100;
            fillBrightnessTarget = 100;
            strokeAlphaTarget = 0;
            strokeBrightnessTarget = 100;
        break;
        case 8:
            bgColorTarget = 0;
            fillAlphaTarget = 50;
            fillBrightnessTarget = 100;
            strokeAlphaTarget = 0;
            strokeBrightnessTarget = 100;
        break;
        case 9:
            bgColorTarget = 0;
            fillAlphaTarget = 0;
            fillBrightnessTarget = 100;
            strokeAlphaTarget = 50;
            strokeBrightnessTarget = 100;
        break;
        case 10:
            bgColorTarget = 0;
            fillAlphaTarget = 50;
            fillBrightnessTarget = 100;
            strokeAlphaTarget = 100;
            strokeBrightnessTarget = 0;
        break;
    }     
}

// go to next mode
function nextMode() {
    if (mode < 10) mode += 1;
    else mode = 1;

    applyMode();
}

// go to random mode
function randomMode() {
    mode = floor(random(1, 11));

    applyMode();
}

// switch between no rotation, global rotation and individual rotation
function applyRotationMode() {
    console.log("rotationMode: " + rotationMode);
    switch (rotationMode) {
        // none rotating
        case 1:
            areRotating = false;
            for (let i = 0; i < tiles.length; i++) {
                let b = tiles[i];
                b.isRotating = false;
            }
        break;
		// individual rotation
        case 2:
            areRotating = false;
            for (let i = 0; i < tiles.length; i++) {
                let b = tiles[i];
                b.isRotating = true;
            }
        break;
		// global rotation to the right
        case 3:
            areRotating = true;
            for (let i = 0; i < tiles.length; i++) {
                let b = tiles[i];
                b.isRotating = false;
                b.rotatingRight = true;
            }
        break;
		// global rotation to the left
        case 4:
            areRotating = true;
            for (let i = 0; i < tiles.length; i++) {
                let b = tiles[i];
                b.isRotating = false;
                b.rotatingRight = false;
            }
        break;
		// global rotation in opposite directions
        case 5:
            areRotating = true;
            for (let i = 0; i < tiles.length; i++) {
                let b = tiles[i];
                b.isRotating = false;
                if (random(2) < 1) b.rotatingRight = false;
                else b.rotatingRight = true;
            }
        break;
    }
}

// go to next rotation mode and apply
function nextRotationMode() {
    if (rotationMode < 5) rotationMode += 1;
    else rotationMode = 1;
    applyRotationMode();
}

// go to random rotation mode and apply
function randomRotationMode() {
    rotationMode = floor(random(1, 6));
    applyRotationMode();
}

// check if shapes have settled after morphing
function areShapesSettled() {
    // check if most tiles have their morph vertices close to their target vertices
    let settledCount = 0;
    let threshold = 0.1; // minimum distance threshold for considering vertices "settled"
    
    for (let i = 0; i < min(tiles.length, 20); i++) { // sample first 20 tiles for performance
        let tile = tiles[i];
        let settled = true;
        
        for (let j = 0; j < min(tile.morph.length, 10); j++) { // sample 10 vertices per tile
            let target = tile.state == 0 ? tile.circle[j] : tile.rect[j];
            let current = tile.morph[j];
            let distance = p5.Vector.dist(current, target);
            
            if (distance > threshold) {
                settled = false;
                break;
            }
        }
        
        if (settled) settledCount++;
    }
    
    return settledCount > 15; // at least 15 out of 20 sampled tiles should be settled
}

// switch between no tiles changing shape, some tiles changing shape, and all tiles changing shapes
function applyBlobMode() {
	console.log("blobMode: " + blobMode);
	
	switch (blobMode) {
		case 1:
			// none changing shape with noise
			areBlobbing = false;
            for (let i = 0; i < tiles.length; i++) {
                let b = tiles[i];
                b.isBlobbing = false;
            }
        break;
        case 2:
			// some changing shape with noise
			areBlobbing = true;
			for (let i = 0; i < tiles.length; i++) {
				let b = tiles[i];
				let rand = floor(random(2));
				if (rand < 1) b.isBlobbing = false;
				else b.isBlobbing = true;
			}
        break;
        case 3:
			// all changing shape with noise
			areBlobbing = true;
			for (let i = 0; i < tiles.length; i++) {
				let b = tiles[i];
				b.isBlobbing = true;
			}
        break;
    }
}

// go to random shape mode and apply
function nextBlobMode() {
	if (blobMode < 3) blobMode += 1;
	else blobMode = 1;
	applyBlobMode();
}

// go to next noiseShaping mode and apply
function randomBlobMode() {
	if (blobMode != 1) blobMode = 1;	// no blobs for half the time
	else blobMode = floor(random(1, 4));
	applyBlobMode();
}

// check key presses
function keyPressed() {
    // circles
    if (key == "1") {
		console.log("circles");
        for (let i = 0; i < tiles.length; i++) {
            let b = tiles[i];
            b.state = 0;
        }
    }

    // squares    
    if (key == "2") {
		console.log("squares");
        for (let i = 0; i < tiles.length; i++) {
            let b = tiles[i];
            b.state = 1;
        }
    }

    // cycle through modes (q key)
    if (keyCode == 81) {
        nextMode();
    }

    // random mode (w key)
    if (keyCode == 87) {
        randomMode();
    }

    // cycle through rotation modes (e key)
    if (keyCode == 69) {
        nextRotationMode();
    }

    // random rotation mode (r key)
    if (keyCode == 82) {
        randomRotationMode();
    }

    // cycle through shaping modes (t key)
    if (keyCode == 84) {
        nextBlobMode();
    }

    // random shaping mode (z key)
    if (keyCode == 90) {
        randomBlobMode();
    }

    // reset noise (n key)
    if (keyCode == 78) {
        resetNoise();
    }

    // order array by ascending index (a key)
    if (keyCode == 65) {
        orderArrayByAscendingIndex(tiles);
    }

    // shuffle array randomly (s key)
    if (keyCode == 83) {
        shuffleArrayRandomly(tiles);
    }

    // draw FPS (g key)
    if (keyCode == 71) {
        debug = !debug;
    }

	// easy fullscreen (f key)
	if (keyCode == 70) {
		let fs = fullscreen();
		fullscreen(!fs);
	}

	// screenshot (p key)
	if (keyCode == 80) {
		saveCanvas('untiled_screenshot_' + limitedWidth + "x" + limitedHeight + "_" + frameCount, 'png');
	}
}

// render how many FPS the sketch is running at
function showDebug() {
    fill(255);
    noStroke();
    rect(30, 5, 60, 30);

    fill(0, 100, 100);
    textSize(20);
    text("fps: " + floor(frameRate()), 0, 10);
}

// reset noise time value for all tiles
function resetNoise() {
    console.log("noise reset");
    
    for(let i = 0; i < tiles.length; i++) {
        let b = tiles[i];
        b.hT = 0;
        b.sT = 0;
    }
}

// randomize array in-place using Durstenfeld shuffle algorithm
function shuffleArrayRandomly(array) {
    console.log("array shuffled");

    for (let i = array.length - 1; i > 0; i--) {
        let j = Math.floor(Math.random() * (i + 1));
        let temp = array[i];
        array[i] = array[j];
        array[j] = temp;
    }
}

// order array by index in ascending order (unused)
function orderArrayByAscendingIndex(array) {
    console.log("array ordered by ascending index");
    
    let temp = [];

    for (let i = 0; i < array.length; i++) {
        let b = array[i];
        temp[b.index] = b;
    }

    for (let i = 0; i < temp.length; i++) {
        array[i] = temp[i];
    }
}

// individual tile
class Tile {

    constructor(size, xPos, yPos, index) {
        
        // position
        this.index = index;
        this.pos = createVector(xPos, yPos);

        // size & scale
        this.size = size;
        this.scale = 1;
        this.scaleT = 0;
		this.lerpedScale = 0;

		// noise shape
		this.xT = Math.random() * 100; // use JS native random function for performance
		this.yT = Math.random() * 100; // use JS native random function for performance
		this.isBlobbing = false;

        // rotation
        this.rotation = 0;
        this.roT = 0;
        this.isRotating = false;
        
        // color
        this.fillCol;
        this.strokeCol;
        this.hue;
        this.sat;
        this.bri;
        this.hT = 0;
        this.sT = 0;

        // shape morphing
        this.circle = [];
        this.rect = [];
        this.morph = [];
        this.state = 1;

        this.initShapes();
    }

    // draw single tile
    draw() {
        // do calculations
        this.compute();

        // set fill and stroke
        fill(this.fillCol);
        strokeWeight(strokeW);
        stroke(this.strokeCol);

        // draw shape
        push();
            translate(this.pos.x, this.pos.y);
            scale(this.lerpedScale);
            rotate(this.rotation);
            this.drawShape();
        pop();
    }

    compute() {
        // color
        this.hT += Math.random() * (.005 - .0005) + .0005; // use JS native random function for performance
        this.sT += Math.random() * (.005 - .0005) + .0005; // use JS native random function for performance
        this.hue = map(noise(this.hT), 0, 1, -60, 160);
        this.sat = map(noise(this.sT), 0, 1, 10, 100);

        // apply
        this.fillCol = color(this.hue, this.sat, fillBrightness, fillAlpha);
        this.strokeCol = color(this.hue, this.sat, strokeBrightness, strokeAlpha);

        // scale with smoother blob transition
        this.scaleT += Math.random() * .005; // use JS native random function for performance
        let targetMinScale = this.isBlobbing ? 0.7 : 0.3;
        let targetMaxScale = this.isBlobbing ? 3 : 2.5;
        
        // lerp the scale ranges themselves to avoid sudden jumps when blob state changes
        if (!this.minScale) this.minScale = 0.3;
        if (!this.maxScale) this.maxScale = 2.5;
        
        this.minScale = lerp(this.minScale, targetMinScale, 0.02);
        this.maxScale = lerp(this.maxScale, targetMaxScale, 0.02);
        
        this.scale = map(noise(this.scaleT), 0, 1, this.minScale, this.maxScale);
		this.lerpedScale = lerp(this.lerpedScale, this.scale, 0.05);	// lerp to scale to mask transition

        // rotation
        this.roT += Math.random() * .008; // use JS native random function for performance
        if (this.isRotating) this.rotation = map(noise(this.roT), 0, 1, 0, 10);
        else if (areRotating && this.rotatingRight) this.rotation = globalRotation;
        else if (areRotating && !this.rotatingRight) this.rotation = -globalRotation;
        else this.rotation = 0;

		// inc blobbing noise
		this.xT += map(noise(this.yT), 0, 1, 0, .1);
		this.yT += .001;
    }

    // initialize the (two) possible shapes with vertices
    initShapes() {
        // create a circle using vectors pointing from center
        for (let angle = 0; angle < 360; angle += 9) {
            // note we are not starting from 0 in order to match the
            // path of a circle.
            let v = p5.Vector.fromAngle(radians(angle - 135));
            v.mult(this.size/2);
            this.circle.push(v);
            // let's fill out morph ArrayList with blank PVectors while we are at it
            this.morph.push(createVector());
        }

        // a rect is a bunch of vertices along straight lines
        // create exactly 40 vertices to match circle
        for (let i = 0; i < 40; i++) {
            let progress = i / 40; // 0 to 1 around the perimeter
            let x, y;
            
            if (progress < 0.25) {
                // top side
                let t = progress * 4;
                x = lerp(-this.size/2, this.size/2, t);
                y = -this.size/2;
            } else if (progress < 0.5) {
                // right side
                let t = (progress - 0.25) * 4;
                x = this.size/2;
                y = lerp(-this.size/2, this.size/2, t);
            } else if (progress < 0.75) {
                // bottom side
                let t = (progress - 0.5) * 4;
                x = lerp(this.size/2, -this.size/2, t);
                y = this.size/2;
            } else {
                // left side
                let t = (progress - 0.75) * 4;
                x = -this.size/2;
                y = lerp(this.size/2, -this.size/2, t);
            }
            
            this.rect.push(createVector(x, y));
        }

		//console.log(this.rect.length + " " + this.circle.length);
    }

    drawShape() {
        // look at each vertex
        for (let i = 0; i < this.circle.length; i++) {
            let v1;
            // are we lerping to the circle or the rect?
            if (this.state == 0) {
                v1 = this.circle[i];
            } else if (this.state == 1) {
                v1 = this.rect[i];
            }
            // get the vertex we will draw
            let v2 = this.morph[i];
			// apply blobbing or not
			if (this.isBlobbing) {
				let offsetRadius = map(noise(this.xT + i * 0.1), 0, 1, -this.size * 0.005, this.size * 0.005);
				let x = offsetRadius * cos(i);
				let y = offsetRadius * sin(i);
				v2.x += x;
				v2.y += y;
			}
            // lerp to the target with adaptive speed based on distance
            let distance = p5.Vector.dist(v2, v1);
            let adaptiveLerpSpeed = map(distance, 0, this.size/2, 0.08, 0.03); // faster when far, slower when close
            adaptiveLerpSpeed = constrain(adaptiveLerpSpeed, 0.02, 0.1);
            v2.lerp(v1, adaptiveLerpSpeed);
        }

		// draw a polygon that makes up all the vertices
		beginShape();
			this.morph.forEach(v => {
				vertex(v.x, v.y);
			});
		endShape(CLOSE);
		
		// debug: draw red circles at each vertex
		// push();
		// fill(255, 100, 100);
		// noStroke();
		// this.morph.forEach(v => {
		// 	circle(v.x, v.y, 3);
		// });
		// pop();
    }
}