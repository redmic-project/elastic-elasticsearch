
/*
 Función para buscar por un rango dado un valor y una desviación
*/

def findByRange = { def data, def minValue, def maxValue, def valuePropery, def deviationProperty ->

	def value = data[valuePropery]
	def deviation = data[deviationProperty]

	if (value == null)
		return false

	if (deviation == null)
		deviation = 0

	def lowerLimit = value-deviation
	def upperLimit = value+deviation

	// Límites de query a null, no se permite query
	if (minValue == null && maxValue == null)
		return false
	// Límites de query not null, se tiene en cuenta la desviación
	if (minValue != null && maxValue != null) {
		if (value >= minValue && value <= maxValue)
			return true
		if (upperLimit >= maxValue && lowerLimit <= minValue)
			return true
		if (upperLimit <= maxValue && upperLimit >= minValue)
			return true
		if (lowerLimit <= maxValue && lowerLimit >= minValue)
			return true
		return false
	}
	// Algún límite de query a null
	if (maxValue != null && upperLimit <= maxValue)
		return true
	if (minValue != null && lowerLimit >= minValue)
		return true
	return false
}

def data = _source

// Obtiene a partir del nestedPath el array datos a filtrar
if (nestedPath) {
	for (subPath in nestedPath.split("\\.")) {
		if (subPath.length() > 0) {
			if (data[subPath])
				data = data[subPath]
			else
				return false
		}
	}
}

def result = false

// para cada uno de los items del array
for (item in data) {

	def dataItem = item
	for (subPath in basePath.split("\\.")) {
		if (subPath.length() > 0) {
			dataItem = dataItem[subPath]
		}
	}

	result = findByRange(dataItem, zMin, zMax, "z", "deviation")
	// desde que uno cumpla la condición retorna true
	if (result)
		return result
}

return result
