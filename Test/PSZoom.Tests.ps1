$ConfirmPreference = 'High'
#$PSVersion = $PSVersionTable.PSVersion.Major
#$ModuleName = $ENV:BHProjectName
#$ModulePath = Join-Path $ENV:BHProjectPath $ModuleName

#Using these variables for local testing
$PSVersion = $PSVersionTable.PSVersion.Major
$ModuleName = 'PSZoom'
$ModulePath = "d:\dev\$ModuleName\$ModuleName"

# Verbose output for non-master builds on appveyor. Handy for troubleshooting. Splat @Verbose against commands as needed (here or in pester tests).
$Verbose = @{ }
if ($ENV:BHBranchName -notlike "master" -or $env:BHCommitMessage -match "!verbose") {
    $Verbose.add("Verbose", $True)
}

Import-Module $ModulePath -Force

#Import private functions
$Private = @(Get-ChildItem -Path "$ModulePath\Private\" -include '*.ps1' -recurse -ErrorAction SilentlyContinue)

foreach ($file in $Private) {
    try {
        . $file.fullname
    }
    catch {
        Write-Error -Message "Failed to import function $($ps1.fullname): $_"
    }
}

$Module = Get-Module $ModuleName
$Commands = $Module.ExportedCommands.Keys

Mock -ModuleName $ModuleName Invoke-RestMethod {
    $Response = @{
        Body    = $Body
        Uri     = $Uri
        Method  = $Method
        Headers = $Headers
    }

    Write-Output $Response
}

Mock -ModuleName $ModuleName Invoke-RestMethod {
    $Response = @{
        Body    = $Body
        Uri     = $Uri
        Method  = $Method
        Headers = $Headers
    }

    Write-Output $Response
}


#Additional variables to use when testing
$AssistantId = 'TestAssistantId'
$AssistantId2 = 'TestAssistantId2'
$UserEmail = 'TestEmail@test.com'
$UserId = 'TestUserId@test.com'
$UserId2 = 'TestUserId2@test.com'
$GroupId = 'TestGroupId'
$GroupId2 = 'TestGroupId2'
$ApiKeySecret = @{
    ApiKey    = 'TestApiKey'
    ApiSecret = 'TestApiSecret'
}

Describe 'PSZoom General Tests' {
    It 'Should be the correct name' {
        $Module.Name | Should Be $ModuleName
    }

    It 'Should generate a JWT correctly' {
        $token = (New-JWT -Algorithm 'HS256' -type 'JWT' -Issuer 123 -SecretKey 456 -ValidforSeconds 30)
        $parsedToken = (Parse-JWTtoken -Token $token)
        $parsedToken.'alg' | Should -Be 'HS256'
        $parsedToken.'typ' | Should -Be 'JWT'
        $parsedToken.'iss' | Should -Be '123'
        $parsedToken.'exp' | Should -Not -BeNullOrEmpty
    }

    It 'Should create the correct headers' {
        $headers = New-ZoomHeaders @ApiKeySecret
        $headers.'content-type' | Should -Be 'application/json'
        $headers.'authorization' | Should -BeLike '*bearer*'
    }
}

Describe 'PSZoom Meeting Tests' {
    Context 'Strict mode' {
        Set-StrictMode -Version 'latest'

        It 'Should load' {
            $MeetingCommands = @(
                'Add-ZoomMeetingRegistrant',
                'Get-ZoomEndedMeetingInstances',
                'Get-ZoomMeeting',
                'Get-ZoomMeetingInvitation',
                'Get-ZoomMeetingPoll',
                'Get-ZoomMeetingRegistrants',
                'Get-ZoomMeetingsFromUser',
                'Get-ZoomPastMeetingDetails',
                'Get-ZoomPastMeetingParticipants',
                'Get-ZoomRegistrationQuestions',
                'Get-ZoomTelephoneReports',
                'New-ZoomMeetingPoll',
                'Remove-ZoomMeeting',
                'Remove-ZoomMeetingPoll',
                'Update-MeetingStatus',
                'Update-ZoomMeeting',
                'Update-ZoomMeetingLiveStream',
                'Update-ZoomMeetingPoll',
                'Update-ZoomMeetingRegistrantStatus'
            )
            
            $MeetingCommands | ForEach-Object {
                $MeetingCommands -contains $_ | Should Be $true
            }
        }
    }
}

Describe 'PSZoom User Tests' {
    Context 'Strict mode' {
        Set-StrictMode -Version 'latest'

        It 'Should load' {
            $UserCommands = @(
                'Get-ZoomRegistrationQuestions',
                'Get-ZoomSpecificUser',
                'Get-ZoomTelephoneReports',
                'Get-ZoomUserAssistants',
                'Get-ZoomUserEmailStatus',
                'Get-ZoomUserPermissions',
                'Get-ZoomUsers',
                'Get-ZoomUserSchedulers',
                'Get-ZoomUserSettings',
                'Get-ZoomUserToken',
                'New-ZoomUser',
                'Remove-ZoomSpecificUserAssistant',
                'Remove-ZoomSpecificUserScheduler',
                'Remove-ZoomUser',
                'Remove-ZoomUserAssistants',
                'Remove-ZoomUserSchedulers',
                'Revoke-ZoomUserSsoToken',
                'Update-ZoomProfilePicture',
                'Update-ZoomUser',
                'Update-ZoomUserEmail',
                'Update-ZoomUserpassword',
                'Update-ZoomUserSettings',
                'Update-ZoomUserStatus'
            )
            
            $UserCommands | ForEach-Object {
                $UserCommands -contains $_ | Should Be $true
            }
        }
    }
}

Describe 'Add-ZoomUserAssistant' {
    $schema = '{
    "type": "object",
    "title": "User assistants List",
    "description": "List of users assistants.",
    "properties": {
        "assistants": {
        "type": "array",
        "description": "List of Users assistants.",
        "maximum": 30,
        "items": {
            "type": "object",
            "properties": {
            "id": {
                "type": "string",
                "description": "Assistants user ID."
            },
            "email": {
                "type": "string",
                "description": "Assistants email address."
            }
            }
        }
        }
    }
    }'

    $params = @{
        UserId         = $UserEmail
        AssistantEmail = 'testemail1', 'testemail2'
        AssistantId    = 'testid1', 'testid2'
    }

    $request = Add-ZoomUserAssistants @params @ApiKeySecret

    It 'Uses the correct method' {
        $request.Method | Should Be 'POST'
    }

    It 'Uses the correct uri' {
        $request.Uri | Should Be "https://api.zoom.us/v2/users/$UserEmail/assistants"
    }

    It 'Validates against the JSON schema' {
        Test-Json -Json $request.Body -Schema $schema | Should Be $True
    }
}

