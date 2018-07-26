def limit = 360 - degrees

def value = _source.value

if (value > 360 || value < 0) {
	value = null
} else if (value >= limit) {
	value -= limit
} else {
	value += degrees
}

return value
