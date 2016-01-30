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
process.env.HUBOT_GITHUB_LINK_REPO = 'link-dump'
process.env.HUBOT_GITHUB_LINK_FILE = 'testdump.json'

TITLE_IMAGE = 'https://upload.wikimedia.org/wikipedia/commons/f/f8/AUTOMOBILE_JUNKYARD_ON_THE_NORTH_BANK_OF_THE_KANSAS_RIVER_BETWEEN_THE_12TH_AND_18TH_STREET_BRIDGES_-_NARA_-_552073.jpg'

FIELD =
  SUBMITTER: 0
  RATING: 1

describe 'link list', ->
  room = null

  beforeEach ->
    room = helper.createRoom()

    nock("https://abc.com")
    .get("/links/")
    .reply 200, 'Success'
    nock("https://abc.com")
    .get("/no-links/")
    .reply 404, 'Failure'
    nock("https://cde.com")
    .get("/links/")
    .reply 200, 'Success'

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
        room.user.say 'alice', 'hubot linkdump add https://abc.com/links/'
        room.user.say 'mary', 'hubot linkdump add https://abc.com/no-links/'
        setTimeout done, 100

      it 'and it should reply confirming the addition of the first link',  ->
        expect(room.robot.emit.firstCall.args[1].content.title).equals("Added: https://abc.com/links/")

      it 'and it should reply with an error for invalid links',  ->
        expect(room.robot.emit.secondCall.args[1].content.title).equals("ADD ERROR - Validation Error - error is null - status is - 404")

      describe 'then asks to save the linkdump', ->

        beforeEach (done) ->
          room.robot.emit = sinon.spy()
          room.user.say 'alice', 'hubot linkdump db save'
          setTimeout done, 20

        it 'and it should reply confirming the save', ->
          expect(room.robot.emit.firstCall.args[1].content.title).equals("linkdump backed up")

      describe 'then asks to see the linkdump', ->

        beforeEach (done) ->
          room.robot.emit = sinon.spy()
          room.user.say 'alice', 'hubot linkdump'
          setTimeout done, 20

        it 'and it should reply with the full link list', ->
          expect(room.robot.emit.firstCall.args[1].content.title).equals("linkdump - 1 links")
          expect(room.robot.emit.firstCall.args[1].content.thumb_url).equals(TITLE_IMAGE)
          expect(room.robot.emit.firstCall.args[1].content.fields[0].title).equals("0 - https://abc.com/links/")
          expect(room.robot.emit.firstCall.args[1].content.fields[0].value).equals("hubot, 0 stars")

      describe 'then asks for a specific link by index number', ->

        beforeEach ->
          room.robot.emit = sinon.spy()
          room.user.say 'alice', 'hubot linkdump lookup 0'
          room.user.say 'alice', 'hubot linkdump lookup 5'
          room.user.say 'alice', 'hubot linkdump lookup junk'

        it 'and it should reply including the title and index of the link requested', ->
          expect(room.robot.emit.firstCall.args[1].content.title).equals("Index 0: https://abc.com/links/")

        it 'and it should reply including the author of the link requested', ->
          expect(room.robot.emit.firstCall.args[1].content.fields[FIELD.SUBMITTER].value).equals("hubot")

        it 'and it should reply including the category of the link requested', ->
          expect(room.robot.emit.firstCall.args[1].content.fields[FIELD.RATING].value).equals(0)

        it 'and it should reply including the image url of the link requested', ->
          expect(room.robot.emit.firstCall.args[1].content.thumb_url).equals(TITLE_IMAGE)

        it 'and it should reply with an error for indexes that do not exist', ->
          expect(room.robot.emit.secondCall.args[1].content.title).equals("LOOKUP ERROR")
          expect(room.robot.emit.lastCall.args[1].content.title).equals("LOOKUP ERROR")

      describe 'then asks for info on a random link', ->

        beforeEach ->
          room.robot.emit = sinon.spy()
          room.user.say 'alice', 'hubot linkdump random'

        it 'and it should reply with a random link to alice', ->
          expect(room.robot.emit.firstCall.args[1].content.title).to.match(/Random - (\d): (.*)$/)

      describe 'then makes a link edit', ->

        beforeEach (done) ->
          room.robot.emit = sinon.spy()
          room.user.say 'alice', 'hubot linkdump edit 500 junk'
          setTimeout done, 100

        it 'and it should reply with an edit error', ->
          expect(room.robot.emit.firstCall.args[1].content.title).equals("EDIT ERROR")

      describe 'then makes a link edit', ->

        beforeEach (done) ->
          room.robot.emit = sinon.spy()
          room.user.say 'alice', 'hubot linkdump edit 0 https://cde.com/links/'
          setTimeout done, 100

        it 'and it should reply with a confirmation of the edit', ->
          expect(room.robot.emit.firstCall.args[1].content.title).equals("Updated: 0 is https://cde.com/links/")

        describe 'then looks up an edited a link', ->

          beforeEach (done) ->
            room.robot.emit = sinon.spy()
            room.user.say 'alice', 'hubot linkdump lookup 0'
            setTimeout done, 10

          it 'and it should reply including the title and index of the link requested', ->
            expect(room.robot.emit.firstCall.args[1].content.title).equals("Index 0: https://cde.com/links/")



        describe 'then adds a review', ->

          beforeEach (done) ->
            room.robot.emit = sinon.spy()
            room.user.say 'alice', 'hubot linkdump review link 0 stars 5'
            setTimeout done, 10

          it 'and it should reply confirming alices rating', ->
            expect(room.robot.emit.firstCall.args[1].content.title).equals("Reviewed: 0 - https://cde.com/links/")
            expect(room.robot.emit.firstCall.args[1].content.fields[FIELD.RATING].value).equals(5)

          describe 'then adds another review', ->

            beforeEach (done) ->
              room.robot.emit = sinon.spy()
              room.user.say 'sam', 'hubot linkdump review link 0 stars 3'
              setTimeout done, 10

            it 'and it should reply confirming sams rating', ->
              expect(room.robot.emit.firstCall.args[1].content.title).equals("Reviewed: 0 - https://cde.com/links/")
              expect(room.robot.emit.firstCall.args[1].content.fields[FIELD.RATING].value).equals(4)

  describe 'user asks hubot to load a linkdump when there are links saved', ->

    beforeEach (done) ->
      room.robot.emit = sinon.spy()
      room.user.say 'mary', 'hubot linkdump db load'
      setTimeout done, 1000

    it 'and it should reply with a response indicating that the linkdump was loaded', ->
      expect(room.robot.emit.firstCall.args[1].content.title).equals("linkdump re-loaded")

    describe 'user asks hubot to list all links after a load', ->

      beforeEach (done) ->
        room.robot.emit = sinon.spy()
        room.user.say 'joe', 'hubot linkdump'
        setTimeout done, 100

      it 'and it should reply with a list of links', ->
        expect(room.robot.emit.firstCall.args[1].content.title).to.match(/linkdump - (\d{1,100}) links$/)
