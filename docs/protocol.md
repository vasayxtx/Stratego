#Basic commands

<!-- Auth -->

## Signup
### Request
    {
        "cmd": "signup",
        "login": <login>,
        "password": <password>
    }    
### Response
    {
        "status": "ok",
        "sid": <sid>,
        "login": <login in the db>
    }
### Response for other clients
    {
        "cmd": "addUserOnline", 
        "login": <login of user>
    }

## Login
### Request
    {
        "cmd": "login",
        "login": <login>,
        "password": <password>
    }    
### Response
    {
        "status": "ok",
        "sid": <sid>,
        "login": <login in the db>
    }
### Response for other clients
    {
        "cmd": "addUserOnline", 
        "login": <login of user>
    }

## Logout
### Request
    {
        "cmd": "logout",
        "sid": <sid>
    }    
### Response
    {
        "status": "ok"
    }
### Response for other clients
    {
        "cmd": "delUserOnline", 
        "login": <login of user>
    }

## Checking sid
### Request
    {
        "cmd": "checkSid"
        "sid": <sid>
    }
### Response
    {
        "status": "ok"
    }

## Getting online users
### Request
    {
        "cmd": "getUsersOnline"
        "sid": <sid>
    }
### Response
    {
        "status": "ok",
        "users": [...]
    }

<!-- Maps -->

## Creation of the map
### Request
    {
        "cmd": "createMap",
        "sid": <sid>,
        "name": <name of the map>,
        "width": <width of the map>,
        "height": <height of the map>,
        "structure": {
            "obst": [...],
            "pl1": [...],
            "pl2": [...]
        }
    }    
### Response
    {
        "status": "ok"
    }

## Editing of the map
### Request
    {
        "cmd": "editMap",
        "sid": <sid>,
        "name": <name of the map>,
        "width": <width of the map>,
        "height": <height of the map>,
        "structure": {
            "obst": [...],
            "pl1": [...],
            "pl2": [...]
        }
    }
### Response
    {
        "status": "ok"
    }

## Destruction of the map
### Request
    {
        "cmd": "destroyMap",
        "sid": <sid>,
        "name": <name of the map>,
    }
### Response
    {
        "status": "ok"
    }

## Getting a list of all maps
### Request
    {
        "cmd": "getListAllMaps",
        "sid": <sid>
    }
### Response
    {
        "status": "ok",
        "maps": [...]
    }

## Getting a list of the maps created by current user's
### Request
    {
        "cmd": "getListMaps",
        "sid": <sid>
    }
### Response
    {
        "status": "ok",
        "maps": [...]
    }

## Getting params of the map
### Request
    {
        "cmd": "getMapParams",
        "sid": <sid>,
        "name": <name of the map>
    }
### Response
    {
        "status": "ok",
        "width": <width of the map>,
        "height": <height of the map>,
        "structure": {
            "obst": [...],
            "pl1": [...],
            "pl2": [...],
        }
    }

<!-- Armies -->

## Creation of the army
### Request
    {
        "cmd": "createArmy",
        "sid": <sid>,
        "name": <name of the army>,
        "units": {
            <name of the unit>: <count>
            ...
        }
    }    
### Response
    {
        "status": "ok"
    }

## Editing of the army
### Request
    {
        "cmd": "editArmy",
        "sid": <sid>,
        "name": <name of the army>,
        "units": {
            <name of the unit>: <count>
            ...
        }
    }    
### Response
    {
        "status": "ok"
    }

## Destruction of the army
### Request
    {
        "cmd": "destroyArmy",
        "sid": <sid>,
        "name": <name of the army>
    }
### Response
    {
        "status": "ok"
    }

## Getting a list of all armies
### Request
    {
        "cmd": "getListAllArmies",
        "sid": <sid>
    }
### Response
    {
        "status": "ok",
        "armies": [...]
    }

## Getting a list of the armies created by current user's
### Request
    {
        "cmd": "getListArmies",
        "sid": <sid>
    }
### Response
    {
        "status": "ok",
        "maps": [...]
    }

## Getting units of the army
### Request
    {
        "cmd": "getArmyUnits",
        "sid": <sid>,
        "name": <name of the army>
    }
### Response
    {
        "status": "ok",
        "units": {
            <name of the unit>: {
                "count": <count>,
                "minCount": <min count>,
                "maxCount": <max count>,
                "moveLength": <move of the length>
            },
            ...
        }
    }

<!-- Tacktics -->

