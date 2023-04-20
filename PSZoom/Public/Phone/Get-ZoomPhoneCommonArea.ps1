<#

.SYNOPSIS
List Zoom Common Area phones that are associated with account Account.

.DESCRIPTION
List Zoom Common Area phones that are associated with account Account.

.PARAMETER CommonAreaId
ID number[s] of common area phones to be queried.

.PARAMETER PageSize
The number of records returned within a single API call (Min 30 - MAX 100).

.PARAMETER NextPageToken
The next page token is used to paginate through large result sets. A next page token will be returned whenever the set 
of available results exceeds the current page size. The expiration period for this token is 15 minutes.

.PARAMETER Full
The full details of each Common Area Phone.

.OUTPUTS
An array of Objects

.EXAMPLE
$AllData = Get-ZoomPhoneCommonArea

.EXAMPLE
$SomeData = Get-ZoomPhoneCommonArea -ObjectId $SpecificIDsToQuery

.EXAMPLE
$RawData = Get-ZoomPhoneCommonArea -PageSize 50 -NextPageToken $reponse.next_page_token

.EXAMPLE
$RawData = Get-ZoomPhoneCommonArea -PageSize 50

.EXAMPLE
$AllData = Get-ZoomPhoneCommonArea -Full

.LINK
https://developers.zoom.us/docs/api/rest/reference/phone/methods/#operation/listCommonAreas

#>

function Get-ZoomPhoneCommonArea {
    [CmdletBinding(DefaultParameterSetName="AllData")]
    param (
        [Parameter(
            ParameterSetName="SelectedRecord",
            Mandatory = $True, 
            Position = 0, 
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True
        )]
        [Alias('id', 'common_Area_Id')]
        [string[]]$CommonAreaId,

        [parameter(ParameterSetName="NextRecords")]
        [ValidateRange(1, 100)]
        [Alias('page_size')]
        [int]$PageSize = 30,
		
        # The next page token is used to paginate through large result sets. A next page token will be returned whenever the set of available results exceeds the current page size. The expiration period for this token is 15 minutes.
        [parameter(ParameterSetName="NextRecords")]
        [Alias('next_page_token')]
        [string]$NextPageToken,

        [parameter(ParameterSetName="AllData")]
        [switch]$Full = $False

     )

    process {

        $BASEURI = "https://api.$ZoomURI/v2/phone/common_areas"

        switch ($PSCmdlet.ParameterSetName) {

            "NextRecords" {

                $AggregatedResponse = Get-ZoomPaginatedData -URI $BASEURI -PageSize $PageSize -NextPageToken $NextPageToken

            }
            "SelectedRecord" {

                $AggregatedResponse = Get-ZoomPaginatedData -URI $BASEURI -ObjectId $CommonAreaId

            }
            "AllData" {

                $AggregatedResponse = Get-ZoomPaginatedData -URI $BASEURI -PageSize $PageSize

            }
        }
        
        
        
        if ($Full -and ($PSVersionTable.PSVersion.Major -ge 7)) {

            $TempAggregatedResponse = $AggregatedResponse
            $AggregatedResponse = [System.Collections.Concurrent.ConcurrentBag[psobject]]::new()

            $TempAggregatedResponse | ForEach-Object -Parallel {

                $Script:PSZoomToken =  $using:PSZoomToken
                $Script:ZoomURI = $using:ZoomURI
                $localAggregatedResponse = $using:AggregatedResponse
                import-module PSZoom

                $localAggregatedResponse.Add($(Get-ZoomPhoneCommonArea -CommonAreaId $_.id))

            } -ThrottleLimit 10  #Recommended amount for Pro users.  If 429 is returned this number may need to be lowered.  See Rate limit details.
            

        }elseif ($Full) {

            $TempAggregatedResponse = $AggregatedResponse
            $AggregatedResponse = @()

            $TempAggregatedResponse | ForEach-Object {

                
                Write-Progress -Activity "Query Zoom API" -Status "$([math]::Round(($AggregatedResponse.count/$TempAggregatedResponse.count)*100))% Complete" -PercentComplete ([math]::Round(($AggregatedResponse.count/$TempAggregatedResponse.count)*100))
                $AggregatedResponse += Get-ZoomPhoneCommonArea -CommonAreaId $_.Id
                

            }
        }
        
        Write-Output $AggregatedResponse 
        
    }
}