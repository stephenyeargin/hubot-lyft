# Description:
#   List estimated arrival times and available Lyft services.
#
# Dependencies:
#   cli-table
#   moment
#
# Configuration:
#   HUBOT_LYFT_CLIENT_TOKEN - client OAuth2 token from https://www.lyft.com/developers/manage
#   HUBOT_LYFT_DEFAULT_LATITUDE - Default latitude for your queries
#   HUBOT_LYFT_DEFAULT_LONGITUDE - Default longitude for your queries
#
# Commands:
#   hubot lyft - Get products and estimated time to arrival
#
# Author:
#   stephenyeargin

moment = require 'moment'
_ = require 'underscore'
formatCurrency = require 'format-currency'

module.exports = (robot) ->
  # Warn on initialization if missing setting
  unless process.env.HUBOT_LYFT_CLIENT_TOKEN
    robot.logger.warning 'HUBOT_LYFT_CLIENT_TOKEN missing! See README for help'

  # Location default for the bot, default to Nashville :-)
  default_latitude = process.env.HUBOT_LYFT_DEFAULT_LATITUDE || 36.1627
  default_longitude = process.env.HUBOT_LYFT_DEFAULT_LONGITUDE || -86.7816

  ##
  # Get JSON response
  makeApiCall = (path, params) ->
    robot.logger.debug 'API path', path
    robot.logger.debug 'API params', params
    return new Promise (resolve, reject) ->
      robot.http("https://api.lyft.com/v1#{path}").headers(
        Authorization: "Bearer #{process.env.HUBOT_LYFT_CLIENT_TOKEN}"
      ).query(params).get() (err, res, body) ->
        if err
          reject(err)
        else
          resolve(JSON.parse(body))

  ##
  # Respond to default route
  robot.respond /lyft$/i, (msg) ->
    location = {lat: default_latitude, lng: default_longitude}
    makeApiCall('/ridetypes', location)
    .then (response) ->
      robot.logger.debug '/ridetypes response', response
      # Handle if error retrieving data
      return msg.send response.error_description if response.error
      # Make it easier to look up later
      ride_types = {}
      _(response.ride_types).each (rt, i) ->
        ride_types[rt.ride_type] = rt
      robot.logger.debug 'ride_types storage', ride_types

      # Now grab ETAs
      makeApiCall('/eta', location)
      .then (response) ->
        robot.logger.debug '/eta response', response
        payload = []
        _(response.eta_estimates).each (row, i) ->
          # Format ETA
          eta = moment.duration(row.eta_seconds * 1000).minutes()
          # Format Currency
          symbol = if ride_types[row.ride_type].pricing_details.currency == 'USD' then '$' else ride_types[row.ride_type].pricing_details.currency
          currencyOpts = symbol: symbol, format: "%s%v"
          ride_type = ride_types[row.ride_type]
          pricing_details = ride_types[row.ride_type].pricing_details
          chunk = {
            fallback: "#{row.display_name}: Seats #{ride_type.seats}, arrives in #{eta} minute(s)"
            title: row.display_name,
            thumb_url: ride_type.image_url,
            color: '#FF00BF',
            fields: [
              {
                title: 'Arrives'
                value: "#{eta} minute(s)",
                short: true
              },
              {
                title: 'Seats'
                value: ride_type.seats,
                short: true
              },
              {
                title: 'Base Charge',
                value: formatCurrency(pricing_details.base_charge/100, currencyOpts),
                short: true
              },
              {
                title: 'Cost per Mile',
                value: formatCurrency(pricing_details.cost_per_mile/100, currencyOpts),
                short: true
              },
              {
                title: 'Cost per Minute',
                value: formatCurrency(pricing_details.cost_per_minute/100, currencyOpts),
                short: true
              },
              {
                title: 'Trust & Service Fee',
                value: formatCurrency(pricing_details.trust_and_service/100, currencyOpts),
                short: true
              },
              {
                title: 'Cancel Penalty',
                value: formatCurrency(pricing_details.cancel_penalty_amount/100, currencyOpts),
                short: true
              },
            ]
          }

          switch robot.adapterName
            when 'slack'
              payload.push chunk
            else
              msg.send chunk.fallback

        # Send Payload
        if payload.length > 0
          msg.send { attachments: payload }


      # Inner Error Catch
      .catch (error) ->
        msg.send error
    # Outer Error Catch
    .catch (error) ->
      msg.send error
