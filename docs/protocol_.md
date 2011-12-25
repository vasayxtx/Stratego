# Description of the game protocol

## Status of server response

## OK
With value "ok" and all necessary data after it.

    { 
        "status": "ok", 
        ... 
    }
    
## Bad Request 
This is an error response, and have a meaning of syntax error in JSON query parsing.

    { 
        "status": "badRequest", 
        "message": <description> 
    }

## Bad Command 
This error appears when command is incorrect, unknown, don't have enough fields for command or
have extra fields, that don't required by command. Also may be used for error reporting when other
error statuses can't be used.

    { 
        "status": "badCommand", 
        "message": <description> 
    }

#Basic commands

## Signup
#### *Request*
    {
        "cmd": "signup",
        "login": <login>,
        "password": <password>
    }    
#### *Response*
    {
        "status": "OK",
        "sid": <sid>
    }
### Bayeux:
#### *Response to URL 'usersonline'*
    {
        "cmd": "add", 
        "login": <login of user>
    }


## Login
#### *Request*
    {
        "cmd": "login",
        "login": <login>,
        "password": <password>
    }
#### *Response*
    {
        "status": "OK",
        "sid": <sid>
    }
### Bayeux:
#### *Response to URL 'usersonline'*
    {
        "cmd": "add", 
        "login": <login of user>
    }
#### *Response to URL 'availablegames'*
    {
      "cmd": "add",
      "game": <name of the game>
    }
**Notes:** 

+ If user has game with status 'creation'


## Logout
#### *Request*
    {
        "cmd": "logout",
        "sid": <sid>
    }
#### *Response*
    {
        "status": "OK"
    }
### Bayeux:
#### *Response to URL 'availablegames'*
    {
        "cmd": "remove",
        "game": <name of the game>
    }
**Notes:** 

+ If came out from the system user has the game with status 'creation'

#### *Response to URL 'availablegames'*
    {
        "cmd": "add",
        "game": <name of the game>
    }
**Notes:** 

+ If came out from the system user was playing a game, and the second player has a game with status 'creation'

#### *Response to URL 'game/\<Name of the game\>/status'*
    {
        "cmd": "changeStatus",
        "status": "leaving"
    }
**Notes:** 

+ If came out from the system user was playing a game


## Getting login name by sid
#### *Request*
    {
        "cmd": "getLogin",
        "sid": <sid>
    }
#### *Response*
    {
        "status": "OK",
        "login": <login>
    }


## Getting list of online users
#### *Request*
    {
        "cmd": "getListUsersOnline",
        "sid": <sid>
    }
#### *Response*
    {
        "status": "OK",
        "users": [
            { "login": <login> },
            ...
        ]
    }


## Getting list of available games
#### *Request*
    {
        "cmd": "getListAvailableGames",
        "sid": <sid>
    }
#### *Response*
    {
        "status": "OK",
        "games": [
            { "nameGame": <name of the game> },
            ...
        ]
    }


## Getting game, created by user and which has status 'creation'
#### *Request*
    {
        "cmd": "getCreatedGame",
        "sid": <sid>
    }
#### *Response*
    {
        "status": "OK",
        "game": <name of the game>
    }



## Getting game, which has status 'placement\running'
#### *Request*
    {
        "cmd": "getStartedGame",
        "sid": <sid>
    }
#### *Response*
    {
        "status": "OK",
        "game": <name of the game>
    }


## Creation a game
#### *Request*
    {
        "cmd": "createGame",
        "sid": <sid>,
        "nameGame": <name of the map>,
        "nameMap": <name of the map>,
        "nameArmy": <name of the army>
    }
#### *Response*
    { "status": "OK" }
### Bayeux:
#### *Response to URL 'availablegames'*
    {
        "cmd": "add",
        "game": <name of the game>
    }


## Getting list of all games
#### *Request*
    {
        "cmd": "getListGames",
        "sid": <sid>
    }
#### *Response*
    {
        "status": "OK",
        "games": [
            {
                "nameGame": <name of the game>,
            }
        ]
    }


## Getting params of a game
#### *Request*
    {
        "cmd": "getGameParams",
        "sid": <sid>,
        "nameGame": <name of the game>
    }
#### *Response*
    {
        "status": "OK",
        "nameMap": <name of the game>,
        "nameArmy": <name of the army>,
        "creatorLogin": <login user who created the game>
    }


## Joining to the game
#### *Request*
    {
        "cmd": "joinGame",
        "sid": <sid>,
        "nameGame": <name of the game>
    }
#### *Response*
    { "status": "OK" }
