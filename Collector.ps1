$SqlSelectStatement = ("SELECT [Url], [CapturedID] AS [ID] FROM ps.CapturedURL WHERE Captured = 0 AND NOT LEFT([Url],7) ='mailto:' AND [Url] NOT LIKE '%linkedin%' AND [Url] LIKE '%.%' AND NOT LEFT([Url],10) = 'javascript' AND NOT LEFT([Url],2) = './'")
$Timestamp = Get-Date

Try 
{
    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = "Server=localhost\sqlexpress;Database=PowerScrape;trusted_connection=true;"
    $SqlConnection.Open()
    $SqlCommand = New-Object System.Data.SQLClient.SQLCommand
    $SqlCommand.Connection = $SqlConnection
    $SqlCommand.CommandText = $SqlSelectStatement
    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter.SelectCommand = $SqlCommand
    $SqlCommand.Connection = $SqlConnection
    $DataSet = New-Object System.Data.DataSet
    $SqlAdapter.Fill($Dataset)
}
Catch [System.Data.SqlClient.SqlException]
{
    $ErrorMessage = ($_.Exception).Message
    $ErrorStatusCode = ($_.Exception).Number
    $ErrorToLog = $ErrorMessage + ' | ' + $ErrorStatusCode + ' | ' + $Timestamp
    $ErrorToLog | Out-File $home\Error.log
}

