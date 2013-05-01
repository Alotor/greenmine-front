angular.module 'greenmine.services.model', [], ($provide) ->
    modelProvider = ($http, $q, storage, url) ->
        headers = ->
            return {"X-SESSION-TOKEN": storage.get('token')}

        toJson = (data) ->
            return JSON.stringify(data)

        class Model
            constructor: (name, data) ->
                @_name = name
                @_attrs = data or {}
                @_modifiedAttrs = {}
                @_isModified = false
                #@_initializeProperties()

            _initializeProperties: ->
                self = @

                getter = (name) ->
                    return ->
                        if name.substr(0,2) == "__"
                            return self[name]

                        if name in self._modifiedAttrs
                            return self._modifiedAttrs[name]

                        return self._attrs[name]

                _.each @_attrs, (value, name) ->
                    options =
                        get: getter(name)
                        enumerable: true
                        configurable: true

                    Object.defineProperty(self, name, options)

            set: (key, val) ->
                self = @
                if _.isObject(key)
                    _.each key, (_value, _key) ->
                        @set(_key, _value)
                else if @_attrs[key] != val
                    @_modifiedAttrs[key] = val
                    @_isModified = true

            get: (key) ->
                if key in @_modifiedAttrs
                    return @_modifiedAttrs[key]
                return @_attrs[key]

            save: ->
                self = @
                defered = $q.defer()

                if not @isModified()
                    defered.resolve(self)
                    return defered.promise

                data = _.extend({}, @_modifiedAttrs)
                params =
                    method: "PATCH"
                    url: @getUrl()
                    headers: headers()
                    data: toJson(data)

                promise = $http(params)
                promise.success (data, status) ->
                    self._isModified = false
                    self._attrs = _.extend(self._attrs, self._modifiedAttrs, data)
                    self._modifiedAttrs = {}
                    defered.resolve(self)

                promise.error (data, status) ->
                    defered.reject(self)

                return defered.promise

            refresh: ->
                self = @
                defered = $q.defer()

                params =
                    method: "GET"
                    url: @getUrl()
                    headers: headers()

                promise = $http(params)
                promise.success (data, status) ->
                    self._modifiedAttrs = {}
                    self._isModified = false
                    self._attrs = data
                    defered.resolve(self)

                promise.error (data, status) ->
                    defered.reject(self)

                return defered.promise

            remove: ->
                defered = $q.defer()

                params =
                    method: "DELETE"
                    url: @getUrl()
                    headers: headers()

                promise = $http(params)
                promise.success (data, status) ->
                    defered.resolve()
                promise.error (data, status) ->
                    defered.reject()

                return defered.promise

            isModified: -> @_isModified
            getUrl: -> "#{url(@_name)}#{@_attrs.id}/"
            attrs: -> _.extend({}, @_attrs, @_modifiedAttrs)

        service = (name, data, model=Model) ->
            return new model(name, data)

        service.cls = Model
        return service

    $provide.factory('$model', ['$http', '$q', 'storage', 'url', modelProvider])
