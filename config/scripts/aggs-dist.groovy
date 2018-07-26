def filterByConfidence = { confidence -> confidences.contains(confidence) }
def filterByPathTaxon = { pathTaxon -> taxons.contains(pathTaxon) }
def filterByMisidentification = {
	taxon -> taxon.registers.findAll { reg ->
		taxons.contains(reg.misidentification)
	}
}
def addRegisters = { taxon ->
	["registers": taxon.registers.findAll {
		reg -> filterByConfidence(reg.confidence)
	}]
}


_source.properties.registerCount = 0
_source.properties.taxonCount = 0

_source.properties.taxons.findAll { tax ->
	if (filterByPathTaxon(tax.path) || filterByPathTaxon(tax.equivalent) || filterByMisidentification(tax)) {
			tax << addRegisters(tax)
			
			if (tax.registers.size() > 0) {
				_source.properties.registerCount += tax.registers.size()
				_source.properties.taxonCount++
                                
				return true;
			}
			return false;
	}
	return false;
}

_source.properties.remove("taxons")
