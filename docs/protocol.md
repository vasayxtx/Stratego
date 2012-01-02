#Basic commands

## Signup
### Request
    {
        "cmd": "signup",
        "login": <login>,
        "password": <password>
    }    
#### Response
    {
        "status": "ok",
        "sid": <sid>
    }
#### Response for other clients
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
#### Response
    {
        "status": "ok",
        "sid": <sid>
    }
#### Response for other clients
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
#### Response
    {
        "status": "ok"
    }
#### Response for other clients
    {
        "cmd": "delUserOnline", 
        "login": <login of user>
    }

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
#### Response
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
#### Response
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
#### Response
    {
        "status": "ok"
    }

## Getting a list of all maps
### Request
    {
        "cmd": "getListAllMaps",
        "sid": <sid>
    }
#### Response
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
#### Response
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
#### Response
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
#### Response
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
#### Response
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
#### Response
    {
        "status": "ok"
    }

## Getting a list of all armies
### Request
    {
        "cmd": "getListAllArmies",
        "sid": <sid>
    }
#### Response
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
#### Response
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
#### Response
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

