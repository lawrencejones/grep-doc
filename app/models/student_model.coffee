$q = require 'q'
Schema = (mongoose = require 'mongoose').Schema
ObjectId = Schema.Types.ObjectId

config = require 'app/etc/config'
require 'app/etc/db'

HTTPProxy = require 'app/proxies/http_proxy'
StudentProxy = new HTTPProxy require 'app/parsers/teachdb/student_parser'
StudentIDProxy = new HTTPProxy require 'app/parsers/teachdb/student_id_parser'

studentSchema = mongoose.Schema
  validFrom: Number
  validTo: Number
  tid: Number
  login: String
  email: String
  salutaion: String
  fname: String
  lname: String
  origin: String
  entryYear: Number
  url: String
  cand: String
  profile: String
  courses: [
    cid: String
    name: String
    eid: String
    terms: [Number]
    classes: [String]
  ]
  enrolment: [
    year: Number
    class: String
  ]

formats =
  '1A': ->
    _meta:
      link: "/api/users/#{@login}"
      login: @login
      tid: @tid
    validFrom: @validFrom
    validTo: @validTo
    tid: @tid
    login: @login
    email: @email
    salutation: @salutation
    fname: @fname
    lname: @lname
    origin: @origin
    entryYear: @entryYear
    url: @url
    cand: @cand
    profile: @profile
    courses: @courses.map (c) ->
      _meta:
        link: "/api/courses/#{c.year}/#{c.cid}"
        year: c.year
        cid: c.cid
      data:
        cid: c.cid
        name: c.name
        eid: c.eid
        terms: c.terms
        classes: c.classes
    enrolment: @enrolment

studentSchema.methods.api = (version = process.env.API_VERSION) ->
  json = formats[version]?.call? @
  if json then json else throw new Error """
  Format #{version} not supported"""

# Shorthand method for registering a student with plain json data
register = (data, cb) ->
  student = new Student data
  student.save (err) ->
    cb? err, student

# Generates promise that is resolved with student from database.
#
#   LOGIN: College login of student
#
# Returns a promise that is resolved with a database student object.
getDbStudent = (login) ->
  def = $q.defer()
  Student.findOne login: login, (err, student) ->
    if err then def.reject err
    else def.resolve student
  def.promise

# Given a students login, returns a promise that is resolved with the
# students teachdb ID.
#
#   LOGIN: College login
#   CREDS: Authentication credentials
#
# Returns a promise that is resolved with an object in the form...
#
#   tid: tid, login: login
#
getTid = (login, creds) ->
  getDbStudent(login).then (student) ->
    if student?.tid then tid: student.tid
    else StudentIDProxy.makeRequest login: login, creds

# Takes a LOGIN and optional TID value.
#
#   LOGIN: College login
#   CREDS: Authentication credentials
#   TID:   Optional teachdb ID of student, to skip indexing
#
# Returns a promise that is resolved with a student mongoose object.
getTeachdbStudent = (login, creds, tid = false) ->
  $q.fcall ->
    if tid then tid: tid else getTid login, creds
  .then (query) ->
    StudentProxy.makeRequest query, creds

# Fetches a student, either from our database or from teachdb if no
# record is present.
#
#   LOGIN: College login
#   CREDS: Authentication credentials
#   FORCE: Will rescrape Teachdb without supplying database
#
# Returns a promise that is resolved with a student object.
getStudent = (login, creds, force = false) ->
  getDbStudent(login).then (student) ->
    if student and not force then student
    else getTeachdbStudent login, creds, student?.tid

# Wraps around the getStudent function to allow easier authentication.
# If successful, the returned promise will be resolved with user data
# along with a token located in the _meta child.
#
#   LOGIN: College login
#   PASS:  Password for Imperial systems
#
# Forces a real request into teachdb.
authWrapper = (login, pass) ->
  getStudent login, user: login, pass: pass, true

Student = mongoose.model 'Student', studentSchema
module.exports =

  model: Student
  formats: formats
  schema: studentSchema

  register: register
  get: getStudent
  getTeachdb: getTeachdbStudent
  getTid: getTid
  auth: authWrapper

