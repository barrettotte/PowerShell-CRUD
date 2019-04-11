
# --- TODO: Put into config.json --------------------
$serverPort = 10024
$serverHost = "127.0.0.1"
$baseUrl = "http://$($serverHost):$($serverPort)/"
$serverDrive = "www"
# ---------------------------------------------------

$root = $PWD.Path
$server = New-Object System.Net.HttpListener

$server.Prefixes.Add($baseUrl)
$server.Start()
New-PSDrive -Name $serverDrive -PSProvider FileSystem -Root $root
Set-Location("$($serverDrive):\")
Write-Host("Listening on $baseUrl ...")

while($server.IsListening) {
    $content = ""
    $context = $server.GetContext()
    $requestUrl = $context.Request.Url
    $response = $context.Response
    Write-Host("$requestUrl")
    try{
        $content = [System.Text.Encoding]::UTF8.GetBytes("
            <h1>Home</h1>
            <p>Hello World</p>
        ")
    } catch [System.Exception] {
        Write-Host("Internal Server Error  $($_.Exception.Message + " " + $_.InvocationInfo.PositionMessage)")
        $response.StatusCode = 500
        $content = [System.Text.Encoding]::UTF8.GetBytes("
            <h1>500 - Internal Server Error</h1>
            <hr><br> 
            <p>
                <b>Message:  </b> $($_.InvocationInfo.MyCommand.Name) : $($_.Exception.Message) <br>
                <b>Position: </b> $($_.InvocationInfo.PositionMessage) <br>
                <b>Category: </b> $($_.CategoryInfo.GetMessage()) <br>
                <b>Error Id: </b> $($_.FullyQualifiedErrorId) <br>
            </p>
            <hr>
        ")
    }
    $response.ContentLength64 = $content.Length
    $response.OutputStream.Write($content, 0, $content.Length)
    $responseStatus = $response.StatusCode
    Write-Host("  $responseStatus")
    $response.Close()
}