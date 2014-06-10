$q = require 'q'
request = require 'request'
process.setMaxListeners 0

# Class for the basic HTTP proxy. All instances will own a parser,
# which will facilitate parsing the html source that this class
# will fetch.
#
# User credentials ARE handled here, and care is required.
module.exports = class HTTPProxy

  # Constructed using a HTMLParser class
  constructor: (@Parser) ->
    if not @Parser.HTML_PARSER
      throw Error "Invalid HTMLParser object: #{@Parser}"

  # Will generate a url from the parser, then using the supplied
  # USER function, will access the credentials and make the request.
  #
  # Returns a promise that is resolved with the parsed data.
  # If query if an ARRAY, will process each query individually.
  #
  # DELAY is the amount of time to delay the request by. Used to
  # prevent contention for site target on large numbers of queries.
  #
  # SALT is used for multiple requests when they are better spread
  # randomly over a time period. Again, is optional. Used for past
  # paper scraping where +12 requests can cause congestion.
  makeRequest: (query, user, delay = 0, salt = 0) ->

    # If query is an array then map over and generate a collective promise
    if query instanceof Array
      return $q.all query.modify (q) =>
        @makeRequest q, user, (delay + Math.random()*salt)

    # Initialise deferred
    def = $q.defer()
    
    try url = @Parser.url query
    catch err
      def.reject code: 400, msg: 'Malformed query'
      return def.promise

    # Retrieve the user credentials from the jwt store, or if testing
    # and supplied as USER then user that.
    auth = user?('USER_CREDENTIALS') ? user
    auth.sendImmediately = true
    options = url: url, auth: auth

    # Make request, feed result through parser and resolve promise.
    setTimeout (=>
      request options, (err, data, body) =>
        return def.reject err if err?
        def.resolve @Parser.parse url, query, body
        def = err = data = body = auth = options = null # gc
    ), 1000*delay

    return def.promise

  # Takes user login and password, resolves promise on whether
  # CATE has accepted the credentials.
  @auth: (user, pass) ->
    options =
      url: 'https://cate.doc.ic.ac.uk'
      auth:
        user: user, pass: pass
        sendImmediately: true
    def = $q.defer()
    request options, (err, data, body) ->
      def.reject 401 if data.statusCode is 401
      def.resolve data.statusCode
      options = def = err = data = body = null # gc
    def.promise


