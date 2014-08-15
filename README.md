hubot-leankit
=============

LeanKit interaction for Hubot

### Configuration:

    LEANKIT_EMAIL
    LEANKIT_PASSWORD
    LEANKIT_ACCOUNT

### Commands:

    !lk-set-default <boardId> - Set default board
    !lk-get-default - Get saved default board
    !lk-unset-default - Clear default board
    !lk-add-card <boardId> <description> - Add a new card to the default lane.
    !lk-del-card <boardId> <cardId> - Delete a card.
    !lk-search <boardId> <query> - Search board
    !lk-board <name> - Query board by Name
    !lk-boards <query> - List of available boards, optional: <query>
