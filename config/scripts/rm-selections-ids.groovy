def ids_save = []
if (ctx._source.ids != null) {
        ids_save = ctx._source.ids as Set
}

ids_save.removeAll(ids)
ctx._source.ids = ids_save
ctx._source.service = service
ctx._source.date = date
ctx._source.name = name
ctx._source.userId = userId
