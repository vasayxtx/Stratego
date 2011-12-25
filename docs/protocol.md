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
        "status": "OK",
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
        "status": "OK",
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
        "status": "OK"
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
        "status": "OK"
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
        "status": "OK"
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
        "status": "OK"
    }

## Getting a list of all maps
### Request
    {
        "cmd": "getListAllMaps",
        "sid": <sid>
    }
#### Response
    {
        "status": "OK",
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
        "status": "OK",
        "name": [...]
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
        "status": "OK",
        "width": <width of the map>,
        "height": <height of the map>,
        "structure": {
            "obst": [...],
            "pl1": [...],
            "pl2": [...],
        }
    }

