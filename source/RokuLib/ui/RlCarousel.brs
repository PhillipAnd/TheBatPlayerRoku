'Represents a simple 2D image carousel. Uses background shadow images for loading purposes.
'@param images an array of image file paths
'@param bigShadow a dictionary specifying parameters of the big shadow to be used. Example: {path: "pkg:/shadow.png", offsetX: 10, offsetY: 10, width: 100, height: 100}
'@param smallShadow a dictionary specifying parameters of the small shadow to be used. Example: {path: "pkg:/shadow.png", offsetX: 10, offsetY: 10, width: 100, height: 100}
'@param x the x coordinate of the main image
'@param y the y coordinate of the main image
'@param VISIBLE_IMAGES an Integer array containing two values, which respectively specify the number of images on the left and right of the main image. Default is [4, 4]
function RlCarousel(images as Object, bigShadow as Object, smallShadow as Object, x as Integer, y as Integer, VISIBLE_IMAGES = [4, 4] as Object, ANIMATION_TIME = 0.25 as Float, animate = true as Boolean) as Object
    this = {
        bigShadow: bigShadow
        smallShadow: smallShadow
        images: images
        x: x
        y: y
        animate: animate
        
        bitmapManager: m.bitmapManager
        
        visibleImages: []
        visibleShadows: []
        moving: false
        reversed: false
        advance: false
        firstTime: true
        direction: 0
        index: 0
        
        'Constants
        DEFAULT_ANIMATION_TIME: ANIMATION_TIME
        ANIMATION_TIME: ANIMATION_TIME 'If animate is set to true, this is the animation time. Otherwise, this is the time to wait between moves.
        VISIBLE_IMAGES: VISIBLE_IMAGES
        
        Init: RlCarousel_Init
        Move: RlCarousel_Move
        Draw: RlCarousel_Draw
        Update: RlCarousel_Update
        UpdateImages: RlCarousel_UpdateImages
        SetIndex: RlCarousel_SetIndex
    }
    
    this.Init()
    
    
    return this
end function

function RlCarousel_Init() as Void
    smallWidth = m.smallShadow.width
    smallHeight = m.smallShadow.height
    bigOffsetX = m.bigShadow.offsetX
    bigWidth = m.bigShadow.width
    bigHeight = m.bigShadow.height
    
    actualX = m.x - bigOffsetX 'Since the main shadow has an offset shadow border
    
    'Positions to tell when to wrap, how to scale etc
    m.wrapLeftX = actualX - m.VISIBLE_IMAGES[0] * smallWidth
    m.wrapRightX = actualX + bigWidth + m.VISIBLE_IMAGES[1] * smallWidth 
    m.centerX = actualX
    m.leftX = actualX - smallWidth
    m.rightX = actualX + bigWidth

    m.SetIndex(0)
end function

