# Description:
#   Interact with Leankit.com
#
# Dependencies:
#   leankit-client
#
# Configuration:
#   LK_USERNAME
#   LK_PASSWORD
#   LK_ACCOUNTNAME
#
# Commands:
#   lk card me <description> - Add a new card with a basic description
#   lk board <name> - Query board by Name
#   lk boards - List of available boards

#
# Author:
#   Adam Stokes <adam.stokes@ubuntu.com>

lk = require 'leankit-client'

class LeanKit
  constructor: (@robot) ->
    unless process.env.LK_USERNAME?
      return @robot.logger.error "LK_USERNAME env var not set."
    unless process.env.LK_PASSWORD?
      return @robot.logger.error "LK_PASSWORD env var not set."
    unless process.env.LK_ACCOUNTNAME?
      return @robot.logger.error "LK_ACCOUNTNAME env var not set."

    @client = lk.newClient(process.env.LK_ACCOUNTNAME,
                          process.env.LK_USERNAME,
                          process.env.LK_PASSWORD)
    @robot.respond /lk card me (\d+) (.*)/i, @addCard
    @robot.respond /lk boards/i, @listBoards
    @robot.respond /lk board (.*)/i, @listBoardByName
    @robot.respond /lk help/i, @help

  help: (msg) =>
    commands = @robot.helpCommands()
    commands = (command for command in commands when command.match(/lk/))
    msg.send commands.join("\n")

  addCard: (msg) =>
    user = msg.message.user
    description = msg.match[1]
    msg.send "Card added, yo."

  listBoardByName: (msg) =>
    user = msg.message.user
    boardName = msg.match[1]
    @client.getBoardByName boardName, (err, res) ->
      board = res
      if res?
        msg.send "Board: #{board.Id} - #{board.Title}"
      else
        msg.send "Could not find board #{boardName}"

  listBoards: (msg) =>
    user = msg.message.user
    @client.getBoards (err, res) ->
      for item in res
        if item.Title.match(/^Solutions/)
          msg.send "Board: #{item.Id} - #{item.Title}"

module.exports = (robot) -> new LeanKit(robot)
