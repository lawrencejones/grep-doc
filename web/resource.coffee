############################################################
# Resource generator
############################################################

resource = angular.module 'resource', []
resource.factory 'Resource', [
  '$http'
  '$q'
  '$injector', ($http, $q, $injector) -> (opt = {}) ->

    # Configure options
    baseurl       =  opt.baseurl
    actions       =  opt.actions ?= {}
    relations     =  opt.relations ?= {}
    parser        =  opt.parser
    defaultParams =  opt.defaultParams ?= {}
    
    # Set up a resource cache
    relationKeys = Object.keys relations
    pragma = if baseurl? then '' else "[#{baseurl}] # "

    # Given a route and parameters, will attempt to generate route
    # to resource given params. Will fail if some parameters in route
    # have not been supplied and cannot be found in defaultParams.
    fillParams = (route, params) ->
      keys = (route.match(/:[^/]+/g) ? []).map (k) -> k[1..]
      for key in keys
        value = params[key] ? defaultParams[key]
        if not value? then throw new Error """
        Failed to supply #{key} parameter for route generation"""
        route = route.replace ":#{key}", value
      return route

    # Wraps $http promises into a standard $q promise.
    #
    # Takes type parameter, that specifies if the expected response should
    # be an array or a single object.
    #
    # Returns the default container for the desired server response, with
    # a $promise value attached. The $promise can then be listened on for
    # completion of the request, though $http will trigger a $scope digest
    # once the response is received.
    #
    # NB - Must call in context of resource Class!
    wrap = (type, req) ->

      # Configure result container, either array or object
      container = if type is 'array' then [] else new @
      container.$promise = (def = $q.defer()).promise

      # Handle request success case
      req.success (data, status) =>
        if typeof data == 'string'
          data = JSON.parse data
        switch type
          when 'array' then container.push @makeResource(data)...
          when 'object' then @call container, data
        def.resolve { data: container, status }

      # Handle case of error in request
      req.error (data, status) ->
        def.reject { data, status }

      return container

    class ResourceInterface

      # Entry to create new resource.
      @makeResource: (data) ->
        if data instanceof Array
          data.map (elem) => @makeResource elem
        else new @ data

      # Get index of all resources.
      @all: (params) -> @query(params)

      # Fetch result of querying resource.
      @query: (params, query = {}) ->
        wrap.call @, 'array', $http
          method: 'GET'
          url: fillParams actions.all, params
          params: query

      # Retrieve a single resource
      @get: (params) ->
        wrap.call @, 'object', $http
          method: 'GET'
          url: fillParams actions.get, params

          
    return class Resource extends ResourceInterface
    
      # Creates new Resource by merging empty object with the supplied
      # server data.
      constructor: (data = {}) ->
        angular.extend @, data
        do @populate
        parser?.call @

      # Analyses current resource and will init any field values that
      # are specified as model relations by new'ing their contents.
      populate: ->
        for key in relationKeys
          if not (@[key] instanceof Resource)
            r = relations[key]
            @[key] = (if typeof r == 'function' then new r @[key]
            else $injector.get(r)?.makeResource @[key])
        return this

      # Generates the api route to this resource.
      getResourceRoute: ->
        fillParams url.get, @

      # Attempt to save changes. On response, if not error then merge response
      # back into the record.
      save: ->
        wrap.call super, 'object', $http
          method: 'PATCH'
          url: @getResourceRoute()
        .then (data) =>
          angular.extend @, data

      # Deletes the resource.
      delete: ->
        wrap.call super, 'object', $http
          method: 'DELETE'
          url: @getResourceRoute()
        
]