ForEach ($CapturedUrl in $DataSet.Tables[0]) 
{

    $UrlID = $CapturedUrl.ID
    $UrlUri = $CapturedUrl.Url

    $Timestamp = Get-Date
    Try 
    {
        $Request = Invoke-WebRequest -Uri $UrlUri -TimeoutSec 30
        $UrlArray = $Request.Links | Select-Object -ExpandProperty Href

        # ResponseUri is handled differently in Linux and Windows so do a check to see which one to run.
        If ($ENV:OS)
        {
            $UrlAuthority = $Request.BaseResponse | Select-Object -ExpandProperty ResponseUri | Select-Object -ExpandProperty Authority
        }
        Else
        {
            $UrlAuthority = ($Request.BaseResponse).RequestMessage | Select-Object -ExpandProperty RequestUri | Select-Object -ExpandProperty host
        }
    }
    Catch [System.Net.WebException]
    {
        $ErrorMessage = ($_.Exception).Message
        $ErrorStatusCode = ($_.Exception).Response.StatusCode.value__
        
        $SqlInsertErrorLog = ("INSERT ErrorLog (URL,Routine,StatusCode,ErrorMessage,DateLogged) VALUES ('"+$UrlUri+"','"+'WebRequest'+"','"+$ErrorStatusCode+"','"+$ErrorMessage+"','"+$Timestamp+"')") 
        $SqlCommand = $SqlConnection.CreateCommand()
        $SqlCommand.CommandText = $SqlInsertErrorLog
        $SqlCommand.ExecuteNonQuery()  
    }
    Catch
    {
        $ErrorMessage = ($_.Exception).Message
        $ErrorStatusCode = ($_.Exception).Response.StatusCode.value__
        
        $SqlInsertErrorLog = ("INSERT ErrorLog (URL,Routine,StatusCode,ErrorMessage,DateLogged) VALUES ('"+$UrlUri+"','"+'WebRequest'+"','"+$ErrorStatusCode+"','"+$ErrorMessage+"','"+$Timestamp+"')") 
        $SqlCommand = $SqlConnection.CreateCommand()
        $SqlCommand.CommandText = $SqlInsertErrorLog
        $SqlCommand.ExecuteNonQuery()  
    }

    # update caPturedUrl set captured = true
    $SqlUpdateCapture = "
        UPDATE ps.CapturedUrl SET Captured = 1, DateCaptured = '"+$Timestamp+"' WHERE CapturedID = $UrlID;
        "
    $SqlCommand = $SqlConnection.CreateCommand()
    $SqlCommand.CommandText = $SqlUpdateCapture
    $SqlCommand.ExecuteNonQuery()
                


    ForEach ($Url in $UrlArray) 
    {
        
        $Timestamp = Get-Date
        Try
        {
            # for Urls that don't include the domain name, ie /r/somesubreddit, take the Authority from the ResponseUri and append it creating www.reddit.com/r/somesubreddit
            If ($Url.StartsWith("/")) 
            {
                $ScrapedUrl = $UrlAuthority + $Url 
            } 

            Else    
            {
                $ScrapedUrl = $Url
            }

            If ($ScrapedUrl -notlike "#*" -and $ScrapedUrl -ne '' -and $ScrapedUrl -ne $null)
            {
                # for Urls that contain a ' the insert will fail, so replace them with '' 
                $ScrapedUrl = $ScrapedUrl -replace "'","''"
<#
                $SqlInsertStatement = "
                    BEGIN 
                    IF NOT EXISTS (
			                    SELECT DISTINCT [URL] FROM CapturedUrl WHERE ([Url] = '"+$ScrapedUrl+"' 
				                    OR [URL] = REPLACE('"+$ScrapedUrl+"','www.','') OR [URL] = REPLACE('"+$ScrapedUrl+"','http://','') 
				                    OR [URL] = REPLACE('"+$ScrapedUrl+"','http://www.','') OR [URL] = REPLACE('"+$ScrapedUrl+"','https://','') 
				                    OR [URL] = REPLACE('"+$ScrapedUrl+"','https://www.',''))
				                    ) 
	                    BEGIN
		                    INSERT CapturedURL ([Url]) VALUES ('"+$ScrapedUrl+"')
	                    END
	                    ELSE
                        BEGIN
		                    UPDATE CapturedURL SET ReCaptured = ReCaptured + 1, DateReCaptured = '"+$Timestamp+"' WHERE [URL] = '"+$ScrapedUrl+"'
                        END
                    END;"
#>
                $SqlInsertStatement = "
                BEGIN 
                    IF NOT EXISTS (
                            SELECT * FROM ps.CapturedUrl WHERE [Url] = '"+$ScrapedUrl+"' OR [URL] = REPLACE('"+$ScrapedUrl+"','www.','') 
                                OR [URL] = REPLACE('"+$ScrapedUrl+"','http://','') OR [URL] = REPLACE('"+$ScrapedUrl+"','http://www.','') 
                                OR [URL] = REPLACE('"+$ScrapedUrl+"','https://','') OR [URL] = REPLACE('"+$ScrapedUrl+"','https://www.','') 
                                OR [URL] = REPLACE('"+$ScrapedUrl+"',RIGHT([URL],1),'') OR [URL] = REPLACE(REPLACE('"+$ScrapedUrl+"','www.',''),RIGHT('"+$ScrapedUrl+"',1),'')
                                )
                        BEGIN
                            INSERT ps.CapturedURL ([Url]) VALUES ('"+$ScrapedUrl+"')
                        END
                END;"
                $SqlCommand = $SqlConnection.CreateCommand()
                $SqlCommand.CommandText = $SqlInsertStatement
                $SqlCommand.ExecuteNonQuery()
            }
        }
        Catch [System.Data.SqlClient.SqlException]
        {
            $ErrorMessage = ($_.Exception).Message
            $ErrorStatusCode = ($_.Exception).Number

            $SqlInsertErrorLog = ("INSERT ErrorLog (URL,Routine,StatusCode,ErrorMessage,DateLogged) VALUES ('"+$ScrapedUrl+"','"+'SqlInsert'+"','"+$ErrorStatusCode+"','"+$ErrorMessage+"','"+$Timestamp+"')")
            $SqlCommand = $SqlConnection.CreateCommand()
            $SqlCommand.CommandText = $SqlInsertErrorLog
            $SqlCommand.ExecuteNonQuery()
        }
        Catch
        {
            $ErrorMessage = ($_.Exception).Message
            $ErrorStatusCode = ($_.Exception).Number

            $SqlInsertErrorLog = ("INSERT ErrorLog (URL,Routine,StatusCode,ErrorMessage,DateLogged) VALUES ('"+$ScrapedUrl+"','"+'SqlInsert'+"','"+$ErrorStatusCode+"','"+$ErrorMessage+"','"+$Timestamp+"')")
            $SqlCommand = $SqlConnection.CreateCommand()
            $SqlCommand.CommandText = $SqlInsertErrorLog
            $SqlCommand.ExecuteNonQuery()
        }
    }
}