Describe 'Get-ZoomPersonalMeetingRoomName' {
    $VanityName = 'Test'
    $request = Get-ZoomPersonalMeetingRoomName -VanityName $VanityName @ApiKeySecret

    It 'Uses the correct method' {
        $request.Method | Should Be 'GET'
    }

    It 'Uses the query parameter' {
        $request.Uri.Query | Should Be "?vanity_name=$VanityName"
    }

    It 'Uses the correct URI' {
        $Request.Uri.Scheme | Should Be 'https'
        $Request.Uri.Authority | Should Be 'api.zoom.us'
        $Request.Uri.AbsolutePath | Should Be '/v2/users/vanity_name'
    }
}

Describe 'Get-ZoomUser' {
    $request = Get-ZoomUser -UserId $UserId @ApiKeySecret

    It 'Uses the correct method' {
        $request.Method | Should Be 'GET'
    }

    It 'Uses the correct uri' {
        $request.Uri | Should Be "https://api.zoom.us/v2/users/$UserId"
    }
}

Describe 'Get-ZoomUserAssistants' {
    $request = Get-ZoomUserAssistants -UserId $UserId @ApiKeySecret

    It 'Uses the correct method' {
        $request.Method | Should Be 'GET'
    }

    It 'Uses the correct uri' {
        $request.Uri | Should Be "https://api.zoom.us/v2/users/$UserId/assistants"
    }
}

Describe 'Get-ZoomUserEmailStatus' {
    $request = Get-ZoomUserEmailStatus -UserId $UserId @ApiKeySecret

    It 'Uses the correct method' {
        $request.Method | Should Be 'GET'
    }

    It 'Uses the correct uri and query parameter' {
        $request.Uri | Should Be "https://api.zoom.us/v2/users/email?email=$UserId".replace('@', '%40')
    }
}

Describe 'Get-ZoomUserPermissions' {
    $request = Get-ZoomUserPermissions -UserId $UserId @ApiKeySecret

    It 'Uses the correct method' {
        $request.Method | Should Be 'GET'
    }

    It 'Uses the correct uri' {
        $request.Uri | Should Be "https://api.zoom.us/v2/users/$UserId/permissions"
    }
}

Describe 'New-ZoomUser' {
    $schema = '{
    "type": "object",
    "properties": {
        "action": {
        "type": "string",
        "description": "Specify how to create the new user: <br>`create` - User will get an email sent from Zoom. There is a confirmation link in this email. The user will then need to use the link to activate their Zoom account. The user can then set or change their password.<br>`autoCreate` - This action is provided for the enterprise customer who has a managed domain. This feature is disabled by default because of the security risk involved in creating a user who does not belong to your domain.<br>`custCreate` - This action is provided for API partners only. A user created in this way has no password and is not able to log into the Zoom web site or client.<br>`ssoCreate` - This action is provided for the enabled “Pre-provisioning SSO User” option. A user created in this way has no password. If not a basic user, a personal vanity URL using the user name (no domain) of the provisioning email will be generated. If the user name or PMI is invalid or occupied, it will use a random number or random personal vanity URL.",
        "enum": [
            "create",
            "autoCreate",
            "custCreate",
            "ssoCreate"
        ],
        "x-enum-descriptions": [
            "User will get an email sent from Zoom. There is a confirmation link in this email. User will then need to click this link to activate their account to the Zoom service. The user can set or change their password in Zoom. <br/>.",
            "This action is provided for enterprise customer who has a managed domain. This feature is disabled by default because of the security risk involved in creating a user who does not belong to your domain without notifying the user. <br/>",
            "This action is provided for API partner only. User created in this way has no password and is not able to log into the Zoom web site or client. <br/>",
            "This action is provided for enabled \"Pre-provisioning SSO User\" option. User created in this way has no password. If it is not a basic user, will generate a Personal Vanity URL using user name (no domain) of the provisioning email. If user name or pmi is invalid or occupied, will use random number/random personal vanity URL. <br/>"
        ]
        },
        "user_info": {
        "type": "object",
        "required": [
            "email",
            "type"
        ],
        "properties": {
            "email": {
            "type": "string",
            "description": "User email address.",
            "maxLength": 128
            },
            "type": {
            "type": "integer",
            "enum": [
                1,
                2,
                3
            ],
            "x-enum-descriptions": [
                "basic",
                "pro",
                "corp"
            ],
            "description": "User type:<br>`1` - Basic.<br>`2` - Pro.<br>`3` - Corp."
            },
            "first_name": {
            "type": "string",
            "description": "Users first name: cannot contain more than 5 Chinese words.",
            "maxLength": 64
            },
            "last_name": {
            "type": "string",
            "description": "Users last name: cannot contain more than 5 Chinese words.",
            "maxLength": 64
            },
            "password": {
            "type": "string",
            "description": "User password. Only used for the \"autoCreate\" function. The password has to have a minimum of 8 characters and maximum of 32 characters. It must have at least one letter (a, b, c..), at least one number (1, 2, 3...) and include both uppercase and lowercase letters. It should not contain only one identical character repeatedly (11111111 or aaaaaaaa) and it cannot contain consecutive characters (12345678 or abcdefgh).",
            "format": "password",
            "minLength": 8,
            "maxLength": 32
            }
        }
        }
    },
    "required": [
        "action"
    ]
    }'

    $params = @{
        Email     = 'testemail@test.com'
        Action    = 'ssoCreate'
        Type      = 'pro'
        FirstName = 'testfirstname'
        LastName  = 'testlastname'
        Password  = 'testpassword'
    }

    $request = New-ZoomUser @params @ApiKeySecret

    It 'Uses the correct method' {
        $request.Method | Should Be 'POST'
    }

    It 'Uses the correct uri' {
        $request.Uri | Should Be "https://api.zoom.us/v2/users"
    }

    It 'Validates against the JSON schema' {
        Test-Json -Json $request.Body -Schema $schema | Should Be $True
    }
}

Describe 'Remove-ZoomSpecificUserAssistant' {
    $request = Remove-ZoomSpecificUserAssistant -UserId $UserId -AssistantId $AssistantId @ApiKeySecret

    It 'Uses the correct method' {
        $request.Method | Should Be 'DELETE'
    }

    It 'Uses the correct uri' {
        $request.Uri | Should Be "https://api.zoom.us/v2/users/$UserId/assistants/$AssistantId"
    }

    It 'Invokes rest method for multiple user IDs' {
        Remove-ZoomSpecificUserAssistant -UserId $UserId, $UserId2 -AssistantId $AssistantId @ApiKeySecret
        Assert-MockCalled -CommandName Invoke-RestMethod -Times 2 -Scope It -ModuleName $ModuleName
    }

    It 'Invokes rest method for multiple user schedulers' {
        Remove-ZoomSpecificUserAssistant -UserId $UserId-AssistantId $AssistantId, $AssistantId2 @ApiKeySecret
        Assert-MockCalled -CommandName Invoke-RestMethod -Times 2 -Scope It -ModuleName $ModuleName
    }
    
    It 'Invokes rest method for multiple user IDs and schedulers at the same time' {
        Remove-ZoomSpecificUserAssistant -UserId $UserId, $UserId2 -AssistantId $AssistantId, $AssistantId2 @ApiKeySecret
        Assert-MockCalled -CommandName Invoke-RestMethod -Times 4 -Scope It -ModuleName $ModuleName
    }
}

