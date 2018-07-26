def action = "none"
def removeTaxonRegister = { itemId, list ->

	def itTaxon = list.taxons.iterator()
	while (itTaxon.hasNext()) {
		def taxon = itTaxon.next()

		def it = taxon.registers.iterator()
		while (it.hasNext()) {
			def register = it.next()
			if (register.id.indexOf(itemId) > -1) {
				it.remove()
				action = "index"
				break
			}
		}
		if (taxon.registers.size() == 0) {
			itTaxon.remove()
			action = "index"
		}
	}
	if (list.taxons.size() == 0) {
		action = "delete"
	}
}

removeTaxonRegister(item_id, ctx._source.properties)
ctx.op = action
