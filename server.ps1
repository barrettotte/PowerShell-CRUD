# A CRUD api written in PowerShell with no security

function HaltIfUnavailable(){
    param ([System.String] $serverHost, [System.Int32] $serverPort)
    $tcpConn = (New-Object System.Net.Sockets.TcpClient)
    try {
        $tcpConn.Connect($serverHost, $serverPort)
        Write-Host("Port $serverPort is unavailable.")
        Write-Host("  Server is already running or something is already listening on this port.")
        exit
    } catch [System.Net.Sockets.SocketException] {
        Write-Host("Attempting to start server...")
    }
    $tcpConn.Close()
}

function AddBackslash(){
    param ([System.String] $s)
    if ($s[$s.Length-1] -ne "/"){
        $s += "/"
    }
    return $s
}

function RequestToHashTable(){
    param ([System.Net.HttpListenerRequest] $req)
    $postContent = @{}
    $stream = (New-Object System.IO.StreamReader($req.InputStream))
    (ConvertFrom-Json $stream.ReadToEnd()).psobject.properties | ForEach-Object { 
        $postContent[$_.Name] = $_.Value 
    }
    return $postContent
}

function GetEndpointUrl(){
    param ([System.String] $reqUrl, [System.String] $baseUrl)
    $endpoint = "$($reqUrl)".Replace($baseUrl, '').Replace(' ', '').ToLower()
    return AddBackslash $endpoint
}

filter isNumeric() {
    param ([System.String] $s)
    return $s -is [byte]  -or $s -is [int16]  -or $s -is [int32]  -or $s -is [int64]  `
       -or $s -is [sbyte] -or $s -is [uint16] -or $s -is [uint32] -or $s -is [uint64] `
       -or $s -is [float] -or $s -is [double] -or $s -is [decimal]
    # Copy/pasted this beauty from here
    # https://stackoverflow.com/questions/10928030/in-powershell-how-can-i-test-if-a-variable-holds-a-numeric-value
}

function BuildDeleteQuery(){
    param (
        [System.Net.HttpListenerRequest] $req, 
        [System.String] $tableString, 
        [System.String] $id,
        [System.String] $identifier
    )
    $query = "DELETE FROM $tableString "
    if($id -ne $epConfig.endpoint -and $id -ne "/"){
        $query += "WHERE $($epConfig.identifier)='$($id.Replace('/',''))'"
    }
    return $query
}

function BuildPutQuery(){
    param (
        [System.Net.HttpListenerRequest] $req, 
        [System.String] $tableString, 
        [System.String] $id,
        [System.String] $identifier
    )
    $query = "UPDATE $tableString SET "
    $postContent = RequestToHashTable $req
    foreach($h in $postContent.Keys){
        $v = "$($postContent.Item($h))"
        if(-not (isNumeric $v)){
            $v = "'$v'"
        }
        $query += ("$h=" + $v + ",")
    }
    return $query.Substring(0, $query.Length-1) + " WHERE $identifier=$($id.Replace('/',''))"
}

function BuildPostQuery(){
    param ([System.Net.HttpListenerRequest] $req, [System.String] $tableString)
    $values = ""
    $cols = ""
    $query = "INSERT INTO $tableString ("
    $postContent = RequestToHashTable $req
    foreach($h in $postContent.Keys){
        $cols += "$h,"
        $v = "$($postContent.Item($h))"
        if(-not (isNumeric $v)){
            $v = "'$v'"
        }
        $values += ($v + ",")
    }
    return $query + $cols.Substring(0, $cols.Length-1) + ") VALUES (" + $values.Substring(0, $values.Length-1) + ")"
}

function BuildQuery(){
    param ([System.Net.HttpListenerRequest] $req, [System.Object] $epConfig, [System.String] $id)
    # Ah, yes. Look at all the low hanging SQL injection :)
    $query = ""
    $method = "$($req.HttpMethod)"
    $tableString = "[$($epConfig.database)].[$($epConfig.schema)].[$($epConfig.table)]"
    if($method -eq "GET"){
        $query = "SELECT * FROM $tableString "
        if($id -ne $epConfig.endpoint -and $id -ne "/"){
            $query += "WHERE $($epConfig.identifier)='$($id.Replace('/',''))'"
        }
    } elseif($method -eq "POST" -and $req.HasEntityBody){
        $query = BuildPostQuery $req $tableString
    } elseif($method -eq "PUT" -and $req.HasEntityBody){
        $query = BuildPutQuery $req $tableString $id "$($epConfig.identifier)"
    } elseif($method -eq "DELETE"){
        $query = BuildDeleteQuery $req $tableString $id "$($epConfig.identifier)"
    }
    return $query
}