Describe 'Remove-ZoomSpecificUserScheduler' {
    $request = Remove-ZoomSpecificUserScheduler -UserId $UserId -SchedulerId $AssistantId @ApiKeySecret

    It 'Uses the correct method' {
        $request.Method | Should Be 'DELETE'
    }

    It 'Uses the correct uri' {
        $request.Uri | Should Be "https://api.zoom.us/v2/users/$UserId/schedulers/$AssistantId"
    }

    It 'Invokes rest method for multiple user IDs' {
        Remove-ZoomSpecificUserAssistant -UserId $UserId, $UserId2 -AssistantId $AssistantId @ApiKeySecret
        Assert-MockCalled -CommandName Invoke-RestMethod -Times 2 -Scope It -ModuleName $ModuleName
    }

    It 'Invokes rest method for multiple user schedulers' {
        Remove-ZoomSpecificUserAssistant -UserId $UserId-AssistantId $AssistantId, $AssistantId2 @ApiKeySecret
        Assert-MockCalled -CommandName Invoke-RestMethod -Times 2 -Scope It -ModuleName $ModuleName
    }
    
    It 'Invokes rest method for multiple user IDs and schedulers at the same time' {
        Remove-ZoomSpecificUserScheduler -UserId $UserId, $UserId2 -SchedulerId $AssistantId, $AssistantId2 @ApiKeySecret
        Assert-MockCalled -CommandName Invoke-RestMethod -Times 4 -Scope It -ModuleName $ModuleName
    }
}

Describe 'Remove-ZoomUser' {
    $request = Remove-ZoomUser -UserId $UserId -Action Delete -TransferEmail $UserId2 -TransferMeeting -TransferRecording  @ApiKeySecret

    It 'Uses the correct method' {
        $request.Method | Should Be 'DELETE'
    }

    It 'Uses the correct uri' {
        $Request.Uri.Scheme | Should Be 'https'
        $Request.Uri.Authority | Should Be 'api.zoom.us'
        $Request.Uri.AbsolutePath | Should Be "/v2/users/$UserId"
    }

    It 'Uses the correct query parameters' {
        $queries = @('action=Delete', "transfer_email=$UserId2".replace('@', '%40'), 'transfer_meeting=True', 'transfer_recording=True')
        $queries | ForEach-Object {
            $Request.Uri.Query | Should BeLike "*$_*"
        }
    }
    
    It 'Invokes rest method for each user inputted' {
        Remove-ZoomUser -UserId $UserId, $UserId2 @ApiKeySecret
        Assert-MockCalled -CommandName Invoke-RestMethod -Times 2 -Scope It -ModuleName $ModuleName
    }
}

Describe 'Remove-ZoomUserAssistants' {
    $request = Remove-ZoomUserAssistants -UserId $UserId @ApiKeySecret

    It 'Uses the correct method' {
        $request.Method | Should Be 'DELETE'
    }

    It 'Uses the correct uri' {
        $Request.Uri | Should Be "https://api.zoom.us/v2/users/$UserId/assistants"
    }
    
    It 'Invokes rest method for each user inputted' {
        Remove-ZoomUserAssistants -UserId $UserId, $UserId2 @ApiKeySecret
        Assert-MockCalled -CommandName Invoke-RestMethod -Times 2 -Scope It -ModuleName $ModuleName
    }
}

Describe 'Remove-ZoomUserSchedulers' {
    $request = Remove-ZoomUserSchedulers -UserId $UserId @ApiKeySecret

    It 'Uses the correct method' {
        $request.Method | Should Be 'DELETE'
    }

    It 'Uses the correct uri' {
        $Request.Uri | Should Be "https://api.zoom.us/v2/users/$UserId/schedulers"
    }
    
    It 'Invokes rest method for each user inputted' {
        Remove-ZoomUserSchedulers -UserId $UserId, $UserId2 @ApiKeySecret
        Assert-MockCalled -CommandName Invoke-RestMethod -Times 2 -Scope It -ModuleName $ModuleName
    }
}

Describe 'Revoke-ZoomUserSsoToken' {
    $request = Revoke-ZoomUserSsoToken -UserId $UserId @ApiKeySecret

    It 'Uses the correct method' {
        $request.Method | Should Be 'DELETE'
    }

    It 'Uses the correct uri' {
        $Request.Uri | Should Be "https://api.zoom.us/v2/users/$UserId/token"
    }
    
    It 'Invokes rest method for each user inputted' {
        Revoke-ZoomUserSsoToken -UserId $UserId, $UserId2 @ApiKeySecret
        Assert-MockCalled -CommandName Invoke-RestMethod -Times 2 -Scope It -ModuleName $ModuleName
    }
}

Describe 'Update-ZoomProfilePicture' {
    new-item -Path $PSScriptRoot -ItemType 'File' -Value 'testimg.jpg'
    $request = Update-ZoomProfilePicture -UserId $UserId -Filename 'testimg.jpg' @ApiKeySecret
    remove-item -Path '$PSScriptRoot\testimg.jpg'

    It 'Uses the correct method' {
        $request.Method | Should Be 'POST'
    }

    It 'Uses the correct uri' {
        $Request.Uri | Should Be "https://api.zoom.us/v2/users/$UserId/picture"
    }
}

