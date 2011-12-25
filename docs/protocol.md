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

