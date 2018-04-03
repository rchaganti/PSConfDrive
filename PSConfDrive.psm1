using namespace Microsoft.PowerShell.SHiPS

#Load the PSConf Agenda from agenda.json


[SHiPSProvider()]
class PSConfEU : SHiPSDirectory
{
    #Default constructor
    PSConfEU([string]$name): base($name)
    {        
    }

    [object[]] GetChildItem()
    {
        $obj = @()
        $agenda = Get-Content -Path "$PSScriptRoot\agenda.json" -raw | ConvertFrom-Json
        $agendaDate = Get-AgendaDate -agenda $agenda
        $dayCounter = 1
        foreach ($day in $agendaDate)
        {
            $obj += [PSConfEUDay]::new("Day$dayCounter", $day)
            $dayCounter += 1
        }

        $obj += [PSConfEUSpeaker]::new('Speakers')
        return $obj
    }
}

[SHiPSProvider()]
class PSConfEUSpeaker : SHiPSDirectory
{
    [string] $date
    
    PSConfEUSpeaker([string]$name): base($name)
    {
    }

    [object[]] GetChildItem()
    {
        $obj = @()
        $speakers = Get-Content -Path "$PSScriptRoot\Speakers.json" -raw | ConvertFrom-Json
        foreach ($speaker in $speakers)
        {
            $obj += [PSConfEUSpeakerBIO]::New($speaker.name, $speaker)
        }
        return $obj
    }
}

[SHiPSProvider()]
class PSConfEUSpeakerBIO : SHiPSLeaf
{
    [string] $country
    [string] $company
    [string] $twitter
    [bool] $MVP
    [string] $bio

    Hidden [object] $speakerData = $null
    
    PSConfEUSpeakerBIO() : base ()
    {
    }
  
    PSConfEUSpeakerBIO([String] $name, [Object] $speakerData): base($name)
    {
      $this.speakerData = $speakerData
      $this.country = $speakerData.country
      $this.company = $speakerData.company
      $this.Twitter = $speakerData.Twitter
      $this.MVP = $speakerData.MVP
      $this.BIO = $speakerData.BIO
    }
}

[SHiPSProvider()]
class PSConfEUDay : SHiPSDirectory
{
    [string] $date
    
    PSConfEUDay([string]$name, [string]$date): base($name)
    {
        $this.date = $date
    }

    [object[]] GetChildItem()
    {
        $obj = @()
        $obj += [PSConfEUSessionByDay]::new('All', $this.date)
        $obj += [PSConfEUSessionBySpeaker]::new('BySpeaker', $this.date)
        $obj += [PSConfEUSessionByCategory]::new('ByCategory', $this.date)
        return $obj
    }
}

[SHiPSProvider()]
class PSConfEUSession : SHiPSLeaf
{
    [string] $title
    [string] $speaker
    [datetime] $startTime
    [string] $type
    [int] $track
    [string] $abstract
    [string] $category

    Hidden [object] $sessionData = $null
    
    PSConfEUSession() : base ()
    {
    }
  
    PSConfEUSession([String] $name, [Object] $sessionData): base($name)
    {
      $this.sessionData = $sessionData
  
      $this.title = $sessionData.title
      $this.speaker = $sessionData.speaker
      $this.startTime = [datetime] $sessionData.startTime
      $this.type = $sessionData.type
      $this.track = [int] $sessionData.track
      $this.abstract = $sessionData.abstract
      $this.category = $sessionData.category
    }
}

[SHiPSProvider()]
class PSConfEUSessionByDay : SHiPSDirectory
{
    [string] $date
    
    PSConfEUSessionByDay([string]$name, [string]$date): base($name)
    {
        $this.date = $date
    }

    [object[]] GetChildItem()
    {
        $obj = @()
        $agenda = Get-Content -Path "$PSScriptRoot\agenda.json" -raw | ConvertFrom-Json
        $sessions = Get-AgendaItem -agenda $agenda -ByDate $this.date
        foreach ($session in $sessions)
        {
            $obj += [PSConfEUSession]::new($session.Id, $session)
        }

        return $obj
    }
}

[SHiPSProvider()]
class PSConfEUSessionBySpeaker : SHiPSDirectory
{
    [string] $date
    
