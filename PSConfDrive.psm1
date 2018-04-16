using namespace Microsoft.PowerShell.SHiPS

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
            $obj += [PSConfEUDay]::new("Day$dayCounter", $day, $agenda)
            $dayCounter += 1
        }

        $obj += [PSConfEUSpeaker]::new('Speakers',$agenda)
        return $obj
    }
}

[SHiPSProvider()]
class PSConfEUSpeaker : SHiPSDirectory
{
    hidden [object] $agenda
    
    PSConfEUSpeaker([string]$name, [object]$agenda): base($name)
    {
        $this.agenda = $agenda
    }

    [object[]] GetChildItem()
    {
        $obj = @()
        $speakers = Get-Content -Path "$PSScriptRoot\Speakers.json" -raw | ConvertFrom-Json
        foreach ($speaker in $speakers)
        {
            $obj += [PSConfEUSpeakerBIO]::New($speaker.name, $speaker, $this.agenda, $null)
        }
        return $obj
    }
}

[SHiPSProvider()]
class PSConfEUSpeakerBIO : SHiPSDirectory
{
    [string] $country
    [string] $company
    [string] $twitter
    [bool] $MVP
    [string] $bio

    Hidden [object] $speakerData
    Hidden [object] $agenda
    [string] $date
    
    PSConfEUSpeakerBIO():base()
    {
    }
  
    PSConfEUSpeakerBIO([String] $name, [Object] $speakerData, [Object]$agenda, [string]$date): base($name)
    {
      $this.speakerData = $speakerData
      $this.agenda = $agenda
      $this.country = $speakerData.country
      $this.company = $speakerData.company
      $this.Twitter = $speakerData.Twitter
      $this.MVP = $speakerData.MVP
      $this.BIO = $speakerData.BIO
      $this.Date = $date
    }

    [object[]] GetChildItem()
    {
        $obj = @()
        $speakerSessions = Get-AgendaItem -BySpeaker $this.name -agenda $this.agenda
        
        if ($this.date -ne $null)
        {
            $speakerSessions = $speakerSessions.Where({$_.StartTime -like "*$($this.date)*"})
        }

        foreach ($session in $speakerSessions)
        {
            $obj += [PSConfEUSession]::New($session.Id, $session)
        }
        return $obj
    }    
}

[SHiPSProvider()]
class PSConfEUDay : SHiPSDirectory
{
    hidden [object] $agenda
    [string] $date
    
    PSConfEUDay([string]$name, [string]$date, [object]$agenda): base($name)
    {
        $this.agenda = $agenda
        $this.date = $date
    }

    [object[]] GetChildItem()
    {
        $obj = @()
        $obj += [PSConfEUSessionByDay]::new('All', $this.date, $this.agenda)
        $obj += [PSConfEUSessionBySpeaker]::new('BySpeaker', $this.date, $this.agenda)
        $obj += [PSConfEUSessionByCategory]::new('ByCategory', $this.date, $this.agenda)
        $obj += [PSConfEUNextSession]::new('Next', $this.date, $this.agenda)
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
    hidden [object] $agenda
    
    PSConfEUSessionByDay([string]$name, [string]$date, [object]$agenda): base($name)
    {
        $this.agenda = $agenda
        $this.date = $date
    }

    [object[]] GetChildItem()
    {
        $obj = @()
        $sessions = Get-AgendaItem -agenda $this.agenda -ByDate $this.date
        foreach ($session in $sessions)
        {
            $obj += [PSConfEUSession]::new($session.Id, $session)
        }

        return $obj
    }
}

[SHiPSProvider()]
class PSConfEUNextSession : SHiPSDirectory
{
    [string] $date
    hidden [object] $agenda
    
    PSConfEUNextSession([string]$name, [string]$date, [object]$agenda): base($name)
    {
        $this.agenda = $agenda
        $this.date = $date
    }

    [object[]] GetChildItem()
    {
        $obj = @()
        $sessions = Get-AgendaItem -agenda $this.agenda -ByDate $this.date        
        $upcomingSessions = $sessions.Where({[DateTime]$_.StartTime -gt (Get-Date)})
        foreach ($session in $upcomingSessions)
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
    hidden [object] $agenda
    
    PSConfEUSessionBySpeaker([string]$name, [string]$date, [object]$agenda): base($name)
    {
        $this.date = $date
        $this.agenda = $agenda
    }

    [object[]] GetChildItem()
    {
        $obj = @()
        $daySpeakers = Get-AgendaSpeaker -agenda $this.Agenda -ByDate $this.date
        $allSpeakers = Get-Content -Path "$PSScriptRoot\Speakers.json" -raw | ConvertFrom-Json
        foreach ($speaker in $allSpeakers)
        {
            if ($daySpeakers -Contains $speaker.Name)
            {
                $obj += [PSConfEUSpeakerBIO]::New($speaker.name, $speaker, $this.agenda, $this.date)
            }
        }
        return $obj
    }
}

[SHiPSProvider()]
class PSConfEUSessionSpeaker : SHiPSDirectory
{
    [string] $date
    hidden [object] $agenda
    
    PSConfEUSessionSpeaker([string]$name, [string]$date, [object]$agenda): base($name)
    {
        $this.date = $date
        $this.agenda = $agenda
    }

    [object[]] GetChildItem()
    {
        $obj = @()     
        $allDaySessions = Get-AgendaItem -agenda $this.agenda -BySpeaker $this.name
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
    hidden [object] $agenda
    
    PSConfEUSessionByCategory([string]$name, [string]$date, [object]$agenda): base($name)
    {
        $this.date = $date
        $this.agenda = $agenda
    }

    [object[]] GetChildItem()
    {
        $obj = @()    
        $allCategories = Get-AgendaCategory -agenda $this.agenda
        foreach ($category in $allCategories)
        {
            if ($category)
            {
                $obj += [PSConfEUSessionCategory]::new($category, $this.date, $this.agenda)
            }
        }            
        return $obj
    }
}

[SHiPSProvider()]
class PSConfEUSessionCategory : SHiPSDirectory
{
    [string] $date
    hidden [object] $agenda
    
    PSConfEUSessionCategory([string]$name, [string]$date, [object]$agenda): base($name)
    {
        $this.date = $date
        $this.agenda = $agenda
    }

    [object[]] GetChildItem()
    {
        $obj = @()        
        $allCatergorySessions = Get-AgendaItem -agenda $this.agenda -ByCategory $this.name
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
        $agenda,

        [Parameter(Mandatory = $true)]
        [string]
        $ByDate
    )

    $daySpeakers = $agenda.Where({$_.StartTime -like "*$ByDate*"}).Speaker
    $uniqueSpeakers = $daySpeakers.Foreach({ $_.Split(',') }).Trim() | Select-Object -Unique
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