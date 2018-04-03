Helper = require 'hubot-test-helper'
chai = require 'chai'
nock = require 'nock'
fs = require 'fs'

expect = chai.expect

helper = new Helper [
  'adapters/slack.coffee',
  '../src/lyft.coffee'
]

# Alter time as test runs
originalDateNow = Date.now
mockDateNow = () ->
  return Date.parse('Tue Mar 06 2018 23:01:27 GMT-0600 (CST)')

describe 'hubot-lyft for slack', ->
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
          [
            'hubot'
            {
              "attachments": [
                {
                  "color": "#FF00BF",
                  "fallback": "Lyft Line: Seats 2, arrives in 2 minute(s)",
                  "fields": [
                    {
                      "short": true,
                      "title": "Arrives",
                      "value": "2 minute(s)"
                    },
                    {
                      "short": true,
                      "title": "Seats",
                      "value": 2
                    },
                    {
                      "short": true,
                      "title": "Base Charge",
                      "value": "$2.00"
                    },
                    {
                      "short": true,
                      "title": "Cost per Mile",
                      "value": "$1.15"
                    },
                    {
                      "short": true,
                      "title": "Cost per Minute",
                      "value": "$0.23"
                    },
                    {
                      "short": true,
                      "title": "Trust & Service Fee",
                      "value": "$1.55"
                    },
                    {
                      "short": true,
                      "title": "Cancel Penalty",
                      "value": "$5.00"
                    }
                  ],
                  "thumb_url": "https://s3.amazonaws.com/api.lyft.com/assets/car_standard.png",
                  "title": "Lyft Line"
                },
                {
                  "color": "#FF00BF",
                  "fallback": "Lyft: Seats 4, arrives in 2 minute(s)",
                  "fields": [
                    {
                      "short": true,
                      "title": "Arrives",
                      "value": "2 minute(s)"
                    },
                    {
                      "short": true,
                      "title": "Seats",
                      "value": 4
                    },
                    {
                      "short": true,
                      "title": "Base Charge",
                      "value": "$2.00"
                    },
                    {
                      "short": true,
                      "title": "Cost per Mile",
                      "value": "$1.15"
                    },
                    {
                      "short": true,
                      "title": "Cost per Minute",
                      "value": "$0.23"
                    },
                    {
                      "short": true,
                      "title": "Trust & Service Fee",
                      "value": "$1.55"
                    },
                    {
                      "short": true,
                      "title": "Cancel Penalty",
                      "value": "$5.00"
                    }
                  ],
                  "thumb_url": "https://s3.amazonaws.com/api.lyft.com/assets/car_standard.png",
                  "title": "Lyft"
                },
                {
                  "color": "#FF00BF",
                  "fallback": "Lyft Plus: Seats 6, arrives in 11 minute(s)",
                  "fields": [
                    {
                      "short": true,
                      "title": "Arrives",
                      "value": "11 minute(s)"
                    },
                    {
                      "short": true,
                      "title": "Seats",
                      "value": 6
                    },
                    {
                      "short": true,
                      "title": "Base Charge",
                      "value": "$3.00"
                    },
                    {
                      "short": true,
                      "title": "Cost per Mile",
                      "value": "$2.00"
                    },
                    {
                      "short": true,
                      "title": "Cost per Minute",
                      "value": "$0.30"
                    },
                    {
                      "short": true,
                      "title": "Trust & Service Fee",
                      "value": "$1.55"
                    },
                    {
                      "short": true,
                      "title": "Cancel Penalty",
                      "value": "$5.00"
                    }
                  ],
                  "thumb_url": "https://s3.amazonaws.com/api.lyft.com/assets/car_plus.png",
                  "title": "Lyft Plus"
                }
              ]
            }
          ]
        ]
        done()
      catch err
        done err
      return
    , 1000)
