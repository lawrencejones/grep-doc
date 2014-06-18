# vi: set foldmethod=marker
mongoose = require 'mongoose'
Models = require 'app/models'
Student = Models.Student

db = require 'test/server/db'
creds = require 'test/server/creds'

studentSeeds = require 'test/seeds/students'

# Shared test hooks ##################################################

[lawrence, nic] = [
  studentSeeds.lawrence
  studentSeeds.nic
]

# Seed database before each test
beforeEach (done) ->
  Student.register lawrence(), (err, student) ->
    student.should.be.ok
    do done

# Clear model after every test
afterEach (done) ->
  Student.model.remove {}, -> do done

# StudentModel Specs #################################################

describe 'StudentModel', ->

  # Seed database before each test
  beforeEach (done) ->
    Student.model.findOne login: lawrence().login, (err, student) ->
      student.should.be.ok
      do done

  describe '#getTid', ->

    it 'should resolve tid from login', ->
      Student.getTid nic().login, creds
      .should.eventually.eql tid: nic().tid

    it 'should catch invalid tid', ->
      Student.getTid 'totally_invalid', creds
      .should.eventually.eql tid: null

  describe '#getTeachdb', ->

    [nic(), lawrence()].map (seed) ->

      it "should fetch #{seed.fname} from teachdb", (done) ->
        Student.getTeachdb seed.login, creds
        .then (student) ->
          # Verify that new information has been returned and parsed
          student.email.should.eql seed.email
          do done
        .catch done

  describe 'produces JSON for API', ->

    it "version 1A", (done) ->
      Student.model.find {}, (err, students) -># {{{
        for json in students.map((b) -> b.api '1A')
          json.should.be.ok
          json.should.include.keys [
            'login', 'tid', 'email', 'fname', 'lname', 'cand'
          ]
          do done# }}}
        


