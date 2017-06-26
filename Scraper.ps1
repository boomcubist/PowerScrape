$SqlGetUrls = ("
    IF (SELECT COUNT([URL]) FROM ps.CapturedUrl WHERE Scraped = 0 AND NOT LEFT([Url],7) ='mailto:' AND [Url] NOT LIKE '%linkedin%') = 0
        BEGIN
	        IF (SELECT COUNT([URL]) FROM ps.CapturedUrl WHERE Scraped = 1 AND ReScraped = 0 AND NOT LEFT([Url],7) ='mailto:' AND [Url] NOT LIKE '%linkedin%') = 0
	        BEGIN
		        SELECT [Url], CapturedID AS ID FROM ps.CapturedUrl WHERE Scraped = 1 AND ReScraped >= 1 AND NOT LEFT([Url],7) ='mailto:' AND [Url] NOT LIKE '%linkedin%'
	        END
	        ELSE
	        BEGIN
		        SELECT [Url], CapturedID AS ID FROM ps.CapturedUrl WHERE Scraped = 1 AND ReScraped = 0 AND NOT LEFT([Url],7) ='mailto:' AND [Url] NOT LIKE '%linkedin%'
	        END
        END
        ELSE
        BEGIN
	        SELECT [Url], CapturedID AS ID FROM ps.CapturedUrl WHERE Scraped = 0 AND NOT LEFT([Url],7) ='mailto:' AND [Url] NOT LIKE '%linkedin%'
        END;
    ")
$SqlGetSearchTerms = ("
    SELECT TermDescription, SearchTermID FROM ps.SearchTerms
    ")

$Timestamp = Get-Date

Try
{   
    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = "Server=localhost\sqlexpress;Database=PowerScrape;trusted_connection=true;"
    $SqlConnection.Open()
}
Catch [System.Data.SqlClient.SqlException]
{
    $ErrorMessage = ($_.Exception).Message
    $ErrorStatusCode = ($_.Exception).Number
    $ErrorToLog = $ErrorMessage + ' | ' + $ErrorStatusCode + ' | ' + $Timestamp
    $ErrorToLog | Out-File $home\Error.log
}
Try
{
    $SqlCommand = New-Object System.Data.SQLClient.SQLCommand
    $SqlCommand.Connection = $SqlConnection
    $SqlCommand.CommandText = $SqlGetUrls

    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter.SelectCommand = $SqlCommand
    $SqlCommand.Connection = $SqlConnection
    $UrlDataSet = New-Object System.Data.DataSet
    $SqlAdapter.Fill($UrlDataSet)
}
Catch [System.Data.SqlClient.SqlException]
{
    $ErrorMessage = ($_.Exception).Message
    $ErrorStatusCode = ($_.Exception).Number
    $ErrorToLog = $ErrorMessage + ' | ' + $ErrorStatusCode + ' | ' + $Timestamp
    $ErrorToLog | Out-File $home\Error.log
}
Try
{
    $SqlCommand = New-Object System.Data.SQLClient.SQLCommand
    $SqlCommand.Connection = $SqlConnection
    $SqlCommand.CommandText = $SqlGetSearchTerms

    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter.SelectCommand = $SqlCommand
    $SqlCommand.Connection = $SqlConnection
    $SearchTermsDataSet = New-Object System.Data.DataSet
    $SqlAdapter.Fill($SearchTermsDataSet)
}
Catch [System.Data.SqlClient.SqlException]
{
    $ErrorMessage = ($_.Exception).Message
    $ErrorStatusCode = ($_.Exception).Number
    $ErrorToLog = $ErrorMessage + ' | ' + $ErrorStatusCode + ' | ' + $Timestamp
    $ErrorToLog | Out-File $home\Error.log
}

ForEach ($CapturedUrl in $UrlDataSet.Tables[0])
{
    $UrlID = $CapturedUrl.ID
    $UrlUri = $CapturedUrl.Url -replace "'","''"
    
    $Timestamp = Get-Date

    Try
    {
        $SqlUpdateUrl = ("
            IF (SELECT Scraped FROM ps.CapturedURL WHERE [CapturedID] = $UrlID) = 0
            BEGIN
	            -- not yet scraped, yet scraped to true
	            UPDATE ps.CapturedUrl SET Scraped = 1, DateScraped = ('"+$Timestamp+"') WHERE [CapturedID] = $UrlID
            END
            ELSE
            BEGIN
	            -- scraped multiple times, add this time to the count
	            UPDATE ps.CapturedUrl SET ReScraped = Rescraped + 1, DateReScraped = ('"+$Timestamp+"') WHERE [CapturedID] = $UrlID
            END;
            ")
        $SqlCommand = $SqlConnection.CreateCommand()
        $SqlCommand.CommandText = $SqlUpdateUrl
        $SqlCommand.ExecuteNonQuery()
    }
    Catch [System.Data.SqlClient.SqlException]
    {
        $ErrorMessage = ($_.Exception).Message
        $ErrorStatusCode = ($_.Exception).Number

        $SqlInsertErrorLog = ("INSERT ps.ErrorLog (Routine,CapturedUrlID,StatusCode,ErrorMessage,DateLogged) VALUES ('SqlInsert',$UrlID,'"+$ErrorStatusCode+"','"+$ErrorMessage+"','"+$Timestamp+"')") 
        $SqlCommand = $SqlConnection.CreateCommand()
        $SqlCommand.CommandText = $SqlInsertErrorLog
        $SqlCommand.ExecuteNonQuery()
    }

    ForEach ($SearchTerm in $SearchTermsDataSet.Tables[0])
    {
        $SearchTermDescription = $SearchTerm.TermDescription
        $SearchTermID = $SearchTerm.SearchTermID

        $Timestamp = Get-Date
        Try
        {
            $Html = (Invoke-WebRequest -Uri $UrlUri -TimeoutSec 30).RawContent
        }
        Catch [System.Net.WebException]
        {
            $ErrorMessage = ($_.Exception).Message
            $ErrorStatusCode = ($_.Exception).Response.StatusCode.value__

            $SqlInsertErrorLog = ("INSERT ps.ErrorLog (Routine,CapturedUrlID,StatusCode,ErrorMessage,DateLogged) VALUES ('SqlInsert',$UrlID,'"+$ErrorStatusCode+"','"+$ErrorMessage+"','"+$Timestamp+"')") 
            $SqlCommand = $SqlConnection.CreateCommand()
            $SqlCommand.CommandText = $SqlInsertErrorLog
            $SqlCommand.ExecuteNonQuery()            
        }
        
        $Result = ($Html -match $SearchTermDescription)

        If ($Result -eq 1) 
        {     
            Try
            {
                $SqlUpdateUrlIfMatched = ("
                    BEGIN
                        UPDATE ps.CapturedUrl SET [Matched] = 1, DateMatched = ('"+$Timestamp+"') WHERE [CapturedID] = $UrlID
                        INSERT ps.MatchedURL ([CapturedUrlID],[SearchTermID],[DateMatched]) VALUES ($UrlID,$SearchTermID,'"+$Timestamp+"')
                    END")
                
                $SqlCommand = $SqlConnection.CreateCommand()
                $SqlCommand.CommandText = $SqlUpdateUrlIfMatched
                $SqlCommand.ExecuteNonQuery()
            }
            Catch [System.Data.SqlClient.SqlException]
            {
                $ErrorMessage = ($_.Exception).Message
                $ErrorStatusCode = ($_.Exception).Number
        
                $SqlInsertErrorLog = ("INSERT ps.ErrorLog (Routine,CapturedUrlID,StatusCode,ErrorMessage,DateLogged) VALUES ('SqlInsert',$UrlID,'"+$ErrorStatusCode+"','"+$ErrorMessage+"','"+$Timestamp+"')") 
                $SqlCommand = $SqlConnection.CreateCommand()
                $SqlCommand.CommandText = $SqlInsertErrorLog
                $SqlCommand.ExecuteNonQuery()  
            }
        }   
    }
}