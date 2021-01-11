local MOD_OFFSET = 0.000

--{second, length, len_or_end ('L' or 'E'), mods}
local MODS_LIST = {
	--Your mods go here!
}

--Offset post-processing!
for _,m in ipairs(MODS_LIST) do
	m[1] = m[1] - MOD_OFFSET
	if m[3] == 'E' then m[2] = m[2] - MOD_OFFSET end 
end

return MODS_LIST