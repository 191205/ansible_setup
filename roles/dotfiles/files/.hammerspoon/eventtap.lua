--
-- Trying to limp along without Karabiner in Sierra.
--

local deepEquals = require 'deepEquals'
local log = require 'log'

local keyDown = hs.eventtap.event.types.keyDown
local keyUp = hs.eventtap.event.types.keyUp

local controlKeyCode = 59 -- For some reason this one not in hs.keycodes.map.
local controlDown = {ctrl = true}
local controlUp = {}
local controlPressed = nil
local repeatDelay = hs.eventtap.keyRepeatDelay()
local repeatInterval = hs.eventtap.keyRepeatInterval()
local controlTimer = nil
local controlRepeatTimer = nil

local function modifierHandler(evt)
  local flags=evt:getFlags()
  local keyCode = evt:getKeyCode()

  -- Going to fire a fake f7 key-press so that we can handle this in the
  -- keyHandler function along with Return.
  if keyCode == controlKeyCode then
    -- We only start timers when Control is pressed alone, but we clean them up
    -- unconditionally when it is released, so as not to leak.
    if flags['ctrl'] == nil and controlPressed == true then
      controlPressed = false
      hs.eventtap.event.newKeyEvent({}, 'f7', false):post()
      if controlTimer ~= nil then
        controlTimer:stop()
      end
      if controlRepeatTimer ~= nil then
        controlRepeatTimer:stop()
      end
    elseif deepEquals(flags, controlDown) then
      controlPressed = true
      hs.eventtap.event.newKeyEvent({}, 'f7', true):post()

      -- We don't get repeat events for modifiers. Have to fake them.
      controlTimer = hs.timer.doAfter(
        repeatDelay,
        (function()
          if controlPressed then
            controlRepeatTimer = hs.timer.doUntil(
              (function() return controlPressed == false end),
              (function()
                hs.eventtap.event.newKeyEvent({}, 'f7', true):post()
              end),
              repeatInterval
            )
          end
        end)
      )
    end
  end
end

local repeatThreshold = .5
local syntheticEvent = 94025 -- magic number chosen "at random"
local eventSourceUserData = hs.eventtap.event.properties['eventSourceUserData']
local keyboardEventKeyboardType = hs.eventtap.event.properties['keyboardEventKeyboardType']
local internalKeyboardType = 43
local externalKeyboardType = 40 -- YubiKey as well...

-- These are keys that do one thing when tapped but act like modifiers when
-- chorded.
local conditionalKeys = {
  f7 = {
    tapped = 'delete',
    chorded = 'ctrl',
    downAt = nil,
    isChording = false,
    expectedFlags = {fn = true},
  },
}
-- "return" is a reserved word, so have to use longhand:
conditionalKeys['return'] = {
  tapped = 'return',
  chorded = 'ctrl',
  downAt = nil,
  isChording = false,
  expectedFlags = {},
}

local function keyHandler(evt)
  local userData = evt:getProperty(eventSourceUserData)
  if userData == syntheticEvent then
    return
  end
  local eventType = evt:getType()
  local keyboardType = evt:getProperty(keyboardEventKeyboardType)
  local keyCode = evt:getKeyCode()
  local flags = evt:getFlags()
  local when = hs.timer.secondsSinceEpoch()
  if eventType == keyDown then
    if keyCode == hs.keycodes.map['i'] then
      if deepEquals(flags, {ctrl = true}) then
        local frontmost = hs.application.frontmostApplication():bundleID()
        if frontmost == 'com.googlecode.iterm2' or frontmost == 'org.vim.MacVim' then
          hs.eventtap.event.newKeyEvent({}, 'f6', true):setProperty(eventSourceUserData, syntheticEvent):post()
          return true
        end
      end
    end

    -- Check for conditional keys.
    -- Along the way, note which conditional key(s) are already down.
    local activeConditionals = {}
    for keyName, config in pairs(conditionalKeys) do
      if keyCode == hs.keycodes.map[keyName] then
        if not deepEquals(flags, config.expectedFlags) then
          local synthetic = hs.eventtap.event.newKeyEvent({}, config.tapped, true)
          synthetic:setProperty(eventSourceUserData, syntheticEvent)
          synthetic:post()
          return true
        elseif not config.downAt then
          config.downAt = when
          return true -- Suppress initial event.
        elseif when - config.downAt > repeatThreshold then
          local synthetic = hs.eventtap.event.newKeyEvent({}, config.tapped, true)
          synthetic:setProperty(eventSourceUserData, syntheticEvent)
          synthetic:post()
          return true -- Let the event through.
        else
          return true -- Suppress until we hit the threshold.
        end
      elseif config.downAt then
        activeConditionals[keyName] = config
      end
    end

    -- Potentially begin chording against the active conditionals.
    for keyName, config in pairs(activeConditionals) do
      if config.isChording or when - config.downAt < repeatThreshold then
        if deepEquals(flags, config.expectedFlags) then
          config.isChording = true
          local synthetic = evt:copy()
          local syntheticFlags = {}
          syntheticFlags[config.chorded] = true
          synthetic:setFlags(syntheticFlags)
          synthetic:setProperty(eventSourceUserData, syntheticEvent)
          synthetic:post()
          return true -- Suppress the event.
        end
      end
    end
  elseif eventType == keyUp then
    for keyName, config in pairs(conditionalKeys) do
      if keyCode == hs.keycodes.map[keyName] then
        if config.isChording then
          config.isChording = false
          return true
        end

        local downAt = config.downAt
        config.downAt = nil
        if deepEquals(flags, config.expectedFlags) and
          when - downAt <= repeatThreshold then
          local synthetic = hs.eventtap.event.newKeyEvent({}, config.tapped, true)
          synthetic:setProperty(eventSourceUserData, syntheticEvent)
          synthetic:post()
          return false
        else
          return true
        end
      end
    end
  end
end

return {
  init = (function()
    local modifierTap = hs.eventtap.new(
      {hs.eventtap.event.types.flagsChanged},
      modifierHandler
    )
    modifierTap:start()
    local keyTap = hs.eventtap.new({keyDown, keyUp}, keyHandler)
    keyTap:start()
  end)
}
