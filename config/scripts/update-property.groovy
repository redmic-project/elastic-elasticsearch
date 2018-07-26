def action = "none"
def merge = { source, target ->  target << source}
def update = { newItem, oldItem ->
	if (oldItem.id == newItem.id) {
        merge(newItem, oldItem)
        action = "index"
    }
}

def data = ctx._source
for (subPath in propertyPath.split("\\.")) {
	if (subPath.length() > 0) {
		data = data[subPath]
	}
}

update(item, data)
ctx.op = action
