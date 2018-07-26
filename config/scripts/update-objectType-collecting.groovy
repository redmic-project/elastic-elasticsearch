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
			return true
		}
	}
	return false
}

def data = ctx._source

def propertyPath = "objectType"
for (it in data.object) {
	def found = updateNested(item, propertyPath, it.classification)
	if (found && item.level == 2) {
		it.name = item.name
	}
}

ctx.op = action