    PSConfEUSessionBySpeaker([string]$name, [string]$date): base($name)
    {
        $this.date = $date
    }

    [object[]] GetChildItem()
    {
        $obj = @()
        $agenda = Get-Content -Path "$PSScriptRoot\agenda.json" -raw | ConvertFrom-Json
        $speakers = Get-AgendaSpeaker -agenda $agenda
        foreach ($speaker in $speakers)
        {
            $obj += [PSConfEUSessionSpeaker]::new($speaker, $this.date)
        }
        return $obj
    }
}

[SHiPSProvider()]
class PSConfEUSessionSpeaker : SHiPSDirectory
{
    [string] $date
    
    PSConfEUSessionSpeaker([string]$name, [string]$date): base($name)
    {
        $this.date = $date
    }

    [object[]] GetChildItem()
    {
        $obj = @()
        $agenda = Get-Content -Path "$PSScriptRoot\agenda.json" -raw | ConvertFrom-Json        
        $allDaySessions = Get-AgendaItem -agenda $agenda -BySpeaker $this.name
        $speakerSessions = $allDaySessions | Where-Object {$_.StartTime -like "*$($this.Date)*"}
        foreach ($session in $speakerSessions)
        {
            $obj += [PSConfEUSession]::new($session.id, $session)
        }
        return $obj
    }
}

[SHiPSProvider()]
class PSConfEUSessionByCategory : SHiPSDirectory
{
    [string] $date
    
    PSConfEUSessionByCategory([string]$name, [string]$date): base($name)
    {
        $this.date = $date
    }

    [object[]] GetChildItem()
    {
        $obj = @()
        $agenda = Get-Content -Path "$PSScriptRoot\agenda.json" -raw | ConvertFrom-Json        
        $allCategories = Get-AgendaCategory -agenda $agenda
        foreach ($category in $allCategories)
        {
            if ($category)
            {
                $obj += [PSConfEUSessionCategory]::new($category, $this.date)
            }
        }            
        return $obj
    }
}

[SHiPSProvider()]
class PSConfEUSessionCategory : SHiPSDirectory
{
    [string] $date
    
    PSConfEUSessionCategory([string]$name, [string]$date): base($name)
    {
        $this.date = $date
    }

    [object[]] GetChildItem()
    {
        $obj = @()
        $agenda = Get-Content -Path "$PSScriptRoot\agenda.json" -raw | ConvertFrom-Json 
        $allCatergorySessions = Get-AgendaItem -agenda $agenda -ByCategory $this.name
        $daySessions = $allCatergorySessions | Where-Object {$_.StartTime -like "*$($this.date)*"}
        foreach ($session in $daySessions)
        {
            $obj += [PSConfEUSession]::new($session.id, $session)
        }
        return $obj
    }
}

#region Supporting functions
function Get-AgendaDate
{
    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory = $true)]
        [Object]
        $agenda
    )

    $uniqueDates = $agenda.StartTime.Foreach({ $_.Split(' ')[0] }) | Select-Object -Unique
    return $uniqueDates
}

function Get-AgendaSpeaker
{
    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory = $true)]
        [Object]
        $agenda
    )

    $uniqueSpeakers = $agenda.Speaker.Foreach({ $_.Split(',') }).Trim() | Select-Object -Unique
    return $uniqueSpeakers
}

function Get-AgendaCategory
{
    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory = $true)]
        [Object]
        $agenda
    )

    $uniqueCategories = $agenda.Category | Select-Object -Unique
    return $uniqueCategories    
}

function Get-AgendaItem
{
    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory = $true)]
        [Object]
        $agenda,

        [Parameter()]
        [String]
        $ByDate,

        [Parameter()]
        [String]
        $ByCategory,
        
        [Parameter()]
        [String]
        $BySpeaker  
    )

    if ($ByDate)
    {
        if ($ByDate -eq 'AllDays')
        {
            return $agenda
        }
        else
        {
            $agenda.Where({$_.StartTime -like "*$ByDate*"})    
        }
    }
    elseif ($ByCategory)
    {
        $agenda.Where({$_.Category -like $ByCategory})
    }
    elseif ($BySpeaker)
    {
        $agenda.Where({$_.Speaker -like "*$BySpeaker*"})
    }
}
#endregion