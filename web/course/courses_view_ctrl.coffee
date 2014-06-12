classy = angular.module 'classy'

classy.factory 'Courses', (Resource, $rootScope) ->
  class Courses extends Resource({
    actions:
      get: '/api/courses/:year/:cid'
    defaultParams:
      year: $rootScope.AppState.currentYear
    relations:
      notes: 'Notes'
      exercises: 'Exercises'
      grades: 'Grades'
      validTo: Date
      validFrom: Date
  })

classy.factory 'Notes', (Resource) ->
  class Notes extends Resource({
    relations:
      time: Date
  })

classy.factory 'Exercises', (Resource) ->
  class Exercises extends Resource({
    relations:
      start: Date
      end: Date
  })

classy.controller 'CoursesViewCtrl', ($scope, $stateParams, $state, Courses) ->
  ($scope.course = Courses.get $stateParams).$promise
  .then (course) ->
    console.log course

  .catch (err) ->
    $state.transitionTo 'app.courses', {}
    console.log "Error occurred."
