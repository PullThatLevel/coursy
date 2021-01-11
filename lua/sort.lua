--[[
	Stable in-place hybrid Merge Sort implementation in Lua.
	Should return a single function: stable_sort(t,c) which does exactly what's described.
	Original code by S. Fisher, modified for Lua 5.0 by XeroOl and 5.1 by PullThatLevel.
]]--

local function insertion_sort(t, l, h, c)
	for i = l + 1, h do
		local k = l
		local v = t[i]
		for j = i, l + 1, -1 do
			if c(v, t[j - 1]) then
				t[j] = t[j - 1]
			else
				k = j
				break
			end
		end
		t[k] = v
	end
end

local function merge(t, b, l, m, h, c)
	if c(t[m], t[m + 1]) then
		return
	end
	local i, j, k
	i = 1
	for j = l, m do
		b[i] = t[j]
		i = i + 1
	end
	i, j, k = 1, m + 1, l
	while k < j and j <= h do
		if c(t[j], b[i]) then
			t[k] = t[j]
			j = j + 1
		else
			t[k] = b[i]
			i = i + 1
		end
		k = k + 1
	end
	for k = k, j - 1 do
		t[k] = b[i]
		i = i + 1
	end
end

local magic_number = 12

local function merge_sort(t, b, l, h, c)
	if h - l < magic_number then
		insertion_sort(t, l, h, c)
	else
		local m = math.floor((l + h) / 2)
		merge_sort(t, b, l, m, c)
		merge_sort(t, b, m + 1, h, c)
		merge(t, b, l, m, h, c)
	end
end

local function default_comparator(a, b) return a < b end

local function stable_sort(t, c)
	if not t[2] then return t end
	c = c or default_comparator
	local n = table.getn and table.getn(t) or #t
	local b = {}
	b[math.floor((n + 1) / 2)] = t[1]
	merge_sort(t, b, 1, n, c)
	return t
end

return stable_sort
