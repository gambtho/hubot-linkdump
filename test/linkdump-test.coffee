Helper = require('hubot-test-helper')
helper = new Helper('../src/linkdump.coffee')

chai = require 'chai'
chai.use require 'sinon-chai'
expect = chai.expect

nock = require 'nock'
sinon = require 'sinon'

# you must set a valid github token, or xit the tests related to load/save

#process.env.HUBOT_GITHUB_TOKEN =
process.env.HUBOT_GITHUB_USER = 'gambtho'
process.env.HUBOT_GITHUB_LINK_REPO = 'linkdump'
process.env.HUBOT_GITHUB_LINK_FILE = 'test_linkdump.json'

FIELD =
  SUBMITTER: 0
  RATING: 1

describe 'link list', ->
  room = null

  beforeEach ->
    room = helper.createRoom()

    nock("https://www.abc.com")
    .get("/links/")
    .reply 200, '{}'
    nock("https://www.abc.com")
    .get("/no-links/")
    .reply 404, '{}'

  afterEach ->
    room.destroy()
    nock.cleanAll()

  describe 'user asks hubot to display an un-initialized linkdump', ->

    beforeEach (done) ->
      room.robot.emit = sinon.spy()
      room.user.say 'mary', 'hubot linkdump'
      setTimeout done, 100

    it 'and it should reply with a response indicating that the linkdump is not initialized', ->
      expect(room.robot.emit.firstCall.args[1].content.title).equals("Null linkdump")

  describe 'user asks hubot to save an un-initialized linkdump', ->

    beforeEach (done) ->
      room.robot.emit = sinon.spy()
      room.user.say 'mary', 'hubot linkdump db save'
      setTimeout done, 100

    it 'and it should reply with a response indicating that the linkdump was not saved', ->
      expect(room.robot.emit.firstCall.args[1].content.title).equals("Unable to backup empty linkdump")

  describe 'user asks hubot to initialize linkdump', ->

    beforeEach (done)  ->
      room.robot.emit = sinon.spy()
      room.user.say 'mary', 'hubot linkdump initialize'
      setTimeout done, 100

    it 'and it should reply with a response indicating that the linkdump was initialized', ->
      expect(room.robot.emit.firstCall.args[1].content.title).equals("linkdump Initialized")

    describe 'user asks hubot to initialize linkdump', ->

      beforeEach (done)  ->
        room.robot.emit = sinon.spy()
        room.user.say 'mary', 'hubot linkdump initialize'
        setTimeout done, 100

      it 'and it should reply with a response indicating that the linkdump already exists', ->
        expect(room.robot.emit.firstCall.args[1].content.title).equals("linkdump already exists")

    describe 'user asks hubot to display linkdump', ->

      beforeEach  ->
        room.robot.emit = sinon.spy()
        room.user.say 'mary', 'hubot linkdump'

      it 'and it should reply with a no-links response when there are no links in the list', ->
        expect(room.robot.emit.firstCall.args[1].content.title).equals("no-links")

    describe 'user asks hubot to add links', ->

      beforeEach (done) ->
        room.robot.emit = sinon.spy()
        room.user.say 'alice', 'hubot linkdump add http://abc.com/links/'
        room.user.say 'mary', 'hubot linkdump add http://abc.com/no-links/'
        setTimeout done, 100

      it 'and it should reply confirming the addition of the first link',  ->
        expect(room.robot.emit.firstCall.args[1].content.title).equals("Added: http://abc.com/links/")

      it 'and it should reply with an error for invalid links',  ->
        expect(room.robot.emit.secondCall.args[1].content.title).to.match(/ADD ERROR - Lookup Error - (.*)$/)