Describe 'Update-ZoomUser' {
    $schema = '{
        "type": "object",
        "description": "The user update object represents a user on Zoom.",
        "properties": {
          "first_name": {
            "type": "string",
            "description": "Users first name. Cannot contain more than 5 Chinese characters.",
            "maxLength": 64
          },
          "last_name": {
            "type": "string",
            "description": "Users last name. Cannot contain more than 5 Chinese characters.",
            "maxLength": 64
          },
          "type": {
            "type": "integer",
            "enum": [
              1,
              2,
              3
            ],
            "x-enum-descriptions": [
              "basic",
              "pro",
              "corp"
            ],
            "description": "User types:<br>`1` - Basic.<br>`2` - Pro.<br>`3` - Corp."
          },
          "pmi": {
            "type": "integer",
            "description": "Personal meeting ID: length must be 10.",
            "minLength": 10,
            "maxLength": 10
          },
          "use_pmi": {
            "type": "boolean",
            "description": "Use Personal Meeting ID for instant meetings.",
            "default": false
          },
          "timezone": {
            "type": "string",
            "description": "The time zone ID for a user profile. For this parameter value please refer to the ID value in the [timezone](https://marketplace.zoom.us/docs/api-reference/other-references/abbreviation-lists#timezones) list."
          },
          "language": {
            "type": "string",
            "description": "language"
          },
          "dept": {
            "type": "string",
            "description": "Department for user profile: use for report."
          },
          "vanity_name": {
            "type": "string",
            "description": "Personal meeting room name."
          },
          "host_key": {
            "type": "string",
            "description": "Host key. It should be a 6-10 digit number.",
            "minLength": 6,
            "maxLength": 10
          },
          "cms_user_id": {
            "type": "string",
            "description": "Kaltura user ID."
          }
        }
      }'

    $params = @{
        UserId     = $UserId
        LoginType  = 'sso'
        Type       = 'pro'
        FirstName  =  'test first name'
        LastName   =  'test last name'
        Pmi        = '1234567890'
        UsePmi     = $True
        Timezone   = 'Pacific/Honolulu'
        Language   = 'english'
        Dept       = 'test department'
        VanityName = 'test vanity name'
        HostKey    = '123456'
        CmsUserId  = '654321'
    }

    $request = Update-ZoomUser @params @ApiKeySecret

    It 'Uses the correct method' {
        $request.Method | Should Be 'PATCH'
    }

    It 'Uses the correct uri' {
        $Request.Uri.Scheme | Should Be 'https'
        $Request.Uri.Authority | Should Be 'api.zoom.us'
        $Request.Uri.AbsolutePath | Should Be "/v2/users/$UserId"
    }

    It 'Uses the correct query parameters' {
        $Request.Uri.Query | Should Be '?login_type=101'
    }

    It "Validates against the JSON schema" {
        Test-Json -Json $request.Body -Schema $schema | Should Be $True
    }
}

Describe 'Update-ZoomUserEmail' {
    $schema ='{
        "type": "object",
        "properties": {
          "email": {
            "type": "string",
            "description": "Users email. The length should be less than 128 characters.",
            "format": "email"
          }
        },
        "required": [
          "email"
        ]
      }'

    $request = Update-ZoomUserEmail -UserId $UserId -email $UserId2  @ApiKeySecret

    It 'Uses the correct method' {
        $request.Method | Should Be 'PUT'
    }

    It 'Uses the correct URI' {
        $Request.Uri | Should Be "https://api.zoom.us/v2/users/$UserId/email"
    }

    It "Validates against the JSON schema" {
        Test-Json -Json $request.Body -Schema $schema | Should Be $True
    }
}

Describe 'Update-ZoomUserPassword' {
    $schema ='{
        "type": "object",
        "properties": {
          "password": {
            "type": "string",
            "description": "User password. Should be less than 32 characters.",
            "minimum": 8
          }
        },
        "required": [
          "password"
        ]
      }'

    $request = Update-ZoomUserPassword -UserId $UserId -password 'testpassword'  @ApiKeySecret

    It 'Uses the correct method' {
        $request.Method | Should Be 'PUT'
    }

    It 'Uses the correct URI' {
        $Request.Uri | Should Be "https://api.zoom.us/v2/users/$UserId/password"
    }

    It "Validates against the JSON schema" {
        Test-Json -Json $request.Body -Schema $schema | Should Be $True
    }
}

