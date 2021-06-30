--
-- Copyright (c) 2021 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

--[[
   code sample from https://github.com/skywind3000/avlmini
]]

local function _leftHeight(self, key)
    local left = self._left[key]
    return (left ~= nil) and self._height[left] or 0
end

local function _rightHeight(self, key)
    local right = self._right[key]
    return (right ~= nil) and self._height[right] or 0
end

local function _childReplace(self, oldkey, newkey, parent)
    if parent ~= nil then
        if self._left[parent] == oldkey then
            self._left[parent] = newkey
        else
            self._right[parent] = newkey
        end
    else
        self._head = newkey
    end
end

local function _rotateLeft(self, key)
    local right = self._right[key]
    local parent = self._parent[key]
    self._right[key] = self._left[right]
    if self._left[right] ~= nil then
        self._parent[self._left[right]] = key
    end
    self._left[right] = key
    self._parent[right] = parent
    _childReplace(self, key, right, parent)
    self._parent[key] = right
    return right
end

local function _rotateRight(self, key)
    local left = self._left[key]
    local parent = self._parent[key]
    self._left[key] = self._right[left]
    if self._right[left] ~= nil then
        self._parent[self._right[left]] = key
    end
    self._right[left] = key
    self._parent[left] = parent
    _childReplace(self, key, left, parent)
    self._parent[key] = left
    return left     
end

local function _updateHeight(self, key)
    local h0 = _leftHeight(self, key)
    local h1 = _rightHeight(self, key)
    self._height[key] = math.max(h0, h1) + 1
end

local function _fixLeft(self, key)
    local right = self._right[key]
    local h0 = _leftHeight(self, right)
    local h1 = _rightHeight(self, right)
    if h0 > h1 then
        right = _rotateRight(self, right)
        _updateHeight(self, self._right[right])
        _updateHeight(self, right)
    end
    key = _rotateLeft(self, key)
    _updateHeight(self, self._left[key])
    _updateHeight(self, key)
    return key
end

local function _fixRight(self, key)
    local left = self._left[key]
    local h0 = _leftHeight(self, left)
    local h1 = _rightHeight(self, left)
    if h0 < h1 then
        left = _rotateLeft(self, left)
        _updateHeight(self, self._left[left])
        _updateHeight(self, left)
    end
    key = _rotateRight(self, key)
    _updateHeight(self, self._right[key])
    _updateHeight(self, key)
    return key
end

local function _reBalance(self, key)
    while key ~= nil do
        local h0 = _leftHeight(self, key)
        local h1 = _rightHeight(self, key)
        local diff = h0 - h1
        local height = math.max(h0, h1) + 1
        if self._height[key] ~= height then
            self._height[key] = height
        elseif diff >= -1 and diff <= 1 then
            break
        end
        if diff <= -2 then
            key = _fixLeft(self, key)
        elseif diff >= 2 then
            key = _fixRight(self, key)
        end
        key = self._parent[key]
    end
end

local function _linkUpdate(self, parent)
    self._pr = parent
end

local function _linkChild(self, sw, key)
    if key == nil then
        if sw == 0 then
            return self._pr
        elseif sw < 0 then
            return self._left[self._pr]
        else
            return self._right[self._pr]
        end
    else
        if sw == 0 then
            self._head = key
        elseif sw < 0 then
            self._left[self._pr] = key
        else
            self._right[self._pr] = key
        end
    end
end

-- update to with from, or clear to
local function _keyUpdate(self, to, from)
    if from == nil then
        self._left[to] = nil
        self._right[to] = nil
        self._parent[to] = nil
        self._height[to] = nil
        self._value[to] = nil
    else
        self._left[to] = self._left[from]
        self._right[to] = self._right[from]
        self._parent[to] = self._parent[from]
        self._height[to] = self._height[from]
    end
end

--
-- Public Interface
--

local _M = {}
_M.__index = _M

function _M:count()
    return self._count
end

-- return minimal key and value
function _M:first()
    if self._count <= 0 then
        return nil
    end
    local left = self._head
    while self._left[left] ~= nil do
        left = self._left[left]
    end
    return left, self._value[left]
end

-- return maximal key and value
function _M:last()
    if self._count <= 0 then
        return nil
    end
    local right = self._head
    while self._right[right] ~= nil do
        right = self._right[right]
    end
    return right, self._value[right]
end

-- return next key and value
function _M:next(key)
    if key == nil then
        return nil
    end
    local item = self._right[key]
    if item ~= nil then
        while self._left[item] ~= nil do
            item = self._left[item]
        end
    else
        item = key
        while true do
            local last = item
            item = self._parent[item]
            if item == nil then
                break
            end
            if self._left[item] == last then
                break
            end
        end
    end
    if item == nil then
        return nil
    end
    return item, self._value[item]
end

