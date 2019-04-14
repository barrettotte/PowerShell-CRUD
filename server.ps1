# A basic CRUD api


function HaltIfUnavailable(){
    param ([System.String] $serverHost, [System.Int32] $serverPort)
    $tcpConn = (New-Object System.Net.Sockets.TcpClient)
    try {
        $tcpConn.Connect($serverHost, $serverPort)
        Write-Host("Port $serverPort is unavailable.")
        Write-Host("  Server is already running or something is already listening on this port.")
        exit
    } catch [System.Net.Sockets.SocketException] {
        Write-Host("Server starting...")
    }
    $tcpConn.Close()
}

function RequestRouter(){
    param ([System.Net.HttpListenerContext] $context, [System.String] $baseUrl)
    $content = ""
    try{
        $resp = $context.Response
        $req = $context.Request
        Write-Host("$($req.HttpMethod) $($req.Url)")
        switch ("$($req.Url)".Replace($baseUrl, '')) {
            ""      { $content = Get-BaseContent           ; $resp.StatusCode = 200 }
            default { $content = Get-404ErrorContent($req) ; $resp.StatusCode = 404 }
        }
    } catch [System.Exception] {
        $content = Get-500ErrorContent($_)
        $resp.StatusCode = 500
    }
    $resp.ContentLength64 = $content.Length
    $resp.OutputStream.Write($content, 0, $content.Length)
    $resp.Close()
}

function Get-BaseContent(){
    return [System.Text.Encoding]::UTF8.GetBytes("{
      `"title`": `"Base API`",
      `"messages`": [
        {
          `"type`": `"Information`",
          `"content`": `"Base endpoint for my PowerShell CRUD API`"
        }
      ],
      `"errors`": [],
      `"data`": []
    }")
}

function Get-404ErrorContent(){
    param ([System.Net.HttpListenerRequest] $req)
    return Get-ErrorContent "404 Not Found" "$($req.Url) was not found" $req
}

function Get-500ErrorContent(){
    param ([System.Management.Automation.ErrorRecord] $ex)
    # Obviously including this much info in a 500 error message back to the client is bad for security,
    #   but this is for education so I'm not going to think like that.
    $msg = "$($ex.Exception.Message + " " + $ex.InvocationInfo.PositionMessage)"
    return Get-ErrorContent "500 Internal Server Error" $msg
}

function Get-ErrorContent(){
    param ([System.String] $type, [System.String] $msg, [System.Net.HttpListenerRequest] $req)
    Write-Host("$type  $msg")
    return [System.Text.Encoding]::UTF8.GetBytes("{
      `"title`": `"Error`",
      `"messages`": [],
      `"errors`": [
        {
          `"type`": `"$type`",
          `"content`": `"$msg`"
        }
      ],
      `"data`": []
    }")
}


$config = Get-Content server.json | Out-String | ConvertFrom-Json;
$baseUrl = "http://$($config.host):$($config.port)/"
HaltIfUnavailable $config.host $config.port

$server = (New-Object System.Net.HttpListener)
$server.Prefixes.Add($baseUrl)
$server.Start()
Write-Host("Listening on $baseUrl ...")
while($server.IsListening) {
    RequestRouter $server.GetContext() $baseUrl
}
$server.Stop()