#      describe 'then asks to save the linkdump', ->
#
#        beforeEach (done) ->
#          room.robot.emit = sinon.spy()
#          room.user.say 'alice', 'hubot linkdump db save'
#          setTimeout done, 20
#
#        it 'and it should reply confirming the save', ->
#          expect(room.robot.emit.firstCall.args[1].content.title).equals("linkdump backed up")
#
#      describe 'then asks to see the linkdump', ->
#
#        beforeEach (done) ->
#          room.robot.emit = sinon.spy()
#          room.user.say 'alice', 'hubot linkdump'
#          setTimeout done, 20
#
#        it 'and it should reply with the full link list', ->
#          expect(room.robot.emit.firstCall.args[1].content.title).equals("linkdump - 5 links")
#          expect(room.robot.emit.firstCall.args[1].content.thumb_url).equals("https://goo.gl/g5Itaz")
#          expect(room.robot.emit.firstCall.args[1].content.fields[3].title).equals("3 - link 3")
#          expect(room.robot.emit.firstCall.args[1].content.fields[3].value).equals("Author 3, Computers")
#
#      describe 'then asks for a specific link by index number', ->
#
#        beforeEach ->
#          room.robot.emit = sinon.spy()
#          room.user.say 'alice', 'hubot linkdump lookup 2'
#          room.user.say 'alice', 'hubot linkdump lookup 5'
#          room.user.say 'alice', 'hubot linkdump lookup junk'
#
#        it 'and it should reply including the title and index of the link requested', ->
#          expect(room.robot.emit.firstCall.args[1].content.title).equals("Index 2: link 2")
#
#        it 'and it should reply including the author of the link requested', ->
#          expect(room.robot.emit.firstCall.args[1].content.fields[FIELD.SUBMITTER].value).equals("Author 2")
#
#        it 'and it should reply including the category of the link requested', ->
#          expect(room.robot.emit.firstCall.args[1].content.fields[FIELD.RATING].value).equals("Computers")
#
#        it 'and it should reply including the image url of the link requested', ->
#          expect(room.robot.emit.firstCall.args[1].content.thumb_url).equals("http://big2")
#
#        it 'and it should reply with an error for indexes that do not exist', ->
#          expect(room.robot.emit.secondCall.args[1].content.title).equals("LOOKUP ERROR")
#          expect(room.robot.emit.lastCall.args[1].content.title).equals("LOOKUP ERROR")
#
#      describe 'then asks for info on a random link', ->
#
#        beforeEach ->
#          room.robot.emit = sinon.spy()
#          room.user.say 'alice', 'hubot linkdump random'
#
#        it 'and it should reply with a random link to alice', ->
#          expect(room.robot.emit.firstCall.args[1].content.title).to.match(/Random - (\d): (.*)$/)
#
#      describe 'then makes a link edit', ->
#
#        beforeEach (done) ->
#          room.robot.emit = sinon.spy()
#          room.user.say 'alice', 'hubot linkdump edit 500 junk'
#          setTimeout done, 100
#
#        it 'and it should reply with an edit error', ->
#          expect(room.robot.emit.firstCall.args[1].content.title).equals("EDIT ERROR")
#
#      describe 'then makes a link edit', ->
#
#        beforeEach (done) ->
#          room.robot.emit = sinon.spy()
#          room.user.say 'alice', 'hubot linkdump edit 2 pragmatic programmer'
#          setTimeout done, 100
#
#        it 'and it should reply with a confirmation of the edit', ->
#          expect(room.robot.emit.firstCall.args[1].content.title).equals("Updated: 2 is The Pragmatic Programmer")
#
#        describe 'then looks up an edited a link', ->
#
#          beforeEach (done) ->
#            room.robot.emit = sinon.spy()
#            room.user.say 'alice', 'hubot linkdump lookup 2'
#            setTimeout done, 10
#
#          it 'and it should reply including the title and index of the link requested', ->
#            expect(room.robot.emit.firstCall.args[1].content.title).equals("Index 2: The Pragmatic Programmer")
#
#          it 'and it should reply including the author of the link requested', ->
#            expect(room.robot.emit.firstCall.args[1].content.fields[FIELD.SUBMITTER].value).equals("Andrew Hunt")
#
#          it 'and it should reply including the category of the link requested', ->
#            expect(room.robot.emit.firstCall.args[1].content.fields[FIELD.RATING].value).equals("Computers")
#
#          it 'and it should reply including the image url of the link requested', ->
#            expect(room.robot.emit.firstCall.args[1].content.thumb_url).equals("http://bigPrag")
#
#
#        describe 'then adds a review', ->
#
#          beforeEach (done) ->
#            room.robot.emit = sinon.spy()
#            room.user.say 'alice', 'hubot linkdump review link 2 stars 5'
#            setTimeout done, 10
#
#          it 'and it should reply confirming alices rating', ->
#            expect(room.robot.emit.firstCall.args[1].content.title).equals("Reviewed: 2 - The Pragmatic Programmer")
#            expect(room.robot.emit.firstCall.args[1].content.fields[FIELD.RATING].value).equals(5)
#
#          describe 'then adds another review', ->
#
#            beforeEach (done) ->
#              room.robot.emit = sinon.spy()
#              room.user.say 'sam', 'hubot linkdump review link 2 stars 3'
#              setTimeout done, 10
#
#            it 'and it should reply confirming sams rating', ->
#              expect(room.robot.emit.firstCall.args[1].content.title).equals("Reviewed: 2 - The Pragmatic Programmer")
#              expect(room.robot.emit.firstCall.args[1].content.fields[FIELD.RATING].value).equals(4)
#
#  describe 'user asks hubot to load a linkdump when there are links saved', ->
#
#    beforeEach (done) ->
#      room.robot.emit = sinon.spy()
#      room.user.say 'mary', 'hubot linkdump db load'
#      setTimeout done, 1000
#
#    it 'and it should reply with a response indicating that the linkdump was loaded', ->
#      expect(room.robot.emit.firstCall.args[1].content.title).equals("linkdump re-loaded")
#
#    describe 'user asks hubot to list all links after a load', ->
#
#      beforeEach (done) ->
#        room.robot.emit = sinon.spy()
#        room.user.say 'joe', 'hubot linkdump'
#        setTimeout done, 100
#
#      it 'and it should reply with a list of links', ->
#        expect(room.robot.emit.firstCall.args[1].content.title).to.match(/linkdump - (\d{1,100}) links$/)
