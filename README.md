# PowerShell-CRUD

To learn the gist of PowerShell I decided to try making a basic CRUD API.

This CRUD API is configured using ```server.json``` which allows it to use multiple
shallow endpoints via JSON.

You're probably wondering why its all in one script? Its because I am lazy


## Server Output Example
```
Attempting to start server...
Listening on http://127.0.0.1:10024/ ...
GET http://127.0.0.1:10024/api
Status: 200
GET http://127.0.0.1:10024/api/v1/programmers
SELECT * FROM [PowerShell_CRUD].[dbo].[Programmers]
Status: 200
GET http://127.0.0.1:10024/api/v1/programmers/1
SELECT * FROM [PowerShell_CRUD].[dbo].[Programmers] WHERE id='1'
Status: 200
```

## Base API GET Response
```json
{
    "title": "Base Endpoint for my PowerShell API",
    "description": "For some reason I decided to make an API in PowerShell",
    "errors": [],
    "data": [
        {
            "endpoint": "/api/v1/programmers/",
            "title": "Programmers Endpoint",
            "description": "Get information about a programmer",
            "methods": [
                "GET",
                "PUT",
                "POST",
                "DELETE"
            ]
        },
        {
            "endpoint": "/api/v1/products/",
            "title": "Products Endpoint",
            "description": "Get information about some product",
            "methods": [
                "GET"
            ]
        }
    ]
}
```


## /programmers/{id} GET
```json
{
    "title": "Programmers Endpoint",
    "description": "Get information about a programmer",
    "errors": [],
    "data": {
        "id": 1,
        "first_name": "Barrett",
        "last_name": "Otte",
        "platform": "Linux",
        "favorite_language": "Python"
    }
}
```


## References
* https://4sysops.com/archives/building-a-web-server-with-powershell
* https://docs.microsoft.com/en-us/powershell/developer/cmdlet/approved-verbs-for-windows-powershell-commands
* https://www.restapitutorial.com/httpstatuscodes.html