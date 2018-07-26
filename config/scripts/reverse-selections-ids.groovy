def ids_save = [] as Set
if (ctx._source.ids != null) {
	ids_save = ctx._source.ids as Set
}

def resultIds = ids - ids_save
ctx._source.ids = resultIds
ctx._source.service = service
ctx._source.date = date
ctx._source.name = name
ctx._source.userId = userId