## Creation of the tactic
### Request
    {
        "cmd": "createTactic",
        "sid": <sid>,
        "name": <name of the tactic>,
        "nameMap": <name of the map>,
        "nameArmy": <name of the army>,
        "placement": {
            "pl1": {
                <position>: <name of the unit>,
                ...
            },
            "pl2": {
                <position>: <name of the unit>,
                ...
            }
        }
    }
### Response
    {
        "status": "ok",
    }

## Getting tactics for player in the game
### Request
    {
        "cmd": "getGameTactics",
        "sid": <sid>,
    }
### Response
    {
        "status": "ok",
        "tactics": {
            <tactic name>: {
                <position>: <name of the unit>,
                ...
            }
        }
    }

<!-- Units -->

## Getting all units
### Request
    {
        "cmd": "getAllUnits"
        "sid": <sid>
    }
### Response
    {
        "status": "ok",
        "units": {
            <name of the unit>: {
                "minCount": <min count>,
                "maxCount": <max count>
                "moveLength": <length of the move>,
                "rank": <rank>,
            },
            ...
        }
    }

<!-- Games -->

## Creation of the game
### Request
    {
        "cmd": "createGame",
        "name": <name of the game>,
        "nameMap": <name of the map>,
        "nameArmy": <name of the army>
    }
### Response
    {
        "status": "ok"
    }
### Response for other clients
    {
        "cmd": "addAvailableGame", 
        "name": <name of the game>
    }

## Getting params of the game
### Request
    {
        "cmd": "getGameParams",
        "name": <name of the game>
    }
### Response
    {
        "status": "ok",
        "map": {
            "name": <name of the map>,
            "width": <width of the map>,
            "hegiht": <height of the map>,
            "structure": {
              "obst": [...],
              "pl1": [...],
              "pl2": [...]
            }
        },
        "army": {
            "name": <name of the map>,
            "units": {
                <name of the unit>: <count>
                ...
            }
        }
    }

## Getting available games
### Request
    {
        "cmd": "getAvailableGames"
    }
### Response
    {
        "status": "ok",
        "games": [...]
    }

## Join to the game
### Request
    {
        "cmd": "joinGame",
        "name": <name of the game>
    }
### Response
    {
        "status": "ok"
    }
### Response for creator
    {
        "cmd": "startGamePlacement"
    }
### Response for other clients
    {
        "cmd": "delAvailableGame", 
        "name": <name of the game>
    }

## Destruction of the game
### Request
    {
        "cmd": "destroyGame"
    }
### Response
    {
        "status": "ok"
    }
### Response for other clients
    {
        "cmd": "delAvailableGame", 
        "name": <name of the game>
    }

## Leaving the game
### Request
    {
        "cmd": "leaveGame"
    }
### Response
    {
        "status": "ok"
    }
### Response for second player
    {
        "cmd": "endGame"
    }

## Getting state of the game
    {
        "cmd": "getGame"
    }
### Response
    {
        "status": "ok",
        "game_name": <name of the game>,
        "players": [...],
        "isTurn": <is your turn[true or false]>,  //Optional (if game started)
        "map": {
            "name": <name of the map>,
            "width": <width of the map>,
            "height": <height of the map>,
            "obst": [...]
        },
        "army": {
            "name": <name of the map>,
            "units": {
                <name of the unit>: {
                    count: <count>,
                    moveLenght: <lenght of the move>
                },
                ...
            }
        },
        "state": {
            "pl1": {                            //"pl1": [...] - if not placed
                <position>: <name of the unit>,
                ...
            },
            "pl2": [...]
        }
    }

## Setting placement
### Request
    {
        "cmd": "setPlacement",
        "placement": {
            <position>: <name of the unit>
        }
    }
### Response
    {
        "status": "ok",
        "isGameStarted": <is game started [true or false]>
    }
### Response1 for other player
    {
        "cmd": "readyOpponent"
    }
### Response2 for other player
    {
        "cmd": "startGame"
    }

## Making a move
### Request
    {
        "cmd": "makeMove",
        "posFrom": <position from>,
        "posTo": <position to>
    }
### Response
    {
        "status": "ok",
        "duel": {                       //Optional
            "result": <result of the duel (win, loss, draw)>,
            "attacker": <attacker unit>,
            "protector": <protector unit>,
        },
        "isEnd": true                   //Optional
    }
### Response for other player
    {
        "cmd": "opponentMakeMove",
        "posFrom": <position from>,
        "posTo": <position to>,
        "duel": {                       //Optional
            "result": <result of the duel (win, loss, draw)>,
            "attacker": <attacker unit>,
            "protector": <protector unit>,
        },
        "isEnd": true                   //Optional
    }