'Instantly sets the carousel to the specified index
function RlCarousel_SetIndex(index as Integer) as Void
	m.visibleImages = []
	m.visibleShadows = []
	m.index = index
	m.moving = false
	m.direction = 0
	m.reversed = false
	count = m.images.Count()
	if count = 0 then return

    'Small shadow constants
    smallPath = m.smallShadow.path
    smallOffsetX = m.smallShadow.offsetX
    smallOffsetY = m.smallShadow.offsetY
    smallWidth = m.smallShadow.width
    smallHeight = m.smallShadow.height
    
    'Big shadow constants
    bigPath = m.bigShadow.path
    bigOffsetX = m.bigShadow.offsetX
    bigOffsetY = m.bigShadow.offsetY
    bigWidth = m.bigShadow.width
    bigHeight = m.bigShadow.height
    
    total = m.VISIBLE_IMAGES[0] + m.VISIBLE_IMAGES[1]
    
    actualX = m.x - bigOffsetX 'Since the main shadow has an offset shadow border
    'Shadows to left of big shadow
    for i = 1 to m.VISIBLE_IMAGES[0]
    	if index - i < 0 then exit for 'Out of bounds to the left
        shadow = RlImage(smallPath, actualX - i * smallWidth, m.y + (bigHeight - smallHeight) / 2, smallWidth, smallHeight)
        shadow.moveLeft = 0
        shadow.moveCurrent = 0
        shadow.moveTotal = 0
        shadow.movePer = 100
        shadow.index = index - i
        shadow.offsetX = smallOffsetX
        shadow.offsetY = smallOffsetY
        m.visibleShadows.Unshift(shadow)
        m.visibleImages.Unshift(invalid)
    end for
    
    left = i - 1
    
	'Set big shadow
    bigShadow = RlImage(bigPath, actualX, m.y, bigWidth, bigHeight)
    bigShadow.moveLeft = 0
    bigShadow.moveCurrent = 0
    bigShadow.moveTotal = 0
    bigShadow.movePer = 100
    bigShadow.index = index
    bigShadow.offsetX = bigOffsetX
    bigShadow.offsetY = bigOffsetY
    m.visibleShadows.Push(bigShadow)
    m.visibleImages.Push(invalid)
    
    'Shadows to right of big shadow
    for i = 1 to m.VISIBLE_IMAGES[1]
    	if index + i > count - 1 then exit for 'Out of bounds to the right
        shadow = RlImage(smallPath, actualX + bigWidth + (i - 1) * smallWidth, m.y + (bigHeight - smallHeight) / 2, smallWidth, smallHeight)
        shadow.moveLeft = 0
        shadow.moveCurrent = 0
        shadow.moveTotal = 0
        shadow.movePer = 100
        shadow.index = index + i
        shadow.offsetX = smallOffsetX
        shadow.offsetY = smallOffsetY
        m.visibleShadows.Push(shadow)
        m.visibleImages.Push(invalid)
    end for
    
    right = i - 1
    
    if count + 1 < left + right then return 'Fewer items than visible shadows
    
    'Fill in leftover shadows
    if right = m.VISIBLE_IMAGES[1] 'Keep adding to the right leftover images
    	for i = m.VISIBLE_IMAGES[1] + 1 to total - left
	    	if index + i > count - 1 then exit for 'Out of bounds to the right
	        shadow = RlImage(smallPath, actualX + bigWidth + (i - 1) * smallWidth, m.y + (bigHeight - smallHeight) / 2, smallWidth, smallHeight)
	        shadow.moveLeft = 0
	        shadow.moveCurrent = 0
	        shadow.moveTotal = 0
	        shadow.movePer = 100
	        shadow.index = index + i
	        shadow.offsetX = smallOffsetX
	        shadow.offsetY = smallOffsetY
	        m.visibleShadows.Push(shadow)
	        m.visibleImages.Push(invalid)
    	end for
	else if left = m.VISIBLE_IMAGES[0] 'Keep adding to the left any leftover images
    	for i = m.VISIBLE_IMAGES[0] + 1 to total - right
	    	if index - i < 0 then exit for 'Out of bounds to the left
	        shadow = RlImage(smallPath, actualX - i * smallWidth, m.y + (bigHeight - smallHeight) / 2, smallWidth, smallHeight)
	        shadow.moveLeft = 0
	        shadow.moveCurrent = 0
	        shadow.moveTotal = 0
	        shadow.movePer = 100
	        shadow.index = index - i
	        shadow.offsetX = smallOffsetX
	        shadow.offsetY = smallOffsetY
	        m.visibleShadows.Unshift(shadow)
	        m.visibleImages.Unshift(invalid)
    	end for
    end if
end function

