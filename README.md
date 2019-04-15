# PowerShell-CRUD

To learn the gist of PowerShell I decided to try making a basic CRUD API


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


## /programmers GET






## References
* https://4sysops.com/archives/building-a-web-server-with-powershell
* https://docs.microsoft.com/en-us/powershell/developer/cmdlet/approved-verbs-for-windows-powershell-commands
* https://www.restapitutorial.com/httpstatuscodes.html