# Description:
#   Interact with Leankit.com
#
# Dependencies:
#   leankit-client
#
# Configuration:
#   LEANKIT_EMAIL
#   LEANKIT_PASSWORD
#   LEANKIT_ACCOUNT
#
# Commands:
#   hubot lk add <boardIdx> <description> - Add a new card to the default ToDo lane
#   hubot lk board <name> - Query board by Name
#   hubot lk boards - List of available boards, shows boardIdx, Title
#   hubot lk add-boards - Populate boards into db
#
# Notes:
#    * Populate your boards into redis with add-boards, then reference your
#      board with the index given from `lk boards`
#
# Author:
#   Adam Stokes <adam.stokes@ubuntu.com>

lk = require 'leankit-client'
_  = require 'lodash'

module.exports = (robot) ->
  unless process.env.LEANKIT_EMAIL?
    return @robot.logger.error "LEANKIT_EMAIL env var not set."
  unless process.env.LEANKIT_PASSWORD?
    return @robot.logger.error "LEANKIT_PASSWORD env var not set."
  unless process.env.LEANKIT_ACCOUNT?
    return @robot.logger.error "LEANKIT_ACCOUNT env var not set."

  client = lk.newClient(process.env.LEANKIT_ACCOUNT,
                        process.env.LEANKIT_EMAIL,
                        process.env.LEANKIT_PASSWORD)

  robot.brain.data.lkboards = {}

  robot.respond /lk add (\d+) (.*)/i, (msg) ->
    user = msg.message.user
    boardId = msg.match[1]
    title = msg.match[2]
    board = robot.brain.data.lkboards[boardId]
    client.getBoardByName board, (err, b) ->
      if b?
        now = new Date()
        cardType = _.find(b.CardTypes, 'IsDefault': true)
        lane = _.find(b.Lanes, 'IsDefaultDropLane': true)
        newCard = {}
        newCard.TypeId = cardType.Id
        newCard.Title = title
        newCard.ExternalCardId = now.getTime()
        newCard.Priority = 1
        client.addCard b.Id, lane.Id, 0, newCard, (err, res) ->
          if res?
            msg.send "Added card(#{res.CardId}): #{title} to " +
                     "#{b.Title}/#{lane.Title}."
          else
            msg.send "Unable to add card to Board"

  robot.respond /lk add-boards/i, (msg) ->
    user = msg.message.user
    idx = 0
    client.getBoards (err, res) ->
      for item in res
        if item.Title.match(/^Solutions/)
          robot.brain.data.lkboards[idx] = item.Title
          idx += 1
      msg.send "Added #{idx} board(s) to BRaiN"

  robot.respond /lk boards/i, (msg) ->
    user = msg.message.user
    for k,v of robot.brain.data.lkboards
      msg.send "Board[#{k}] -> #{v}"

  robot.respond /lk board (.*)/i, (msg) ->
    user = msg.message.user
    boardName = msg.match[1]
    client.getBoardByName boardName, (err, res) ->
      board = res
      if res?
        msg.send "Board: #{board.Id} - #{board.Title}"
      else
        msg.send "Could not find board #{boardName}"

  robot.respond /lk help/i, (msg) ->
    commands = robot.helpCommands()
    commands = (command for command in commands when command.match(/lk/))
    msg.send commands.join("\n")
