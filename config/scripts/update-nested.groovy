def action = "none"
def merge = { source, target ->  target << source}
def updateNested = { newItem, path, list ->
	for (item in list) {
		def data = item
		for (subPath in path.split("\\.")) {
			if (subPath.length() > 0) {
				data = data[subPath]
			}
		}
		if (data.id == newItem.id) {
			merge(newItem, data)
			action = "index"
			break
		}
	}
}

def data = ctx._source
for (subPath in nestedPath.split("\\.")) {
	if (subPath.length() > 0) {
		data = data[subPath]
	}
}

updateNested(item, propertyPath, data)
ctx.op = action
