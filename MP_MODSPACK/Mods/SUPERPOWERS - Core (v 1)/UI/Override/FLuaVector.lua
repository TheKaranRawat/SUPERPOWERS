-- FLuaVector

function Vector2( i, j ) return { x = i, y = j } end
function Vector3( i, j, k ) return { x = i, y = j, z = k } end
function Vector4( i, j, k, l ) return { x = i, y = j, z = k, w = l } end
if InStrategicView then
	Color = Vector4
else --CivBE case
	local floor = math.floor
	local function byte(n)
		return (n>=1 and 255) or (n<=0 and 0) or floor(n * 255)
	end
	function Color( red, green, blue, alpha )
		return byte(red or 0) + byte(green or 0)*0x100 + byte(blue or 0)*0x10000 + byte(alpha or 1)*0x1000000
	end
end

function VecAdd( u, v ) 
	return {
		x = u.x and v.x and u.x + v.x,
		y = u.y and v.y and u.y + v.y,
		z = u.z and v.z and u.z + v.z,
		w = u.w and v.w and u.w + v.w,
	}
end

function VecSubtract( u, v ) 
	return {
		x = u.x and v.x and u.x - v.x,
		y = u.y and v.y and u.y - v.y,
		z = u.z and v.z and u.z - v.z,
		w = u.w and v.w and u.w - v.w,
	}
end