Describe 'Update-ZoomUserSettings' {
    $schema ='{
        "title": "User settings",
        "type": "object",
        "properties": {
          "schedule_meeting": {
            "title": "User settings: Meeting settings",
            "description": "",
            "type": "object",
            "properties": {
              "host_video": {
                "type": "boolean",
                "description": "Start meetings with host video on."
              },
              "participants_video": {
                "type": "boolean",
                "description": "Start meetings with participants video on."
              },
              "audio_type": {
                "type": "string",
                "default": "voip",
                "description": "Determine how participants can join the audio portion of the meeting:<br>`both` - Telephony and VoIP.<br>`telephony` - Audio PSTN telephony only.<br>`voip` - VoIP only.<br>`thirdParty` - Third party audio conference.",
                "enum": [
                  "both",
                  "telephony",
                  "voip",
                  "thirdParty"
                ],
                "x-enum-descriptions": [
                  "Telephony and VoIP",
                  "Audio PSTN telephony only",
                  "VoIP only",
                  "3rd party audio conference"
                ]
              },
              "join_before_host": {
                "type": "boolean",
                "description": "Join the meeting before host arrives."
              },
              "force_pmi_jbh_password": {
                "type": "boolean",
                "description": "Require a password for personal meetings if attendees can join before host."
              },
              "pstn_password_protected": {
                "type": "boolean",
                "description": "Generate and require password for participants joining by phone."
              },
              "use_pmi_for_scheduled_meetings": {
                "type": "boolean",
                "description": "Use Personal Meeting ID (PMI) when scheduling a meeting\n"
              },
              "use_pmi_for_instant_meetings": {
                "type": "boolean",
                "description": "Use Personal Meeting ID (PMI) when starting an instant meeting\n"
              }
            }
          },
          "in_meeting": {
            "title": "User settings: Meeting settings",
            "description": "",
            "type": "object",
            "properties": {
              "e2e_encryption": {
                "type": "boolean",
                "description": "End-to-end encryption required for all meetings."
              },
              "chat": {
                "type": "boolean",
                "default": false,
                "description": "Enable chat during meeting for all participants."
              },
              "private_chat": {
                "type": "boolean",
                "default": false,
                "description": "Enable 1:1 private chat between participants during meetings."
              },
              "auto_saving_chat": {
                "type": "boolean",
                "default": false,
                "description": "Auto save all in-meeting chats."
              },
              "entry_exit_chime": {
                "type": "string",
                "default": "all",
                "description": "Play sound when participants join or leave:<br>`host` - When host joins or leaves.<br>`all` - When any participant joins or leaves.<br>`none` - No join or leave sound.",
                "enum": [
                  "host",
                  "all",
                  "none"
                ],
                "x-enum-descriptions": [
                  "when host joins/leaves",
                  "when any participant joins/leaves",
                  "no join/leave sound"
                ]
              },
              "record_play_voice": {
                "type": "boolean",
                "description": "Record and play their own voice."
              },
              "file_transfer": {
                "type": "boolean",
                "default": false,
                "description": "Enable file transfer through in-meeting chat."
              },
              "feedback": {
                "type": "boolean",
                "default": false,
                "description": "Enable option to send feedback to Zoom at the end of the meeting."
              },
              "co_host": {
                "type": "boolean",
                "default": false,
                "description": "Allow the host to add co-hosts."
              },
              "polling": {
                "type": "boolean",
                "default": false,
                "description": "Add polls to the meeting controls."
              },
              "attendee_on_hold": {
                "type": "boolean",
                "default": false,
                "description": "Allow host to put attendee on hold."
              },
              "annotation": {
                "type": "boolean",
                "default": false,
                "description": "Allow participants to use annotation tools."
              },
              "remote_control": {
                "type": "boolean",
                "default": false,
                "description": "Enable remote control during screensharing."
              },
              "non_verbal_feedback": {
                "type": "boolean",
                "default": false,
                "description": "Enable non-verbal feedback through screens."
              },
              "breakout_room": {
                "type": "boolean",
                "default": false,
                "description": "Allow host to split meeting participants into separate breakout rooms."
              },
              "remote_support": {
                "type": "boolean",
                "default": false,
                "description": "Allow host to provide 1:1 remote support to a participant."
              },
              "closed_caption": {
                "type": "boolean",
                "default": false,
                "description": "Enable closed captions."
              },
              "group_hd": {
                "type": "boolean",
                "default": false,
                "description": "Enable group HD video."
              },
              "virtual_background": {
                "type": "boolean",
                "default": false,
                "description": "Enable virtual background."
              },
              "far_end_camera_control": {
                "type": "boolean",
                "default": false,
                "description": "Allow another user to take control of the camera."
              },
              "share_dual_camera": {
                "type": "boolean",
                "default": false,
                "description": "Share dual camera (deprecated)."
              },
              "attention_tracking": {
                "type": "boolean",
                "default": false,
                "description": "Allow host to see if a participant does not have Zoom in focus during screen sharing."
              },
              "waiting_room": {
                "type": "boolean",
                "default": false,
                "description": "Enable Waiting room - if enabled, attendees can only join after host approves."
              },
              "allow_live_streaming": {
                "type": "boolean",
                "description": "Allow live streaming."
              },
              "workplace_by_facebook": {
                "type": "boolean",
                "description": "Allow livestreaming by host through Workplace by Facebook."
              },
              "custom_live_streaming": {
                "type": "boolean",
                "description": "Allow custom live streaming."
              },
              "custom_service_instructions": {
                "type": "string",
                "description": "Custom service instructions."
              },
              "show_meeting_control_toolbar": {
                "description": "Always show meeting controls during a meeting.",
                "type": "boolean"
              }
            }
          },
          "email_notification": {
            "title": "User settings: Notification settings",
            "description": "",
            "type": "object",
            "properties": {
              "jbh_reminder": {
                "type": "boolean",
                "default": false,
                "description": "When attendees join meeting before host."
              },
              "cancel_meeting_reminder": {
                "type": "boolean",
                "default": false,
                "description": "When a meeting is cancelled."
              },
              "alternative_host_reminder": {
                "type": "boolean",
                "default": false,
                "description": "When an alternative host is set or removed from a meeting."
              },
              "schedule_for_reminder": {
                "type": "boolean",
                "default": false,
                "description": "Notify the host there is a meeting is scheduled, rescheduled, or cancelled."
              }
            }
          },
          "recording": {
            "title": "User settings: Recording settings",
            "description": "",
            "type": "object",
            "properties": {
              "local_recording": {
                "type": "boolean",
                "description": "Local recording."
              },
              "cloud_recording": {
                "type": "boolean",
                "default": false,
                "description": "Cloud recording."
              },
              "record_speaker_view": {
                "type": "boolean",
                "default": false,
                "description": "Record the active speaker view."
              },
              "record_gallery_view": {
                "type": "boolean",
                "default": false,
                "description": "Record the gallery view."
              },
              "record_audio_file": {
                "type": "boolean",
                "default": false,
                "description": "Record an audio only file."
              },
              "save_chat_text": {
                "type": "boolean",
                "default": false,
                "description": "Save chat text from the meeting."
              },
              "show_timestamp": {
                "type": "boolean",
                "default": false,
                "description": "Show timestamp on video."
              },
              "recording_audio_transcript": {
                "type": "boolean",
                "description": "Audio transcript."
              },
              "auto_recording": {
                "type": "string",
                "default": "local",
                "description": "Automatic recording:<br>`local` - Record on local.<br>`cloud` - Record on cloud.<br>`none` - Disabled.",
                "enum": [
                  "local",
                  "cloud",
                  "none"
                ],
                "x-enum-descriptions": [
                  "Record on local",
                  "Record on cloud",
                  "Disabled"
                ]
              },
              "host_pause_stop_recording": {
                "type": "boolean",
                "default": false,
                "description": "Host can pause/stop the auto recording in the cloud."
              },
              "auto_delete_cmr": {
                "type": "boolean",
                "default": false,
                "description": "Auto delete cloud recordings."
              },
              "auto_delete_cmr_days": {
                "type": "integer",
                "description": "A specified number of days of auto delete cloud recordings.",
                "minimum": 1,
                "maximum": 60
              }
            }
          },
          "telephony": {
            "title": "User settings: Meeting settings",
            "description": "",
            "type": "object",
            "properties": {
              "third_party_audio": {
                "type": "boolean",
                "description": "Third party audio conference."
              },
              "audio_conference_info": {
                "type": "string",
                "default": "",
                "description": "Third party audio conference info.",
                "maxLength": 2048
              },
              "show_international_numbers_link": {
                "type": "boolean",
                "description": "Show the international numbers link on the invitation email."
              }
            }
          },
          "feature": {
            "title": "User settings: Feature settings",
            "description": "",
            "type": "object",
            "properties": {
              "meeting_capacity": {
                "type": "integer",
                "description": "Users meeting capacity."
              },
              "large_meeting": {
                "type": "boolean",
                "description": "Large meeting feature."
              },
              "large_meeting_capacity": {
                "type": "integer",
                "description": "Large meeting capacity: can be 500 or 1000, depending on the user has a large meeting capacity plan subscription or not."
              },
              "webinar": {
                "type": "boolean",
                "description": "Webinar feature."
              },
              "webinar_capacity": {
                "type": "integer",
                "description": "Webinar capacity: can be 100, 500, 1000, 3000, 5000 or 10000, depending on if the user has a webinar capacity plan subscription or not."
              },
              "zoom_phone": {
                "type": "boolean",
                "description": "Zoom phone feature."
              }
            }
          },
          "tsp": {
            "type": "object",
            "description": "Account Settings: TSP.",
            "title": "User settings: TSP settings",
            "properties": {
              "call_out": {
                "type": "boolean",
                "description": "Call Out"
              },
              "call_out_countries": {
                "type": "array",
                "description": "Call Out Countries/Regions"
              },
              "show_international_numbers_link": {
                "type": "boolean",
                "description": "Show international numbers link on the invitation email"
              }
            }
          }
        }
      }'

      $params = @{
        AllowLiveStreaming                  = $true
        AlternativeHostReminder             = $true
        Annotation                          = $true
        AttendeeOnHold                      = $true
        AttentionTracking                   = $true
        AudioConferenceInfo                 = $true
        AudioType                           = 'both'
        AutoDeleteCmr                       = $true
        AutoDeleteCmrDay                    = $true
        AutoRecording                       = 'local'
        AutoSavingChat                      = $true
        BreakoutRoom                        = $true
        CallOut                             = $true
        CallOutCountries                    = $true
        CancelMeetingReminder               = $true
        Chat                                = $true
        ClosedCaption                       = $true
        CloudRecording                      = $true
        CoHost                              = $true
        CustomLiveStreaming                 = $true
        CustomServiceInstructions           = $true
        E2eEncryption                       = $true
        EntryExitChim                       = 'all'
        FarEndCameraControl                 = $true
        Feedback                            = $true
        FileTransfer                        = $true
        ForcePmiJbhPassword                 = $true
        GroupHd                             = $true
        HostPauseStopRecording              = $true
        HostVideo                           = $true
        JoinBeforeHost                      = $true
        LargeMeeting                        = $true
        LargeMeetingCapacity                = $true
        LocalRecording                      = $true
        MeetingCapacity                     = $true
        NonVerbalFeedback                   = $true
        ParticipantsVideo                   = $true
        Polling                             = $true
        PrivateChat                         = $true
        PstnPasswordProtected               = $true
        RecordAudioFile                     = $true
        RecordGalleryView                   = $true
        RecordingAudioTranscrip             = $true
        RecordPlayVoic                      = $true
        RecordSpeakerView                   = $true
        RemoteControl                       = $true
        RemoteSupport                       = $true
        SaveChatText                        = $true
        ScheduleForReminder                 = $true
        ShareDualCamera                     = $true
        ShowInternationalNumbersLink        = $true
        ShowInternationalNumbersLinkTsp     = $true
        ShowTimestamp                       = $true
        ThirdPartyAudio                     = $true
        UsePmiForInstantMeetings            = $true
        UsePmiForScheduledMeetings          = $true
        UserId                              = $UserId
        VirtualBackground                   = $true
        WaitingRoom                         = $true
        Webinar                             = $true
        WebinarCapacity                     = $true
        WorkplaceByFacebook                 = $true
        ZoomPhone                           = $true
    }

    $request = Update-ZoomUserSettings @params @ApiKeySecret

    It 'Uses the correct method' {
        $request.Method | Should Be 'PATCH'
    }

    It 'Uses the correct URI' {
        $Request.Uri | Should Be "https://api.zoom.us/v2/users/$UserId/settings"
    }

    It "Validates against the JSON schema" {
        Test-Json -Json $request.Body -Schema $schema | Should Be $True
    }
}

