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
            <name of the unit>: <count>
            ...
        }
    }

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
            <name of the unit>: [
                <rank>,
                <length of the move>,
                <min count>,
                <max count>
            ],
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

## Living the game
### Request
    {
        "cmd": "liveGame"
    }
### Response
    {
        "status": "ok"
    }
### Response for second player
    {
        "cmd": "endGame"
    }

<!-- New cmds -->

## Getting state of the game
    {
        "cmd": "getGame"
    }
### Response1
    {
        "status": "ok",
        "game_status": "placement"
        "game_name": <name of the game>,
        "players": [...],
        "map": {
            "name": <name of the map>,
            "width": <width of the map>,
            "height": <height of the map>,
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
### Response2
    {
        "status": "ok",
        "game_status": "process",
        "game_name": <name of the game>,
        "players": [...],
        "isTurn": <is your turn>,
        "map_name": <name of the map>,
        "army_name": <name of the army>,
        "map_width": <width of the map>,
        "map_height": <height of the map>
        "state": {
            "obst": [...],
            "pl1": {
                <position>: <name of the unit>
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
    }
### Response1 for other player
    {
        "cmd": "opponentReady"
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
        "cell": <content of the cell>,
        "duel": {                         //Optional
            "res": <result of the duel>,
            "attacker": <attacker unit>,
            "protector": <protector unit>,
        }
    }
### Response for other player
    {
        "cmd": "duel",
        "posFrom": <position from>,
        "posTo": <position to>,
        "duel": {                         //Optional
            "res": <result of the duel>,
            "attacker": <attacker unit>,
            "protector": <protector unit>,
        }
    }

