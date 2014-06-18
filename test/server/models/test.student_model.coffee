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

    it 'should fail without crash with no credentials', (done) ->
      Student.getTeachdb lawrence().login, null # no creds
      .catch (err) -> err.should.be.ok; do done

  describe '#get', ->

    it 'should prefer supplying database instances over scraping', ->
      Student.get lawrence().login, null
      .should.eventually.have.property 'email', lawrence().email

    it 'should parse students if they are not in the database', ->
      Student.get nic().login, creds
      .should.eventually.have.property 'email', nic().email

  describe 'produces JSON for API', ->

    it "version 1A", (done) ->
      Student.model.find {}, (err, students) -># {{{
        for json in students.map((b) -> b.api '1A')
          json.should.be.ok
          json.should.include.keys [
            'login', 'tid', 'email', 'fname', 'lname', 'cand'
          ]
          do done# }}}
        


