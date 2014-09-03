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
#   leankit add default <boardId> - Set default board
#   leankit show default - Get saved default board
#   leankit rm default - Clear default board
#   leankit add card <boardId> <description> - Add a new card to the default lane.
#   leankit rm card <boardId> <cardId> - Delete a card.
#   leankit search <boardId> <query> - Search board
#   leankit board <name> - Query board by Name
#   leankit boards <query> - List of available boards, optional: <query>
#   leankit help - See a list of the available commands
#
# Notes:
#    * Populate your boards into redis with !lk-store-boards, then reference
#      your board with the index given from `lk boards`
#    * Specifying the boardId is required unless you set a default board with
#      !lk-set-default <boardId>
#    * boardId is always required when deleting a card.
#
# Author:
#   Adam Stokes <adam.stokes@ubuntu.com>

lk = require 'leankit-client'
_  = require 'lodash'

module.exports = (robot) ->
  unless process.env.LEANKIT_EMAIL?
    return robot.logger.error "LEANKIT_EMAIL env var not set."
  unless process.env.LEANKIT_PASSWORD?
    return robot.logger.error "LEANKIT_PASSWORD env var not set."
  unless process.env.LEANKIT_ACCOUNT?
    return robot.logger.error "LEANKIT_ACCOUNT env var not set."

  client = lk.newClient(process.env.LEANKIT_ACCOUNT,
                        process.env.LEANKIT_EMAIL,
                        process.env.LEANKIT_PASSWORD)

  robot.hear /^leankit search\s+(\d+)?\s*(.*)$/i, (msg) ->
    boardId = msg.match[1]

    if not boardId?
      if robot.brain.data.lkboard?
        boardId = robot.brain.data.lkboard.Id
      else
        return msg.send "No boardId found and no default board set."

    query = msg.match[2]
    searchOpts = {
      SearchTerm: query,
      SearchInBacklog: false,
      SearchInRecentArchive: false,
      SearchInOldArchive: false,
      SearchAllBoards: false,
      IncludeTaskboards: false,
      IncludeComments: false,
      IncludeDescription: true,
      IncludeExternalId: false,
      IncludeTags: false,
      AddedAfter: null,
      AddedBefore: null,
      Page: 1
      MaxResults: 4,  # Dont spam
      OrderBy: "CreatedOn",
      SortOrder: 1
    }

    client.searchCards boardId, searchOpts, (err, res) ->
      unless res.Results.length > 0
        return msg.send "No results found."
      for card in res.Results
        assignedUser = card.AssignedUserName
        unless !!assignedUser
          assignedUser = "Unassigned"

        msg.send "(#{card.Id}|#{card.PriorityText}|#{card.CreateDate}"+
                 "|#{assignedUser}) #{card.Title}"

  robot.hear /^leankit add default (\d+)/, (msg) ->
    boardId = msg.match[1]
    client.getBoard boardId, (err, b) ->
      if b and b.ReplyCode == 503
        return msg.send "Unable to find board with id #{boardId}"
      else
        robot.brain.data.lkboard = b
        return msg.send "#{b.Title} set as default board."

  robot.hear /^leankit rm default/, (msg) ->
    if robot.brain.data.lkboard?
      robot.brain.data.lkboard = undefined
    msg.send "Unset default board."

  robot.hear /^leankit show default/, (msg) ->
    if robot.brain.data.lkboard?
      board = robot.brain.data.lkboard
      msg.send "(#{board.Id}) #{board.Title} is the default board."
    else
      msg.send "No default board is set."

  robot.hear /^leankit rm card\s+(\d+)\s+(\d+)\s*(srsly)?/, (msg) ->
    user = msg.message.user
    boardId = msg.match[1]
    cardId = msg.match[2]
    isSerious = msg.match[3]
    if not isSerious?
      return msg.reply "I don't trust you, add 'srsly' to the end if you " +
                       "really wanted this."
    client.deleteCard boardId, cardId, (err, res) ->
      msg.send "#{cardId} deleted."

  robot.hear /^leankit add card\s+(\d+)?\s*(.*)$/i, (msg) ->
    user = msg.message.user
    boardId = msg.match[1]
    title = msg.match[2]

    if not boardId?
      if robot.brain.data.lkboard?
        boardId = robot.brain.data.lkboard.Id
      else
        return msg.send "No boardId found and no default board set."

    client.getBoard boardId, (err, b) ->
      if b and b.ReplyCode == 503
        return msg.send "Unable to find board with id #{boardId}"

      if b?
        now = new Date()
        cardType = _.find(b.CardTypes, 'IsDefault': true)

        lane = _.find(b.Lanes, 'IsDefaultDropLane': true)
        if not lane?
          lane = _.first(b.Backlog)

        newCard = {}
        newCard.TypeId = cardType.Id
        newCard.Title = title
        newCard.ExternalCardId = now.getTime()
        newCard.Priority = 1

        client.addCard b.Id, lane.Id, 0, newCard, (err, res) ->
          if res?
            return msg.send "Added card(#{res.CardId}): #{title} to " +
                            "#{b.Title}/#{lane.Title}."
          else
            return msg.send "Unable to add card to Board"
      else
        return msg.send "Unable to find board with id #{boardId}"

  robot.hear /^leankit boards\s+(.*)/i, (msg) ->
    user = msg.message.user
    fuzz = new RegExp "#{msg.match[1]}"
    client.getBoards (err, res) ->
      unless res.length > 0
        return msg.send "No boards found."
      for item in res
        if item.Title.match(fuzz)
          msg.send "(#{item.Id}) #{item.Title}"

  robot.hear /^leankit board (.*)/i, (msg) ->
    user = msg.message.user
    boardName = msg.match[1]
    client.getBoardByName boardName, (err, res) ->
      board = res
      if res?
        msg.send "Board: #{board.Id} - #{board.Title}"
      else
        msg.send "Could not find board #{boardName}"

  robot.hear /^leankit help/i, (msg) ->
    commands = robot.helpCommands()
    commands = (command for command in commands when command.match(/lk/))
    msg.send commands.join("\n")
