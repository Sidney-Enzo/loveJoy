--yeah i know use this math, what you gonna do about it?
local function collision_pointRectangle(_point, _rectangle)
    return _point.x <= _rectangle.x + _rectangle.w and
    _point.y <= _rectangle.y + _rectangle.h and 
    _point.x >= _rectangle.x and 
    _point.y >= _rectangle.y
end

local function math_normalize(_x, _y)
    local _lenght = (_x*_x + _y*_y)^0.5
    
    if _lenght == 0 then 
        return 0, 0, 0
    elseif _lenght == 1 then
        return _x, _y, 1
    end
    
    return _x/_lenght, _y/_lenght, _lenght 
end

local function math_dist2(_x1, _y1, _x2, _y2)
    return ((_x2 - _x1)*(_x2 - _x1) + (_y2 - _y1)*(_y2 - _y1))^0.5
end

local joystick = {}
joystick.__index = joystick

local function _new(_x, _y, _radius, _fallowClick, _fallowFinger, _onlyNormal)
    _radius = _radius or 64

    local newJoystick = setmetatable({}, joystick)
    newJoystick.x = _x
    newJoystick.y = _y
    newJoystick.radius = _radius

    newJoystick.original = {}
    newJoystick.original.x = _x
    newJoystick.original.y = _y

    newJoystick.activeArea = {}
    newJoystick.activeArea.x = 0
    newJoystick.activeArea.y = 0
    newJoystick.activeArea.w = love.graphics.getWidth()
    newJoystick.activeArea.h = love.graphics.getHeight()

    newJoystick.onlyNormal = _onlyNormal or false
    newJoystick.fallowFinger = _fallowFinger or true
    newJoystick.fallowClick = _fallowClick or true

    newJoystick.pressed = false
    newJoystick.hovered = false

    newJoystick.paddler = {}
    newJoystick.paddler.x = _x
    newJoystick.paddler.y = _y
    newJoystick.paddler.radius = _radius/2

    newJoystick.normalized = {}
    newJoystick.normalized.x = 0
    newJoystick.normalized.y = 0
    
    return newJoystick
end

function joystick:draw()
    local currentRendererColor = {love.graphics.getColor()}
    --scrolling area
    love.graphics.setColor(currentRendererColor[1], currentRendererColor[2], currentRendererColor[3], currentRendererColor[4]/2)
    love.graphics.circle("line", self.x, self.y, self.radius)
    love.graphics.setColor(currentRendererColor[1], currentRendererColor[2], currentRendererColor[3], currentRendererColor[4]/4)
    love.graphics.circle("fill", self.x, self.y, self.radius)
    love.graphics.setColor(currentRendererColor)
    love.graphics.circle("fill", self.paddler.x, self.paddler.y, self.paddler.radius)
end

function joystick:update(deltaTime)
    local touches = love.touch.getTouches()
    if #touches == 0 then
        self.hovered = false
    end

    for t = 1, #touches, 1 do
        local touchX, touchY = love.touch.getPosition(touches[t])
        if collision_pointRectangle({x = touchX, y = touchY}, self.activeArea) then
            self.pressed = not self.hovered 
            self.hovered = true

            if self.pressed and self.fallowClick then
                self.x, self.y = touchX, touchY
            end
            self.normalized.x, self.normalized.y = math_normalize(touchX - self.x, touchY - self.y)

            if math_dist2(self.x, self.y, touchX, touchY) < self.radius then
                if not self.onlyNormal then
                    self.normalized.x = self.normalized.x*math.abs((touchX - self.x)/self.radius)
                    self.normalized.y = self.normalized.y*math.abs((touchY - self.y)/self.radius)
                end

                self.paddler.x = touchX
                self.paddler.y = touchY
            else
                self.paddler.x = self.x + self.normalized.x*self.radius
                self.paddler.y = self.y + self.normalized.y*self.radius

                if self.fallowFinger then
                    self.x = self.x + (touchX - self.x)*0.025
                    self.y = self.y + (touchY - self.y)*0.025
                end
            end
            break --will stop to read touches when found the first touch on joystick
        end
    end

    if not self.hovered then
        self.normalized.x, self.normalized.y = 0, 0
        self.x, self.y = self.original.x, self.original.y
        self.paddler.x, self.paddler.y = self.x, self.y
    end

    return self.normalized.x, self.normalized.y
end

function joystick:setJoystickArea(_x, _y, _w, _h)
    self.actveArea = {}
    self.actveArea.x, self.actveArea.y, self.actveArea.w, self.actveArea.h = _x, _y, _w, _h
end

function joystick:setOnlyNormal(_onlyNormal)
    self.onlyNormal = _onlyNormal
end

function joystick:setFallowClick(_fallowClick)
    self.fallowClick = _fallowClick
end

function joystick:setFallowFinger(_fallowFinger)
    self.fallowFinger = _fallowFinger
end

function joystick:setPosition(_x, _y)
    self.original.x, self.original.y = _x, _y
end

function joystick:setRadius(_radius)
    self.radius = _radius
    self.paddler.radius = _radius/2
end

function joystick:getNormalize()
    return self.normalized.x, self.normalized.y
end

function joystick:isPressed()
    return self.pressed
end

function joystick:isHover()
    return self.hovered
end

return setmetatable({
--external api
    draw = joystick.draw,
    update = joystick.update,
--set
    setOnlyNormal = joystick.setOnlyNormal,
    setFallowClick = joystick.setFallowClick,
    setFallowFinger = joystick.setFallowFinger,
    setJoystickArea = joystick.setJoystickArea,
    setPosition = joystick.setPosition,
    setRadius = joystick.setRadius,
--get
    getNormalize = joystick.getNormalize,
    pressed = isPressed,
    hovered = isHover,
}, {
    __call = function(_, ...)
        return _new(...)
    end
})