### Bayeux:
#### *Response to URL 'availablegames'*
    {
        "cmd": "remove",
        "game": <name of the game>
    }
**Notes:** 

+ Remove game from list of available games, created (with 'creation' status) by user. If it exists

#### *Response to URL 'availablegames'*
    {
        "cmd": "remove",
        "game": <name of the game>
    }
**Notes:** 

+ Remove joined game from list of available games

#### *Response to URL 'game/\<name of the game\>/status'*
    {
        "cmd": "changeStatus",
        "status": "placement"
    }
**Notes:** 

+ Set status of the game in 'placement'


## Leaving the game
#### *Request*
    {
        "cmd": "leaveGame",
        "sid": <sid>,
        "game": "nameGame"
    }
#### *Response*
    { "status": "OK" }
### Bayeux:
#### *Response to URL 'availablegames'*
    {
        "cmd": "add",
        "game": <name of the game>
    }
**Notes:** 

+ Add game to list of available games, created (with 'creation' status) by user. If it exists

#### *Response to URL 'game/\<name of the game\>/status'*
    {
        "cmd": "changeStatus",
        "status": "leaving"
    }
**Notes:** 

+ Set status of the game in 'leaving'


## Destruction game
#### *Request*
    {
        "cmd": "destroyGame",
        "sid": <sid>,
        "game": "nameGame"
    }
#### *Response*
    { "status": "OK" }
### Bayeux:
#### *Response to URL 'availablegames'*
    {
        "cmd": "remove",
        "game": <name of the game>
    }
**Notes:** 

+ Remove game from list of available games


## Creation map
#### *Request*
    {
        "cmd": "createMap",
        "sid": <sid>,
        "nameMap": <name of the map>,
        "width": <width of the map>,
        "height": <height of the map>,
        "structure": <string representing a structure of the map>
    }
#### *Response*
    { "status": "OK" }

**Notes:** 

* Values for height and width of map are in range from the 5 to 100 inclusive.
* Structure of map is given by the string (with length is equal to width * height) that represents the character sequence of: 
  + [ascii - 32] - the cell is available for game move;
  + [ascii - 33] - the cell is available for placement to the first player;
  + [ascii - 34] - the cell is available for placement to the second player;
  + [ascii - 35] - the cell is not available.


## Editing map 
#### *Request*
    {
        "cmd": "editMap",
        "sid": <sid>,
        "nameMap": <name of the map>,
        "width": <width of the map>,
        "height": <height of the map>,
        "structure": <string representing a structure of the map>
    }
#### *Response*
    { "status": "OK" }


## Destruction map
#### *Request*
    {
        "cmd": "destroyMap",
        "sid": <sid>,
        "nameMap": <name of the map>
    }
#### *Response*
    { "status": "OK" }


## Getting list of all maps
#### *Request*
    {
        "cmd": "getListAllMaps",
        "sid": <sid>
    }
#### *Response*
    {
        "status": "OK",
        "maps": [
            { "nameMap": <name of the map> },
            ...
        ]
    }


## Getting list of maps, designed by current user
#### *Request*
    {
        "cmd": "getListMaps",
        "sid": <sid>
    }
#### *Response*
    {
        "status": "OK",
        "maps": [
            { "nameMap": <name of the map> },
            ...
        ]
    }


## Creation army
#### *Request*
    {
        "cmd": "createArmy",
        "sid": <sid>,
        "nameArmy": <name of the army>,
        "units": [
            {
                "nameUnit": <name of the unit>,
                "count": <count of units>
            }
        ]
    }
#### *Response*
    { "status": "OK" }


## Editing army
#### *Request*
    {
        "cmd": "editArmy",
        "sid": <sid>,
        "nameArmy": <name of the army>,
        "units": [
            {
                "nameUnit": <name of the unit>,
                "count": <count of units>
            }
        ]
    }
#### *Response*
    { "status": "OK" }


## Destruction army
#### *Request*
    {
        "cmd": "destroyArmy",
        "sid": <sid>,
        "nameArmy": <name of the army>
    }
#### *Response*
    { "status": "OK" }



###Getting units of the army
#### *Request*
    {
        "cmd": "getArmyUnits",
        "sid": <sid>,
        "nameArmy": <name of the army>
    }
#### *Response*
    {
        "status": "OK",
        "units": [
            {
                "nameUnit": <name of the unit>,
                "count": <count of units>
            }
        ]
    }


## Getting list of all armies
#### *Request*
    {
        "cmd": "getListAllArmies",
        "sid": <sid>
    }