function MethodHandler(){
    param ([System.Net.HttpListenerRequest] $req, [System.Object] $epConfig)
    $id = AddBackslash ($req.RawUrl.Replace($epConfig.endpoint, ''))
    $content = ""
    if($id.Split('/').Length -le 2 -or $id -eq $epConfig.endpoint){
        if(-not $epConfig.methods.Contains($req.HttpMethod)){
            return Get405ErrorContent $req
        }
        $query = BuildQuery $req $epConfig $id
        if($query -eq ""){
            return Get400ErrorContent $req "Bad body content given"
        } 
        $data = DatabaseHandler $query $epConfig.server $epConfig.database
        if($data.Length -eq 0){
            if($req.HttpMethod -eq "GET"){
                return Get404ErrorContent $req
            } else{
                $data = "[]"
            }
        }
        $content = "{
          `"title`": `"$($epConfig.title)`",
          `"description`": `"$($epConfig.description)`",
          `"errors`": [],
          `"data`": $data
        }"
    } 
    return $content 
}

function DatabaseHandler(){
    param ([System.String] $query, [System.String] $server, [System.String] $database)
    Write-Host($query)
    $data = Invoke-Sqlcmd -Query $query -ServerInstance $server -Database $database
    return $data | Select-Object * -ExcludeProperty ItemArray, Table, RowError, RowState, HasErrors | ConvertTo-Json
}

function EndpointHandler(){
    param ([System.Net.HttpListenerRequest] $req, [System.String] $reqEp, [System.Object] $config)
    $content = ""
    if ($reqEp -eq "/" -or $reqEp -eq "/api/" -or $reqEp -eq "/api/$($config.version)/"){
        $content = GetBaseContent $config
    } else{
        foreach ($epConfig in $config.endpoints){
            if ($reqEp.Contains($epConfig.endpoint)){
                $content = MethodHandler $req $epConfig
                if($content.Length -gt 0){
                    break
                }
            }
        }
    }
    return $content
}

function RequestHandler(){
    param([System.Net.HttpListenerContext] $context, [System.String] $baseUrl, [System.Object] $config)
    $content = ""
    try {
        $resp = $context.Response
        $resp.StatusCode = 200
        $req = $context.Request
        Write-Host("$($req.HttpMethod) $($req.Url)")
        $content = EndpointHandler $req (GetEndpointUrl $req.RawUrl $baseUrl) $config
        if($content.Length -eq 0){
            $content = Get404ErrorContent $req
        }
    } catch [System.Exception]{
        $content = Get500ErrorContent($_)
    }
    $contentJson = $content | ConvertFrom-Json
    if($contentJson.errors.Length -gt 0){
        $resp.StatusCode = $contentJson.errors[0].code
    }
    Write-Host("Status: $($resp.StatusCode)")
    $content = [System.Text.Encoding]::UTF8.GetBytes($content)
    $resp.ContentLength64 = $content.Length
    $resp.OutputStream.Write($content, 0, $content.Length)
    $resp.Close()
}

function GetBaseContent(){
    param([System.Object] $config)
    $endpoints = $config.endpoints | Select-Object * -ExcludeProperty server, database, schema, table, unique-identifier | ConvertTo-Json
    return "{
      `"title`": `"Base Endpoint for my PowerShell API`",
      `"description`": `"For some reason I decided to make an API in PowerShell`",
      `"errors`": [],
      `"data`": $endpoints
    }"
}

function Get400ErrorContent(){
    param ([System.Net.HttpListenerRequest] $req, [System.String] $msg)
    return GetErrorContent 400 "Bad Request" $msg
}

function Get404ErrorContent(){
    param ([System.Net.HttpListenerRequest] $req)
    return GetErrorContent 404 "Not Found" "$($req.Url) was not found"
}

function Get405ErrorContent(){
    param ([System.Net.HttpListenerRequest] $req)
    return GetErrorContent 405 "Method Not Allowed" "$($req.Url) does not support $($req.HttpMethod)"
}

function Get500ErrorContent(){
    param ([System.Management.Automation.ErrorRecord] $ex)
    $msg = "$($ex.Exception.Message + " " + $ex.InvocationInfo.PositionMessage)"
    return GetErrorContent 500 "Internal Server Error" $msg
}

function GetErrorContent(){
    param ([System.Int32] $code, [System.String] $type, [System.String] $msg)
    Write-Host("$code $type $msg")
    return "{
      `"title`": `"Error`",
      `"description`": `"`",
      `"errors`": [
        {
          `"code`": `"$code`",
          `"type`": `"$type`",
          `"content`": `"$msg`"
        }
      ],
      `"data`": []
    }"
}

$config = Get-Content server.json | Out-String | ConvertFrom-Json;
$baseUrl = "http://$($config.server.host):$($config.server.port)/"
HaltIfUnavailable $config.host $config.port
$server = (New-Object System.Net.HttpListener)
try {
    $server.Prefixes.Add($baseUrl)
    $server.Start()
} catch [System.Exception]{
    Write-Host("$($_.Exception.Message + " " + $_.InvocationInfo.PositionMessage)")
    Write-Host("Fatal Error; Server could not be started.")
    exit
}
Write-Host("Listening on $baseUrl ...")
while ($server.IsListening){
    RequestHandler $server.GetContext() $baseUrl $config
}
$server.Stop()