Describe "Update-ZoomUserStatus" {
    $schema = '{
        "description": "The action.",
        "type": "object",
        "properties": {
          "action": {
            "type": "string",
            "description": "The action types:<br>`activate` - Activate a deactivated user.<br>`deactivate` - Deactivate a user.",
            "enum": [
              "activate",
              "deactivate"
            ],
            "x-enum-descriptions": [
              "set users status to active",
              "set users status to inactive"
            ]
          }
        },
        "required": [
          "action"
        ]
      }'

    $request = Update-ZoomUserStatus -UserId $UserId -action deactivate @ApiKeySecret

    It 'Uses the correct method' {
        $request.Method | Should Be 'PUT'
    }

    It 'Uses the correct URI' {
        $Request.Uri | Should Be "https://api.zoom.us/v2/users/$UserId/status"
    }

    It "Validates against the JSON schema" {
        Test-Json -Json $request.Body -Schema $schema | Should Be $True
    }
}

#Group Tests
Describe 'PSZoom Group Tests' {
    Context 'Strict mode' {
        Set-StrictMode -Version 'latest'
        $GroupCommands = @(
            'Add-ZoomGroupMember',
            'Get-ZoomGroupLockSettings',
            'Get-ZoomGroups',
            'Get-ZoomGroupSettings',
            'Get-ZoomSpecificGroup',
            'New-ZoomGroup',
            'Remove-ZoomGroup',
            'Remove-ZoomGroupMembers',
            'Update-ZoomGroup',
            'Update-ZoomGroupLockSettings',
            'Update-ZoomGroupSettings'
        )

        It 'Should load' {
            $GroupCommands | ForEach-Object {
                $GroupCommands -contains $_ | Should Be $True
            }
        }
    }
}
    
Describe "Add-ZoomGroupMember" {
    $schema = '{
            "type": "object",
            "properties": {
              "members": {
                "type": "array",
                "description": "List of Group members",
                "maximum": 30,
                "items": {
                  "type": "object",
                  "properties": {
                    "id": {
                      "type": "string",
                      "description": "User ID."
                    },
                    "email": {
                      "type": "string",
                      "description": "User email. If the user ID is given then the user email should be ignored."
                    }
                  }
                }
              }
            }
          }'
        
    $request = Add-ZoomGroupMember -GroupId $GroupId -MemberEmail $UserEmail @ApiKeySecret
        
    It "Uses the correct method" {
        $request.Method | Should Be 'POST'
    }
        
    It "Uses the correct uri" {
        $request.Uri | Should Be "https://api.zoom.us/v2/groups/$GroupId/members"
    }
        
    It "Validates against the JSON schema" {
        Test-Json -Json $request.Body -Schema $schema | Should Be $True
    }
}

Describe "Get-ZoomGroup" {
    $request = Get-ZoomGroup -GroupId $GroupId -ApiKey 123 -ApiSecret 456

    It "Uses the correct method" {
        $request.Method | Should Be 'GET'
    }
    
    It "Uses the correct uri" {
        $request.Uri | Should Be "https://api.zoom.us/v2/groups/$GroupId"
    }
}

Describe "Get-ZoomGroupLockSettings" {
    $request = Get-ZoomGroupLockSettings -GroupId $GroupId @ApiKeySecret

    It "Uses the correct method" {
        $request.Method | Should Be 'GET'
    }
    
    It "Uses the correct uri" {
        $request.Uri | Should Be "https://api.zoom.us/v2/groups/$GroupId/lock_settings"
    }
}

Describe "Get-ZoomGroups" {
    $request = Get-ZoomGroups -FullApiResponse @ApiKeySecret

    It "Uses the correct method" {
        $request.Method | Should Be 'GET'
    }
    
    It "Uses the correct uri" {
        $request.Uri | Should Be "https://api.zoom.us/v2/groups"
    }
}

Describe "Get-ZoomGroupSettings" {
    $request = Get-ZoomGroupSettings -GroupId $GroupId @ApiKeySecret

    It "Uses the correct method" {
        $request.Method | Should Be 'GET'
    }
    
    It "Uses the correct uri" {
        $request.Uri | Should Be "https://api.zoom.us/v2/groups/$GroupId/settings"
    }
}

Describe "New-ZoomGroup" {
    $schema = '{
            "type": "object",
            "properties": {
                "name": {
                "type": "string",
                "description": "Group name."
                }
            }
        }'
        
    $request = New-ZoomGroup -Name 'TestGroupName' @ApiKeySecret
    
    It "Uses the correct method" {
        $request.Method | Should Be 'POST'
    }
    
    It "Uses the correct uri" {
        $request.Uri | Should Be 'https://api.zoom.us/v2/groups'
    }
    
    It "Validates against the JSON schema" {
        Test-Json -Json $request.Body -Schema $schema | Should Be $True
    }
}

