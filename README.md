hubot-leankit
=============

LeanKit interaction for Hubot

### Configuration:

    LEANKIT_EMAIL
    LEANKIT_PASSWORD
    LEANKIT_ACCOUNT

### Commands:

    leankit add default <boardId> - Set default board
    leankit show default - Get saved default board
    leankit rm default - Clear default board
    leankit add card <boardId> <description> - Add a new card to the default lane.
    leankit rm card <boardId> <cardId> - Delete a card.
    leankit search <boardId> <query> - Search board
    leankit board <name> - Query board by Name
    leankit boards <query> - List of available boards, optional: <query>
    leankit help - See a list of the available commands
