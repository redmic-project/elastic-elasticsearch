def action = "none"

def merge = { source, target ->  target << source }

def add = { source, target ->
	def it = target.iterator()
	while (it.hasNext()) {
		def item = it.next()
		if (item.id == source[0].id) {
			it.remove()
		}
	}
	source.addAll(target)
}

def addTaxonRegister = { props, list ->
	def existTaxon = false
	def it = list.taxons.iterator()
	while (it.hasNext()) {
		def taxon = it.next()
		if (taxon.id == props.id) {
			existTaxon = true
			add(props.registers, taxon.registers) // mezcla los registro antiguos con los nuevos
			merge(props, taxon) // guarda en el original lo nuevo
			action = "index"
			break
		}
	}
	if (!existTaxon) {
		list.taxons.addAll(props)
		action = "index"
	}
}

addTaxonRegister(item, ctx._source.properties)
ctx.op = action