Describe 'Remove-ZoomGroup' {
    $request = Remove-ZoomGroup -GroupId $GroupId @ApiKeySecret
    
    It "Uses the correct method" {
        $request.Method | Should Be 'DELETE'
    }
    
    It "Uses the correct uri" {
        $request.Uri | Should Be "https://api.zoom.us/v2/groups/$GroupId"
    }
}

Describe 'Update-ZoomGroup' {
    $schema = '{
            "type": "object",
            "properties": {
              "name": {
                "type": "string",
                "description": "Group name. It must be unique to one account and less than 128 characters."
              }
            }
          }'
        
    $request = Update-ZoomGroup -GroupId $GroupId -Name 'NewName' @ApiKeySecret
    
    It 'Uses the correct method' {
        $request.Method | Should Be 'PATCH'
    }
    
    It 'Uses the correct uri' {
        $request.Uri | Should Be "https://api.zoom.us/v2/groups/$GroupId"
    }
    
    It 'Validates against the JSON schema' {
        Test-Json -Json $request.Body -Schema $schema | Should Be $True
    }
}

$updateGroupParams = @{
    AccountUserAccessRecording      = $true
    AlertGuestJoin                  = $true
    AllowShowZoomWindows            = $true
    AlternativeHostReminder         = $true
    Annotation                      = $true
    AttendeeOnHold                  = $true
    AttentionTracking               = $true
    AudioConferenceInfo             = 'testaudioconferenceinfo'
    AudioType                       = $true
    AutoAnswer                      = $true
    AutoRecording                   = $true
    AutoSavingChat                  = $true
    BreakoutRoom                    = $true
    CancelMeetingReminder           = $true
    Chat                            = $true
    ClosedCaption                   = $true
    CloudRecording                  = $true
    CloudRecordingAvailableReminder = $true
    CloudRecordingDownload          = $true
    CloudRecordingDownloadHost      = $true
    CoHost                          = $true
    E2eEncryption                   = $true
    EntryExitChime                  = 'testchime'
    FarEndCameraControl             = $true
    Feedback                        = $true
    FileTransfer                    = $true
    ForcePmiJbhPassword             = $true
    GroupHd                         = $true
    HostDeleteCloudRecording        = $true
    HostVideo                       = $true
    JbhReminder                     = $true
    JoinBeforeHost                  = $true
    LocalRecording                  = $true
    MuteUponEntry                   = $true
    NonVerbalFeedback               = $true
    OnlyHostViewDeviceList          = $true
    OriginalAudio                   = $true
    ParticipantVideo                = $true
    Polling                         = $true
    PostMeetingFeedback             = $true
    PrivateChat                     = $true
    PstnPasswordProtected           = $true
    RecordAudioFile                 = $true
    RecordGalleryView               = $true
    RecordingAudioTranscript        = $true
    RecordPlayOwnVoice              = $true
    RecordSpeakerView               = $true
    RemoteControl                   = $true
    RemoteSupport                   = $true
    RequirePasswordForAllMeetings   = $true
    SaveChatText                    = $true
    ScheduleForHostReminder         = $true
    ScreenSharing                   = $true
    SendingDefaultEmailInvites      = $true
    ShowBrowserJoinLink             = $true
    ShowDeviceList                  = $true
    ShowMeetingControlToolbar       = $true
    ShowTimestamp                   = $true
    StereoAudio                     = $true
    ThirdPartyAudio                 = $true
    UpcomingMeetingReminder         = $true
    UseHtmlFormatEmail              = $true
    VirtualBackground               = $true
    WaitingRoom                     = $true
    Whiteboard                      = $true
}