'Set this carousel to start moving to the next item (right) or previous item (left).
'@param direction the direction to move in. 1 for right and -1 for left.
function RlCarousel_Move(direction as Integer) as Void
	if not m.animate
		m.SetIndex(m.index + direction)
		return
	end if
	
    'Small shadow constants
    smallPath = m.smallShadow.path
    smallOffsetX = m.smallShadow.offsetX
    smallOffsetY = m.smallShadow.offsetY
    smallWidth = m.smallShadow.width
    smallHeight = m.smallShadow.height
    
    'Big shadow constants
    bigPath = m.bigShadow.path
    bigOffsetX = m.bigShadow.offsetX
    bigOffsetY = m.bigShadow.offsetY
    bigWidth = m.bigShadow.width
    bigHeight = m.bigShadow.height
    actualX = m.x - bigOffsetX 'Since the main shadow has an offset shadow border
    
    if direction <> 0
        'Calculate move amounts
        
        max = m.visibleShadows.Count() - 1
        for i = 0 to max
            shadow = m.visibleShadows[i]
            if m.direction <> 0 and direction <> m.direction 'Animation reversed direction
                shadow.moveLeft = shadow.moveCurrent 'Reverse movement to the nearest previous item
                shadow.moveCurrent = RlModulo(shadow.moveLeft, shadow.movePer)
                shadow.moveTotal = shadow.movePer 'Total move amount treated like it's moving one complete unit
                m.reversed = not m.reversed
            else if not m.moving' Continuing in same direction, or new direction
            	m.reversed = false
                if shadow.index = m.index 'Shadow is the big shadow
                    if direction < 0
                        shadow.moveTotal = bigWidth
                    else if direction > 0
                        shadow.moveTotal = smallWidth
                    end if
                else 'Shadow is the small shadow
                    if shadow.index = m.index + 1 and direction > 0 'To the right of the big shadow and moving left
                        shadow.moveTotal = bigWidth
                    else if shadow.index = m.index - 1 and direction < 0 'To the left of the big shadow and moving right
                        shadow.moveTotal = smallWidth
                    else 'All other shadows move the small width, and do not scale
                        shadow.moveTotal = smallWidth
                    end if
                end if

                if m.direction = 0 'Starting from 0
                    shadow.movePer = shadow.moveTotal
                    shadow.moveCurrent = 0
                    shadow.moveLeft = shadow.moveTotal
                else if direction = m.direction 'Adding to current direction
                    shadow.movePer = shadow.moveTotal 'Left/right movement of 1 unit
                    shadow.moveTotal = shadow.moveLeft + shadow.moveTotal
                    shadow.moveLeft = shadow.moveTotal
                end if
            end if
        end for

		m.advance = true
        m.moving = true
        m.direction = direction
    end if
    
end function

