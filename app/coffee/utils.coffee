utils = @greenmine.utils = {}

utils.pointIdToOrder = (points) ->
    return (id) ->
        point = points[id]
        if point.get('order') == -2
            return 0.5
        else if point.get('order') == -1
            return 0
        return point.get('order')
