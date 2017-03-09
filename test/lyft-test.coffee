Helper = require 'hubot-test-helper'
chai = require 'chai'
nock = require 'nock'
fs = require 'fs'

expect = chai.expect

helper = new Helper('../src/lyft.coffee')

describe 'lyft', ->
  beforeEach ->
    process.env.HUBOT_LYFT_DEFAULT_LONGITUDE = '-86.000'
    process.env.HUBOT_LYFT_DEFAULT_LATITUDE = '36.000'
    process.env.HUBOT_LYFT_CLIENT_TOKEN = 'foobarbaz'

    @room = helper.createRoom()

    do nock.disableNetConnect
    options =
      reqheaders:
        authorization: "Bearer foobarbaz"
    nock('https://api.lyft.com', options)
      .get('/v1/ridetypes?lat=36.000&lng=-86.000')
      .reply 200, fs.readFileSync('test/fixtures/ridetypes.json')
    nock('https://api.lyft.com', options)
      .get('/v1/eta?lat=36.000&lng=-86.000')
      .reply 200, fs.readFileSync('test/fixtures/eta.json')

  afterEach ->
    @room.destroy()
    nock.cleanAll()

  it 'responds to lyft', (done) ->
    selfRoom = @room
    testPromise = new Promise (resolve, reject) ->
      selfRoom.user.say('alice', '@hubot lyft')
      setTimeout(() ->
        resolve()
      , 200)

    testPromise.then ((result) ->
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
    ), done
