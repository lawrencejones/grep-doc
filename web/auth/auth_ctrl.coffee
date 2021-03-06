auth = angular.module 'auth'
auth.controller\
( 'AuthCtrl'
, [ 'Auth', '$scope', '$http', '$window', '$state'
    (Auth,   $scope,   $http,   $window,   $state) ->

      $scope.input =
        login: null
        pass: null

      $scope.denied  = false
      $scope.waiting = false

      $scope.submit = ->
        $scope.waiting = true
        authed = Auth.login $scope.input.login, $scope.input.pass
        authed.then (data) ->
          if $window.blockedHash?
            $window.location = $window.blockedHash
            $window.blockedHash = null
          else
            $state.transitionTo 'app.profile' # or whatever home
        authed.catch ->
          $scope.denied  = true
          $scope.waiting = false
])

