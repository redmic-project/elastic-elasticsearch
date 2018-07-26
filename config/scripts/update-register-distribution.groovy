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
			break
		}
	}
	if (!existTaxon) {
		list.taxons.addAll(props)
	}
}

def updateTaxonRegister = { props, list ->

	def isInIndex = false

	def itTaxon = list.taxons.iterator()
	while (itTaxon.hasNext()) {
		def taxon = itTaxon.next()

		def it = taxon.registers.iterator()
		while (it.hasNext()) {
			def register = it.next()

			if (register.id == props.registers[0].id && taxon.id == props.id) { // mismo taxon; cambia el reg
				it.remove()
				props.registers.addAll(taxon.registers) // añade el nuevo
				merge(props, taxon) // guarda en el original lo nuevo
				isInIndex = true
				action = "index"
				break
			}
			else if (register.id == props.registers[0].id && taxon.id != props.id) { // cambia el taxon
				// marcamos el registro para eliminar (fuera del bucle)
				it.remove()
				if (taxon.registers.size() == 0) { // Si al eliminar el registro, el taxon no tiene más asociados
					itTaxon.remove() // eliminamos el taxon
				}
				break
			}
		}
	}
	if (!isInIndex) { // Si cambia el taxon de la cita o no estaba se añade el nuevo registro
		addTaxonRegister(props, list)
		action = "index"
	}
}
updateTaxonRegister(item, ctx._source.properties)
ctx.op = action
