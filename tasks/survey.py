"""Utility functions for building Qualtrics surveys."""

def pluck(items, search_term):
    for item in items:
        try:
            values = item.values()
        except AttributeError:
            continue
        else:
            if search_term in values:
                return item
    raise AssertionError('search term {} not found'.format(search_term))
