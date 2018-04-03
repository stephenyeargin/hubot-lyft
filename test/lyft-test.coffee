Helper = require 'hubot-test-helper'
chai = require 'chai'
nock = require 'nock'
fs = require 'fs'

expect = chai.expect

helper = new Helper [
  '../src/lyft.coffee'
]

# Alter time as test runs
originalDateNow = Date.now
mockDateNow = () ->
  return Date.parse('Tue Mar 06 2018 23:01:27 GMT-0600 (CST)')

describe 'hubot-lyft', ->
  beforeEach ->
    process.env.HUBOT_LYFT_DEFAULT_LONGITUDE='-86.000'
    process.env.HUBOT_LYFT_DEFAULT_LATITUDE='36.000'
    process.env.HUBOT_LYFT_CLIENT_TOKEN='foobarbaz'
    Date.now = mockDateNow
    @room = helper.createRoom()
    nock.disableNetConnect()

  afterEach ->
    delete process.env.HUBOT_LYFT_DEFAULT_LONGITUDE
    delete process.env.HUBOT_LYFT_DEFAULT_LATITUDE
    delete process.env.HUBOT_LYFT_CLIENT_TOKEN
    Date.now = originalDateNow
    @room.destroy()
    nock.cleanAll()

  it 'retrieves the current lyft availability', (done) ->
    options =
      reqheaders:
        authorization: "Bearer foobarbaz"
    nock('https://api.lyft.com', options)
      .get('/v1/ridetypes')
      .query(
        lat: '36.000'
        lng: '-86.000'
      )
      .reply 200, fs.readFileSync('test/fixtures/ridetypes.json')
    nock('https://api.lyft.com', options)
      .get('/v1/eta')
      .query(
        lat: '36.000'
        lng: '-86.000'
      )
      .reply 200, fs.readFileSync('test/fixtures/eta.json')

    selfRoom = @room
    selfRoom.user.say('alice', '@hubot lyft')
    setTimeout(() ->
      try
        expect(selfRoom.messages).to.eql [
          ['alice', '@hubot lyft']
          ['hubot',  'Lyft Line: Seats 2, arrives in 2 minute(s)']
          ['hubot',  'Lyft: Seats 4, arrives in 2 minute(s)']
          ['hubot',  'Lyft Plus: Seats 6, arrives in 11 minute(s)']
        ]
        done()
      catch err
        done err
      return
    , 1000)
