# Description
#   A hubot script for saving and viewing links
#
# Configuration:
#   HUBOT_GITHUB_TOKEN
#   HUBOT_GITHUB_USER
#   HUBOT_GITHUB_LINK_REPO
#   HUBOT_GITHUB_LINK_FILE
#
# Commands:
#   hubot linkdump random - Returns a random link
#   hubot linkdump add <URL> - adds the link to the linkdump
#   hubot linkdump lookup <index> - retrieves link information
#   hubot linkdump - displays full linkdump
#   hubot linkdump edit <index> <URL> - edit link at index with new link
#   hubot linkdump review link <index> stars <rating> - rates the selected link
#
#
# Author:
#   gambtho <thomas_gamble@homedepot.com>
#
# Idea from @krujos, script borrows heavily from hubot-booklist
#
# Image - By Paik, Kenneth, 1940-2006, Photographer (NARA record: 8464462) (U.S. National Archives and Records Administration) [Public domain], via Wikimedia Commons

Github = require('github-api')

module.exports = (robot) ->

  LINK =
    URL: 0
    SUBMITTER: 1
    RATING: 2
    REVIEWCOUNT: 3
    IMAGE: 4

  TITLE_IMAGE = 'https://upload.wikimedia.org/wikipedia/commons/f/f8/AUTOMOBILE_JUNKYARD_ON_THE_NORTH_BANK_OF_THE_KANSAS_RIVER_BETWEEN_THE_12TH_AND_18TH_STREET_BRIDGES_-_NARA_-_552073.jpg'

  TOKEN = process.env.HUBOT_GITHUB_TOKEN
  GITHUB_USER = process.env.HUBOT_GITHUB_USER
  GITHUB_REPO = process.env.HUBOT_GITHUB_LINK_REPO
  GITHUB_FILE = process.env.HUBOT_GITHUB_LINK_FILE

  robot.hear /linkdump initialize/i, (res) ->
    if robot.brain.get('linkdump')
      if robot.brain.get('linkdump').length >= 0
        return emitString(res, "linkdump already exists")

    robot.brain.set('linkdump', [])
    return emitString(res, "linkdump Initialized")

  prepRepo = (res, cb) ->
    github = new Github {token: TOKEN, auth: "oauth"}
    email = "hubot@hubot.com"
    user = "hubot"
    if res.user
      if res.user.name
        user = res.user.name
      if res.user.email_address
        email = res.user.email_address
    options = {
      author: {
        name: user
        email: email
      }
      committer: {
        name: user
        email: email
      }
      encode: true
    }
    repo = github.getRepo GITHUB_USER, GITHUB_REPO
    cb(repo, options)

  robot.hear /linkdump db (.*)$/i, (res) ->
    linkdump = getlinkdump()
    if res.match[1] == "save"
      if linkdump and linkdump.length > 0
        prepRepo res, (repo, options) ->
          repo.write 'master', GITHUB_FILE, JSON.stringify(linkdump), "hubot", options, (err) ->
            return emitString(res, "BACKUP ERORR -" + err) if err
          return emitString(res, "linkdump backed up")
      return emitString(res, "Unable to backup empty linkdump")
    if res.match[1] == "load"
      if linkdump and linkdump.length > 0
        return emitString(res, "linkdump already exists")
      else
        prepRepo res, (repo, options) ->
          repo.read 'master', GITHUB_FILE, (err, data) ->
            return emitString("RELOAD ERROR - " + err) if err
            robot.brain.set('linkdump', data)
            return emitString(res, "linkdump re-loaded")

  robot.hear /linkdump add (.*)$/i, (res) ->
    linkToAdd = res.match[1]
    rating = 0
    nbrOfReviews = 0

    addlink res, linkToAdd, rating, nbrOfReviews, null, (err) ->

      return emitString(res,"ADD ERROR - #{err}") if err

      formatlinkInfo getLastlink(), "Added: ", (link, err) ->

        return emitString(res,"ADD ERROR - #{err}") if err
        robot.emit 'slack-attachment',
          channel: res.envelope.room
          content: link

  robot.hear /linkdump review link (\d{1,5}) stars (\d{1})/i, (res) ->
    index = res.match[1]
    reviewRating = parseInt(res.match[2], 10)

    if reviewRating > 5
      return emitString(res,"Ratings must be between 1 and 5")

    maxIndex = getlinkdump().length - 1
    if index > maxIndex
      return emitString(res,"link DOES NOT EXIST ERROR")
    else
      addReview index, reviewRating

      formatlinkInfo getlinkAtIndex(index), "Reviewed: #{index} - ", (formattedlink, err) ->

        return emitString(res,"EDIT ERROR - #{err}") if err
        robot.emit 'slack-attachment',
          channel: res.envelope.room
          content: formattedlink

  robot.hear /linkdump random/i, (res) ->
    linkdump = getlinkdump()
    if linkdump.length == 0
      return emitString(res, "no-links")
    else
      randomlink = res.random getlinkdump()
      index = getlinkdump().indexOf(randomlink)
      formatlinkInfo randomlink, "Random - #{index}: ", (link, err) ->

        return emitString(res,"RANDOM ERROR - #{err}") if err

        robot.emit 'slack-attachment',
          channel: res.envelope.room
          content: link

  robot.hear /linkdump$/i, (res) ->
    linkdump = getlinkdump()
    return emitString(res, "Null linkdump") if linkdump is null
    if linkdump.length == 0
      return emitString(res,"no-links")
    else
      fields = []

      linkdump.map (link) ->
        fields.push
          title: "#{linkdump.indexOf(link)} - #{link[LINK.URL].value}"
          value: "#{link[LINK.SUBMITTER].value}, #{link[LINK.RATING].value} stars"

      payload =
        title: "linkdump - #{getlinkdump().length} links"
        thumb_url: TITLE_IMAGE
        fields: fields

      robot.emit 'slack-attachment',
        channel: res.envelope.room
        content: payload

  robot.hear /linkdump lookup (\d{1,20})$/i, (res) ->
    index = res.match[1]
    maxIndex = getlinkdump().length - 1
    if index > maxIndex
      return emitString(res,"LOOKUP ERROR")
    else
      formatlinkInfo getlinkAtIndex(index), "Index #{index}: ", (link, err) ->

        return emitString(res,"LOOKUP ERROR - #{err}") if err

        robot.emit 'slack-attachment',
          channel: res.envelope.room
          content: link

  robot.hear /linkdump edit (\d{1,20}) (.*)$/i, (res) ->
    rating = 0
    nbrOfRatings = 0

    index = res.match[1]

    newLink = res.match[2]
    maxIndex = getlinkdump().length - 1
    if index > maxIndex
      return emitString(res,"EDIT ERROR")
    else
      addlink res, newLink, rating, nbrOfRatings, index, (err) ->
        return emitString(res,"EDIT ERROR - #{err}") if err


        formatlinkInfo getlinkAtIndex(index), "Updated: #{index} is ", (link, err) ->

          return emitString(res,"EDIT ERROR - #{err}") if err

          robot.emit 'slack-attachment',
            channel: res.envelope.room
            content: link

  getlinkAtIndex = (index) ->
    getlinkdump()[index]

  getlinkdump = ->
    robot.brain.get('linkdump')

  addlink = (res, url, rating, nbrOfReviews, index, cb) ->
    linkValidationQuery res, url, (err) ->
      return cb err if err

      user = "hubot"
      if res.user
        if res.user.name
          user = res.user.name
      link = []
      link.push
        key: "URL"
        value: url

      link.push
        key: "Submitter"
        value: user

      link.push
        key: "Average Rating"
        value: rating

      link.push
        key: "Number of Reviews"
        value: nbrOfReviews

      link.push
        key: "Image"
        value: TITLE_IMAGE

      linkdump = getlinkdump()
      if index
        getlinkdump()[index] = link
      else
        linkdump.push link
      cb err

  addReview = (index, newRating) ->
    link = getlinkAtIndex(index)
    newRating = parseInt(newRating, 10)

    currentAverage = 0
    nbrOfReviews = 0

    if link[LINK.RATING] and link[LINK.REVIEWCOUNT]
      currentAverage = link[LINK.RATING].value
      nbrOfReviews = link[LINK.REVIEWCOUNT].value

    newTotalOfAllRatings = currentAverage * nbrOfReviews + newRating

    nbrOfReviews++

    newAverage = newTotalOfAllRatings / nbrOfReviews

    link[LINK.RATING].value = newAverage
    link[LINK.REVIEWCOUNT].value = nbrOfReviews

  getLastlink = ->
    linkdump = getlinkdump()
    last = linkdump.length - 1
    getlinkAtIndex(last)

  emitString = (res, string="Error") ->
    payload =
      title: string
    robot.emit 'slack-attachment',
      channel: res.envelope.room
      content: payload

  formatlinkInfo = (link, action, cb) ->
    currentAverage = 0

    if link[LINK.RATING] and link[LINK.REVIEWCOUNT]
      currentAverage = link[LINK.RATING].value

    payload =
      title: action + link[LINK.URL].value
      thumb_url: link[LINK.IMAGE].value
      fields: [
        { short: true, title: "Submitted by", value: link[LINK.SUBMITTER].value }
        { short: true, title: "Average Rating", value: currentAverage }
      ]

    cb(payload, null)

  linkValidationQuery = (res, URL, cb) ->
    res.http("#{URL}")
    .get() (err, resp, body) ->
      if err or not (resp.statusCode==200)
        err = "Validation Error - error is " + err + " - status is - " + resp.statusCode
      cb(err)
