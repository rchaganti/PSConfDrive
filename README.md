# PowerShell Conference EU - Agenda as PowerShell Drive #
The SHiPS module has several use cases with structured data. I have written a few proof-of-concept modules using SHiPS to understand how it works and try out different design patterns.

One of my sessions at PowerShell Conference EU 2018 is around using SHiPS. In the process of creating different demos for this session, I started implementing PS drives for several different things. One such module I created enables the ability to browse PowerShell Conference EU 2018 agenda as a PowerShell drive. I have an intial draft of this module at https://github.com/rchaganti/PSConfDrive. 

## How to install the module?
Since this is still a very early version of the module, you need to download the [zip archive](https://github.com/rchaganti/PSConfDrive/archive/master.zip) of the GitHub repository and extract it to a folder represented by `$env:PSModulePath`. You will require the SHiPS module as well. This can be downloaded from the PowerShell Gallery.

    Install-Module -Name SHiPS -Force

The following commands will load the modules and map a PS drive.

    Import-Module SHiPS -Force
    Import-Module PSConfDrive -Force
    New-PSDrive -Name PSConfEU -PSProvider SHiPS -Root psconfdrive#psconfeu

Here is how you can use this PS drive for exploring the conference agenda.

![](https://i.imgur.com/cgdueER.gif)

Once again, this is a POC only and the design still needs to be and can be optimized. If you plan to attend PSConfEU 2018, come to my session on SHiPS to understand how to use the module and choose the right design pattern for your modules. 