#### *Response*
    {
        "status": "OK",
        "armies": [
            { "nameArmy": <name of the army> },
            ...
        ]
    }


## Getting list of armies, designed by current user
#### *Request*
    {
        "cmd": "getListArmies",
        "sid": <sid>
    }
#### *Response*
    {
        "status": "OK",
        "armies": [
            { "nameArmy": <name of the army> },
            ...
        ]
    }


## Getting units of the army
#### *Request*
    {
        "cmd": "getArmyUnits",
        "sid": <sid>,
        "nameArmy": <name of the army>
    }
#### *Response*
    {
        "status": "OK",
        "units": [
            {
                "nameUnit": <name of the unit>,
                "count": <count of units>
            }
        ]
    }

## Getting units in the army (ranks) and length of moves for each unit
#### *Request*
    {
        "cmd": "getArmyUnits",
        "sid": <sid>,
        "nameArmy": <name of the army>
    }
#### *Response*
    {
        "status": "OK",
        "units": [
            {
                "rank": <rank of the unit>,
                "moveLength": <length of the move>
            }
        ]
    }


## Getting units in the army (ranks) and length of moves for each unit
#### *Request*
    {
        "cmd": "getArmyUnits",
        "sid": <sid>,
        "nameArmy": <name of the army>
    }
#### *Response*
    {
        "status": "OK",
        "units": [
            {
                "nameUnit": <namee of the unit>,
                "rank": <rank of the unit>,
                "moveLength": <length of move of unit>,
                "maxCount": <maximum count of units in army>,
                "minCount": <minimum count of units in army>,
                "description": <desctirption of the unit>
            },
            ...
        ]
    }


###Getting game resources for placement
#### *Request*
    {
        "cmd": "getGamePlacement",
        "sid": <sid>,
        "nameGame": <name of the game>
    }
#### *Response*
    {
        "status": "OK",
        "nameMap": <name of the map>,
        "structure": <structure of the map>,
        "heightMap": <height of the map>,
        "widthMap": <width of the map>,
        "nameArmy": <name of the army>,
        "units": [
            {
                "nameUnit": <name of the unit>,
                "rank": <rank of the unit>,
                "count": <count of units>
            },
            ...
        ]
    }


## Setting placement of units
#### *Request*
    {
        "cmd": "setPlacement",
        "sid": <sid>,
        "nameGame": <name of the game>,
        "placement": <placement of units by player>
    }
#### *Response*
    { "status": "OK" }
### Bayeux:
#### *Response to URL 'game/\<name of the game\>/playerready'*
    {
        "cmd": "setReady",
        "login": <login of a user>    
    }
#### *Response to URL 'game/\<name of the game\>/status'*
    {
        "cmd": "changeStatus",
        "status": "running"    
    }

**Notes:** 

+ If second player has the status is 'ready' 
+ JSON is sent to two channels (that is for every players)

## Getting state and params of the game
#### *Request*
    {
        "cmd": "getGameSituation",
        "sid": <sid>,
        "nameGame": <name of the game>
    }
#### *Response*
    {
        "status": "OK",
        "nameMap": <name of the game>,
        "nameArmy": <name of the army>,
        "stateGame": <state of the game>,
        "opponentLogin" <login of a opponent>,
        "heightMap": <hegiht of the map>,
        "widthMap": <width of the map>,
        "isTurn": <is user's turn now>
    }

**Notes:** 

+ Game situation different for every players


## Making a move
#### *Request*
    {
        "cmd": "makeMove",
        "sid": <sid>,
        "nameGame": <name of the game>,
        "posFrom": <position from which move is made>,
        "posTo": <position where the move is made>
    }
#### *Response*
    { "status": "OK" }
### Bayeux:
#### *Response to URL 'game/\<name of the game\>/process/\<session id of the user\>'*
    {
        "cmd": "makeMove",
        "posFrom": <position from which move is made>,
        "posTo": <position where the move is made>
        "cellTo": <value of cell, where the move is made>
    }

**Notes:** 

+ JSON is sent to two channels (that is for every players)
+ Value of cell, where the move is made different for every players

#### *Response to URL 'game/\<name of the game\>/process/\<session id of the user\>'*
    {
        "cmd": "duel",
        "attackerUnitName": <name of the unit, that attacks>,
        "protectorUnitName": <name of the unit, that protect>,
        "result": <result of the duel for player>,
        "side": <side (attacker or protector) of unit>,
        "isEnd": <is end of the game>
    }

**Notes:** 

+ JSON is sent to two channels (that is for every players)