-- return prev key and value
function _M:prev(key)
    if key == nil then
        return nil, nil
    end
    local item = self._left[key]
    if item ~= nil then
        while self._right[item] ~= nil do
            item = self._right[item]
        end
    else
        item = key
        while true do
            local last = item
            item = self._parent[item]
            if item == nil then
                break
            end
            if self._right[item] == last then
                break
            end
        end
    end
    if item == nil then
        return nil, nil
    end
    return item, self._value[item]
end

-- find key/value
function _M:find(key)
    if key == nil or self._count <= 0 then
        return nil
    end
    local n = self._head
    local fn = self._fn
    while n ~= nil do
        local hr = fn(key, n)
        if hr == 0 then
            return n, self._value[n]
        elseif hr < 0 then
            n = self._left[n]
        else
            n = self._right[n]
        end
    end
    return nil
end

-- insert key with value, default not replace
function _M:insert(key, value, replace)
    if key == nil then
        return false
    end
    replace = replace or false
    local parent = nil
    local sw = 0
    local fn = self._fn
    _linkUpdate(self, self._head)
    while true do
        parent = _linkChild(self, sw, nil)
        if parent == nil then
            break
        end
        _linkUpdate(self, parent)
        sw = fn(key, parent)
        if sw == 0 then
            if replace then
                self._value[key] = value
            end
            return true
        elseif _linkChild(self, sw, nil) == nil then
            break
        end
    end
    self._value[key] = value
    self._parent[key] = parent
    self._height[key] = 1
    _linkChild(self, sw, key)
    _reBalance(self, parent)
    self._count = self._count + 1
end

-- remove key and return value
function _M:remove(key)
    if key == nil or self._height[key] == nil then
        return nil
    end
    local value = self._value[key]    
    local child = nil
    local parent = nil
    if self._left[key] ~= nil and self._right[key] ~= nil then
        local old = key
        key = self._right[key]
        while true do
            local left = self._left[key]
            if left == nil then
                break
            end
            key = left
        end
        child = self._right[key]
        parent = self._parent[key]
        if child ~= nil then
            self._parent[child] = parent
        end
        _childReplace(self, key, child, parent)
        if self._parent[key] == old then
            parent = key
        end
        _keyUpdate(self, key, old)
        _childReplace(self, old, key, self._parent[old])
        self._parent[self._left[old]] = key
        if self._right[old] ~= nil then
            self._parent[self._right[old]] = key
        end
        _keyUpdate(self, old, nil)
    else
        if self._left[key] == nil then
            child = self._right[key]
        else
            child = self._left[key]
        end
        parent = self._parent[key]
        _childReplace(self, key, child, parent)
        if child ~= nil then
            self._parent[child] = parent
        end
        _keyUpdate(self, key, nil)
    end
    if parent ~= nil then
        _reBalance(self, parent)
    end
    self._count = self._count - 1
    return value
end

-- iterator
function _M:walk(seq)
    if self._count <= 0 then
        return function()
            return nil
        end        
    end
    if seq ~= false then
        seq = true
    end
    local key 
    local value
    if seq then
        key, value = self:first()
    else
        key, value = self:last()
    end
    return function()
        if key ~= nil then
            local rkey = key
            local rvalue = value
            if seq then
                key, value = self:next(key)
            else
                key, value = self:prev(key)
            end
            return rkey, rvalue
        else
            return nil
        end
    end
end

-- index range, as (2, 3) or (9, 7)
function _M:range(from, to)
    from = from or 1
    to = to or self._count
    if self._count <= 0 or math.min(from, to) < 1 or math.max(from, to) > self._count then
        return {}
    end
    local range = {}
    local step = (from < to) and 1 or -1
    local idx = (step > 0) and 1 or self._count
    local key
    if step > 0 then
        key = self:first()
    else
        key = self:last()
    end
    if from > to then
        from, to = to, from
    end
    repeat
        if idx >= from and idx <= to then
            range[#range + 1] = key
        end
        idx = idx + step
        if step > 0 then
            if idx > to then
                break
            end
            key = self:next(key)
        else
            if idx < from then
                break
            end
            key = self:prev(key)
        end
    until key == nil
    return range
end

-- clear
function _M:clear()
    if self._count <= 0 then
        return
    end
    self._count = 0
    self._head = nil
    self._left = {}
    self._right = {}
    self._parent = {}
    self._height = {}
    self._value = {}
end

-- get key height
function _M:height(key)
    if key == nil or self._count <= 0 then
        return -1
    end
    return self._height[key] or -1
end

-- compare_fn(key1, key2) return -1, 0, 1 when <, =, >
local function _new(compare_fn)
    if compare_fn == nil then
        return nil
    end
    local ins = {
        _count = 0,
        _head = nil,
        _left = {},
        _right = {},
        _parent = {},
        _height = {},
        _value = {},
        _fn = compare_fn,
        _pr = nil
    }
    return setmetatable(ins, _M)
end

return {
    new = _new
}