'Update the carousel, independent of frame rate (since Roku 1/2/3 devices have different performances)
'@param delta the change in time value
'@return true if updated
function RlCarousel_Update(delta as Float) as Boolean

    updated = false
    max = m.visibleShadows.Count() - 1
    if m.moving
        'Move each shadow if animation time is nonzero
        for i = 0 to max
            shadow = m.visibleShadows[i] 
            if shadow.moveLeft > 0
                if m.ANIMATION_TIME >= 0.05
                    moveAmount = int(- m.direction * delta * (shadow.moveTotal / m.ANIMATION_TIME))
                    if abs(moveAmount) > shadow.moveLeft then moveAmount = - m.direction * shadow.moveLeft 'moveAmount greater than moveLeft, clamp it
                else
                    moveAmount = - int(m.direction * shadow.moveTotal)
                end if
                         
                shadow.x = shadow.x + moveAmount
                shadow.moveCurrent = shadow.moveCurrent + abs(moveAmount)                           
                shadow.moveLeft = shadow.moveLeft - abs(moveAmount)
                
                m.moving = true
            else
                m.moving = false
            end if
        end for

	    'Scale the shadows appropriately as they pass through the center scaling point
	    for i = 0 to max
	    	shadow = m.visibleShadows[i]
	    	
	    	
	    	if shadow.x >= m.leftX and shadow.x <= m.centerX 'Scaling between center poster and poster directly to its left
	    		scale = (shadow.x - m.leftX) / (m.centerX - m.leftX)
	    		shadow.width = int(m.smallShadow.width + scale * (m.bigShadow.width - m.smallShadow.width))
	    		shadow.height = int(m.smallShadow.height + scale * (m.bigShadow.height - m.smallShadow.height))
	    		shadow.y = m.y + int((m.bigShadow.height - shadow.height) / 2)
	    		shadow.offsetX = int(m.smallShadow.offsetX + scale * (m.bigShadow.offsetX - m.smallShadow.offsetX))
	    		shadow.offsetY = int(m.smallShadow.offsetY + scale * (m.bigShadow.offsetY - m.smallShadow.offsetY))
	    	else if shadow.x >= m.centerX and shadow.x <= m.rightX
	    		scale = (m.rightX - shadow.x) / (m.rightX - m.centerX) 'Scaling down to small shadow
	    		shadow.width = int(m.smallShadow.width + scale * (m.bigShadow.width - m.smallShadow.width))
	    		shadow.height = int(m.smallShadow.height + scale * (m.bigShadow.height - m.smallShadow.height))
	    		shadow.y = m.y + int((m.bigShadow.height - shadow.height) / 2)
	    		shadow.offsetX = int(m.smallShadow.offsetX + scale * (m.bigShadow.offsetX - m.smallShadow.offsetX))
	    		shadow.offsetY = int(m.smallShadow.offsetY + scale * (m.bigShadow.offsetY - m.smallShadow.offsetY))
	    	end if
	    end for
	    
	    'Wrap around         
        if m.direction > 0
		    temp = m.visibleShadows[0]
		    if temp.x < m.wrapLeftX and m.visibleShadows[max].index < m.images.Count() - 1 'Left wraparound
		        temp.x = m.visibleShadows[max].x + m.visibleShadows[max].width 'Move it to the position after the rightmost shadow
		        temp.index = m.visibleShadows[max].index + 1
		        for i = 0 to max - 1
		            m.visibleShadows[i] = m.visibleShadows[i + 1]
		        end for
		        m.visibleShadows[max] = temp
		        temp = m.visibleShadows[0]
		    end if
	    else if m.direction < 0   
		    temp = m.visibleShadows[max]
		    while temp.x > m.wrapRightX and m.visibleShadows[0].index > 0 'Right wraparound
		        temp.x = m.visibleShadows[0].x - temp.width 'Move it to the position before the leftmost shadow
		        temp.index = m.visibleShadows[0].index - 1
		        for i = max to 1 step -1
		            m.visibleShadows[i] = m.visibleShadows[i - 1]
		        end for
		        m.visibleShadows[0] = temp
		        temp = m.visibleShadows[max]
		    end while
	    end if
	    
        updated = true    
    else    
    	m.direction = 0
        m.reversed = false
    end if

    for i = 0 to max
    	shadow = m.visibleShadows[i]
        if shadow.moveCurrent >= shadow.movePer and not m.reversed 'I.e. moved past a single unit
            shadow.moveCurrent = RlModulo(shadow.moveCurrent, shadow.movePer) 'Reset the position past a single unit to 0
            
            'Update carousel index and clamp
            if i = 0
	            m.index = m.index + m.direction
	            imageMax = m.images.Count() - 1
	            if m.index < 0
	            	m.index = 0
	            else if m.index > imageMax 
	            	m.index = imageMax
	            end if
	            m.advance = false
            end if
        end if
    end for

    if m.UpdateImages()
    	updated = true
    end if

    return updated
end function

'Draws this RlCarousel to the specified component.
'@param component a roScreen/roBitmap/roRegion object
'@return true if successful
function RlCarousel_Draw(component as Object) as Boolean
    if not RlDrawAll(m.visibleShadows, component) then return false
    if not RlDrawAll(m.visibleImages, component, 250) then return false
    return true
end function

'Set the images to be shown on the visible shadows
function RlCarousel_UpdateImages() as Boolean
	fs = CreateObject("roFileSystem")
    max = m.visibleShadows.Count() - 1 
    updated = false
    
    for i = 0 to max
        shadow = m.visibleShadows[i] 'Get the shadow to overlay the image on
        visibleImage = m.visibleImages[i]
        if visibleImage = invalid then updated = true
        
        image = invalid
        path = m.images[shadow.index]
        if m.ANIMATION_TIME > 0.1 and fs.exists(path)
            x = shadow.x + shadow.offsetX
            y = shadow.y + shadow.offsetY
            width = shadow.width - 2 * shadow.offsetX
            height = shadow.height - 2 * shadow.offsetY
            image = RlImage(path, x, y, width, height, not m.moving) 'Build an image from the path corresponding to the shadow's index if it exists
		end if

        'Add the image to to the visible images
        m.visibleImages[i] = image
    end for

    return updated
end function