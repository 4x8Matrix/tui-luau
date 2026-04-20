return function(s: string, i: number, j: number): string
	local startByte = utf8.offset(s, i) or (#s + 1)
	local nextByte = utf8.offset(s, j + 1)
	return s:sub(startByte, nextByte and nextByte - 1 or #s)
end