Describe 'Update-ZoomGroupLockSettings' -Verbose {
    $schema = '{
            "type": "object",
            "properties": {
              "schedule_meeting": {
                "type": "object",
                "properties": {
                  "host_video": {
                    "type": "boolean",
                    "description": "Start meetings with host video on."
                  },
                  "participant_video": {
                    "type": "boolean",
                    "description": "Start meetings with participant video on."
                  },
                  "audio_type": {
                    "type": "boolean",
                    "description": "Determine how participants can join the audio portion of the meeting."
                  },
                  "join_before_host": {
                    "type": "boolean",
                    "description": "Allow participants to join the meeting before the host arrives"
                  },
                  "force_pmi_jbh_password": {
                    "type": "boolean",
                    "description": "If join before host option is enabled for a personal meeting, then enforce password requirement."
                  },
                  "pstn_password_protected": {
                    "type": "boolean",
                    "description": "Generate and send new passwords for newly scheduled or edited meetings."
                  },
                  "mute_upon_entry": {
                    "type": "boolean",
                    "description": "Automatically mute all participants when they join the meeting."
                  },
                  "upcoming_meeting_reminder": {
                    "type": "boolean",
                    "description": "Receive desktop notification for upcoming meetings."
                  }
                }
              },
              "in_meeting": {
                "type": "object",
                "properties": {
                  "e2e_encryption": {
                    "type": "boolean",
                    "description": "Require that all meetings are encrypted using AES."
                  },
                  "chat": {
                    "type": "boolean",
                    "description": "Allow meeting participants to send chat message visible to all participants."
                  },
                  "private_chat": {
                    "type": "boolean",
                    "description": "Allow meeting participants to send a private 1:1 message to another participant."
                  },
                  "auto_saving_chat": {
                    "type": "boolean",
                    "description": "Automatically save all in-meeting chats."
                  },
                  "entry_exit_chime": {
                    "type": "string",
                    "description": "Play sound when participants join or leave."
                  },
                  "file_transfer": {
                    "type": "boolean",
                    "description": "Allow hosts and participants to send files through the in-meeting chat."
                  },
                  "feedback": {
                    "type": "boolean",
                    "description": "Enable users to provide feedback to Zoom at the end of the meeting."
                  },
                  "post_meeting_feedback": {
                    "type": "boolean",
                    "description": "Display end-of-meeting experience feedback survey."
                  },
                  "co_host": {
                    "type": "boolean",
                    "description": "Allow the host to add co-hosts. Co-hosts have the same in-meeting controls as the host."
                  },
                  "polling": {
                    "type": "boolean",
                    "description": "Add Polls to the meeting controls. This allows the host to survey the attendees."
                  },
                  "attendee_on_hold": {
                    "type": "boolean",
                    "description": "Allow hosts to temporarily remove an attendee from the meeting."
                  },
                  "show_meeting_control_toolbar": {
                    "type": "boolean",
                    "description": "Always show meeting controls during a meeting."
                  },
                  "allow_show_zoom_windows": {
                    "type": "boolean",
                    "description": "Show Zoom windows during screen share."
                  },
                  "annotation": {
                    "type": "boolean",
                    "description": "Allow participants to use annotation tools to add information to shared screens."
                  },
                  "whiteboard": {
                    "type": "boolean",
                    "description": "Allow participants to share a whiteboard that includes annotation tools."
                  },
                  "remote_control": {
                    "type": "boolean",
                    "description": "During screen sharing, allow the person who is sharing to let others control the shared content."
                  },
                  "non_verbal_feedback": {
                    "type": "boolean",
                    "description": "Allow participants in a meeting can provide nonverbal feedback and express opinions by clicking on icons in the Participants panel."
                  },
                  "breakout_room": {
                    "type": "boolean",
                    "description": "Allow host to split meeting participants into separate, smaller rooms."
                  },
                  "remote_support": {
                    "type": "boolean",
                    "description": "Allow meeting host to provide 1:1 remote support to another participant."
                  },
                  "closed_caption": {
                    "type": "boolean",
                    "description": "Allow host to type closed captions or assign a participant/third party device to add closed captions."
                  },
                  "far_end_camera_control": {
                    "type": "boolean",
                    "description": "Allow another user to take control of the camera during a meeting."
                  },
                  "group_hd": {
                    "type": "boolean",
                    "description": "Enable higher quality video for host and participants. This will require more bandwidth."
                  },
                  "virtual_background": {
                    "type": "boolean",
                    "description": "Enable virtual background."
                  },
                  "alert_guest_join": {
                    "type": "boolean",
                    "description": "Allow participants who belong to your account to see that a guest (someone who does not belong to your account) is participating in the meeting/webinar."
                  },
                  "auto_answer": {
                    "type": "boolean",
                    "description": "Enable users to see and add contacts to auto-answer group in the contact list on chat. Any call from members of this group will be automatically answered."
                  },
                  "sending_default_email_invites": {
                    "type": "boolean",
                    "description": "Allow users to invite participants by email only by default."
                  },
                  "use_html_format_email": {
                    "type": "boolean",
                    "description": "Allow  HTML formatting instead of plain text for meeting invitations scheduled with the Outlook plugin."
                  },
                  "stereo_audio": {
                    "type": "boolean",
                    "description": "Allow users to select stereo audio during a meeting."
                  },
                  "original_audio": {
                    "type": "boolean",
                    "description": "Allow users to select original sound during a meeting."
                  },
                  "screen_sharing": {
                    "type": "boolean",
                    "description": "Allow host and participants to share their screen or content during meetings."
                  },
                  "attention_tracking": {
                    "type": "boolean",
                    "description": "Allow the host to see an indicator in the participant panel if a meeting/webinar attendee does not have Zoom in focus during screen sharing."
                  },
                  "waiting_room": {
                    "type": "boolean",
                    "description": "Attendees cannot join a meeting until a host admits them individually from the waiting room."
                  },
                  "show_browser_join_link": {
                    "type": "boolean",
                    "description": "Allow participants to join a meeting directly from their browser."
                  }
                }
              },
              "email_notification": {
                "type": "object",
                "properties": {
                  "cloud_recording_available_reminder": {
                    "type": "boolean",
                    "description": "Notify host when cloud recording is available."
                  },
                  "jbh_reminder": {
                    "type": "boolean",
                    "description": "Notify host when participants join the meeting before them."
                  },
                  "cancel_meeting_reminder": {
                    "type": "boolean",
                    "description": "Notify host and participants when the meeting is cancelled."
                  },
                  "alternative_host_reminder": {
                    "type": "boolean",
                    "description": "Notify the alternative host who is set or removed."
                  },
                  "schedule_for_host_reminder": {
                    "type": "boolean",
                    "description": "Notify the host there is a meeting is scheduled, rescheduled, or cancelled."
                  }
                }
              },
              "recording": {
                "type": "object",
                "properties": {
                  "local_recording": {
                    "type": "boolean",
                    "description": "Allow hosts and participants to record the meeting to a local file."
                  },
                  "cloud_recording": {
                    "type": "boolean",
                    "description": "Allow hosts to record and save the meeting / webinar in the cloud."
                  },
                  "auto_recording": {
                    "type": "string",
                    "description": "Record meetings automatically as they start."
                  },
                  "cloud_recording_download": {
                    "type": "boolean",
                    "description": "Allow anyone with a link to the cloud recording to download."
                  },
                  "account_user_access_recording": {
                    "type": "boolean",
                    "description": "Make cloud recordings accessible to account members only."
                  },
                  "host_delete_cloud_recording": {
                    "type": "boolean",
                    "description": "Allow the host to delete the recordings. If this option is disabled, the recordings cannot be deleted by the host and only admin can delete them."
                  },
                  "auto_delete_cmr": {
                    "type": "boolean",
                    "description": "Allow Zoom to automatically delete recordings permanently after a specified number of days."
                  }
                }
              },
              "telephony": {
                "type": "object",
                "properties": {
                  "third_party_audio": {
                    "type": "boolean",
                    "description": "Allow users to join the meeting using the existing 3rd party audio configuration."
                  }
                }
              }
            }
          }'
        
    $request = Update-ZoomGroupLockSettings -GroupId $GroupId @updateGroupParams @ApiKeySecret
    Write-Verbose $request.body
    It 'Uses the correct method' {
        $request.Method | Should Be 'PATCH'
    }
    
    It 'Uses the correct uri' {
        $request.Uri | Should Be "https://api.zoom.us/v2/groups/$GroupId/lock_settings"
    }
    
    It 'Validates against the JSON schema' {
        Test-Json -Json $request.Body -Schema $schema | Should Be $True
    }
}

Describe 'Update-ZoomGroupSettings' {
    $schema = '{
            "type": "object",
            "properties": {
              "name": {
                "type": "string",
                "description": "Group name. It must be unique to one account and less than 128 characters."
              }
            }
          }'
        
    $request = Update-ZoomGroupSettings -GroupId $GroupId @updateGroupParams @ApiKeySecret
    
    It 'Uses the correct method' {
        $request.Method | Should Be 'PATCH'
    }
    
    It 'Uses the correct uri' {
        $request.Uri | Should Be "https://api.zoom.us/v2/groups/$GroupId/settings"
    }
    
    It 'Validates against the JSON schema' {
        Test-Json -Json $request.Body -Schema $schema | Should Be $True
    }
}

Describe "PSZoom Report Tests" {
    Context 'Strict mode' {
        Set-StrictMode -Version 'latest'

        Mock Invoke-RestMethod {
            Write-Output $Body, $Uri, $Method
        }

        $ReportCommands = @(
            'Get-ZoomActiveInactiveHostReports',
            'Get-ZoomTelephoneReports'
        )

        It 'Should load' {
            $ReportCommands | ForEach-Object {
                $ReportCommands -contains $_ | Should Be $True
            }
        }
    }
}