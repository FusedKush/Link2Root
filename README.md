<div align="center">
  <h1>Link2Root</h1>
  <p style="font-style: italic;">A simple PowerShell-based tool for creating links to nested files and folders at the root of a disk drive for easy access during development.</p>
</div>

- [The Problem](#the-problem)
- [The Solution](#the-solution)
- [Usage](#usage)
  - [*Link2Root* Portable](#link2root-portable)
    - [Using the `Link2Root` Shortcut](#using-the-link2root-shortcut)
    - [Using the `Link2Root` Command](#using-the-link2root-command)
    - [Using the PowerShell Scripts](#using-the-powershell-scripts)
    - [Using the PowerShell Module](#using-the-powershell-module)
  - [*Link2Root* Installed Locally](#link2root-installed-locally)
    - [Installing *Link2Root*](#installing-link2root)
    - [Using the `LinkThis2Root` Shortcut](#using-the-linkthis2root-shortcut)
    - [Using the `Link2Root` Command](#using-the-link2root-command-1)
    - [Using the PowerShell Module](#using-the-powershell-module-1)
    - [Uninstalling *Link2Root*](#uninstalling-link2root)
  - [The *Link2Root* PowerShell Module](#the-link2root-powershell-module)
  - [`Link2Root` Command Reference](#link2root-command-reference)
- [Frequently Asked Questions](#frequently-asked-questions)


## The Problem
For example, suppose you are working in a folder located at the following path:
```
X:\Projects\Personal\My-Super-Cool-Project\assets\scripts
```

Any time that you need to execute a command or script in that directory, you either need to specify the full path, or change directories into the folder first:
```
Get-ChildItem X:\Projects\Personal\My-Super-Cool-Project\assets\scripts
cd X:\Projects\Personal\My-Super-Cool-Project\assets\scripts
\X:\Projects\Personal\My-Super-Cool-Project\assets\scripts\my-script.bat
```

Even if you just want to open up the directory in File Explorer, you need to click through six folders just to get where you need to be.


## The Solution
That's where *Link2Root* comes in. By simply calling `Link2Root` or the underlying `New-Link2Root` PowerShell function, that long path can immediately be accessed at:
```
X:\$
```

Thus, the above commands and scripts can be executed using:
```
Get-ChildItem \$
cd \$
\$\my-script.bat
```

To open up the directory in File Explorer, you would then only need to click through two folders, rather than six.


## Usage
Start by downloading and unzipping the [latest release](https://github.com/FusedKush/Link2Root/releases/latest).

Once downloaded, *Link2Root* can be used in several ways, depending on your environment and use-case:
  - [Run Portably](#link2root-portable)
    - [Using the `Link2Root` Shortcut](#using-the-link2root-shortcut)
    - [Using the `Link2Root` Command](#using-the-link2root-command)
    - [Using the PowerShell Scripts](#using-the-powershell-scripts)
    - [Using the PowerShell Module](#using-the-powershell-module)
  - [Installed Locally](#link2root-installed-locally)
    - [Using the `LinkThis2Root` Shortcut](#using-the-linkthis2root-shortcut)
    - [Using the `Link2Root` Command](#using-the-link2root-command-1)
    - [Using the PowerShell Module](#using-the-powershell-module-1)
  - [As a PowerShell Module](#the-link2root-powershell-module)


### *Link2Root* Portable
*Link2Root* can be used completely portably. Simply move the `Link2Root/` folder to the desired location and invoke *Link2Root* in one of the following ways:
  - [Using the `Link2Root` Shortcut](#using-the-link2root-shortcut)
  - [Using the `Link2Root` Command](#using-the-link2root-command)
  - [Using the PowerShell Scripts](#using-the-powershell-scripts)
  - [Using the PowerShell Module](#using-the-powershell-module)


#### Using the `Link2Root` Shortcut
> [!IMPORTANT]
> This method only works for folders and cannot be used to create links to files.

  1. Move the `Link2Root/` folder into the directory you want to create a link to.
  2. Double-click on the `Link2Root.bat` file in the `Link2Root/` folder.
  
<video controls src="https://github.com/user-attachments/assets/e8d01898-79b0-4920-a724-ea3591929e58" title="Demonstration of Using the Link2Root Shortcut" width="1000px"></video>


#### Using the `Link2Root` Command
Simply invoke the `Link2Root` command from the directory you want to link:
```
X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> ls

    Directory: X:\Projects\Personal\My-Super-Cool-Project\assets\scripts

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d----            3/6/2026  2:59 PM                Link2Root
-a---            3/6/2026  2:56 PM             27 my-script.bat

X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> Link2Root\Link2Root
Creating Root Link: X:\$ ---> X:\Projects\Personal\My-Super-Cool-Project\assets\scripts... Success!

X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> cd /$
X:\$> ls

    Directory: X:\$

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d----            3/6/2026  2:59 PM                Link2Root
-a---            3/6/2026  2:56 PM             27 my-script.bat
```

You can customize which file or directory is linked, which drive is used, and the name of the link by passing the appropriate options to the command:
```
X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> .\my-script.bat
Hello, World!
Press any key to continue . . .

X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> Link2Root\Link2Root -Path "my-script.bat" -Shortcut "$.bat"
Creating Root Link: X:\$.bat ---> X:\Projects\Personal\My-Super-Cool-Project\assets\scripts\my-script.bat... Success!

X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> \$.bat
Hello, World!
Press any key to continue . . .
```

You can also use the `/Get`, `/Test`, and `/Remove` options to manage existing links:
```
X:\> .\Link2Root\Link2Root /Get
X:\$

X:\> .\Link2Root\Link2Root /Get -GetLinkedPath
X:\Projects\Personal\My-Super-Cool-Project\assets\scripts

X:\> .\Link2Root\Link2Root /Get -Shortcut "$.bat" -GetLinkedPath
X:\Projects\Personal\My-Super-Cool-Project\assets\scripts\my-script.bat

X:\> .\Link2Root\Link2Root /Test
True

X:\> .\Link2Root\Link2Root /Test -Shortcut "$.bat"
True

X:\> .\Link2Root\Link2Root /Test -Drive C
False

X:\> .\Link2Root\Link2Root /Remove
Removing Root Link: X:\$ ---> X:\Projects\Personal\My-Super-Cool-Project\assets\scripts... Success!

X:\> .\Link2Root\Link2Root /Remove -Shortcut "$.bat"
Removing Root Link: X:\$.bat ---> X:\Projects\Personal\My-Super-Cool-Project\assets\scripts\my-script.bat... Success!
```

For more information about the available options when invoking the `Link2Root` command, see the [`Link2Root` Command Reference](#link2root-command-reference).


#### Using the PowerShell Scripts
> [!WARNING]
> To directly invoke these scripts from the terminal, the [PowerShell Execution Policy](https://learn.microsoft.com/en-us/powershell/scripting/learn/ps101/01-getting-started#execution-policy) cannot be set to `Restricted`, as it commonly is in many enterprise environments.
>
> If you cannot change the Execution Policy to a more permissive value, use the [`Link2Root` Command](#using-the-link2root-command) instead.

You can use the PowerShell scripts located in the `/scripts` directory similarly to how you would invoke the `Link2Root` command. To link the current directory, simply invoke the `New-Link2Root.ps1` script:
```
X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> ls

    Directory: X:\Projects\Personal\My-Super-Cool-Project\assets\scripts

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d----            3/6/2026  2:59 PM                Link2Root
-a---            3/6/2026  2:56 PM             27 my-script.bat

X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> .\Link2Root\Scripts\New-Link2Root.ps1
Creating Root Link: X:\$ ---> X:\Projects\Personal\My-Super-Cool-Project\assets\scripts... Success!

X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> cd /$
X:\$> ls

    Directory: X:\$

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d----            3/6/2026  2:59 PM                Link2Root
-a---            3/6/2026  2:56 PM             27 my-script.bat
```

Similarly, you can customize which file or directory is linked, which drive is used, and the name of the link by passing the appropriate options to the script:
```
X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> .\my-script.bat
Hello, World!
Press any key to continue . . .

X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> .\Link2Root\Scripts\New-Link2Root.ps1 -Path "my-script.bat" -Shortcut "$.bat"
Creating Root Link: X:\$.bat ---> X:\Projects\Personal\My-Super-Cool-Project\assets\scripts\my-script.bat... Success!

X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> \$.bat
Hello, World!
Press any key to continue . . .
```

You can also use the `Get-Link2Root.ps1`, `Test-Link2Root.ps1`, and `Remove-Link2Root.ps1` scripts to manage existing links:
```
X:\> .\Link2Root\Scripts\Get-Link2Root.ps1
X:\$

X:\> .\Link2Root\Scripts\Get-Link2Root.ps1 -GetLinkedPath
X:\Projects\Personal\My-Super-Cool-Project\assets\scripts

X:\> .\Link2Root\Scripts\Get-Link2Root.ps1 -Shortcut "$.bat" -GetLinkedPath
X:\Projects\Personal\My-Super-Cool-Project\assets\scripts\my-script.bat

X:\> .\Link2Root\Scripts\Test-Link2Root.ps1
True

X:\> .\Link2Root\Scripts\Test-Link2Root.ps1 -Shortcut "$.bat"
True

X:\> .\Link2Root\Scripts\Test-Link2Root.ps1 -Drive C
False

X:\> .\Link2Root\Scripts\Remove-Link2Root.ps1
Removing Root Link: X:\$ ---> X:\Projects\Personal\My-Super-Cool-Project\assets\scripts... Success!

X:\> .\Link2Root\Scripts\Remove-Link2Root.ps1 -Shortcut "$.bat"
Removing Root Link: X:\$.bat ---> X:\Projects\Personal\My-Super-Cool-Project\assets\scripts\my-script.bat... Success!
```


#### Using the PowerShell Module
> [!WARNING]
> To load the module from the terminal, the [PowerShell Execution Policy](https://learn.microsoft.com/en-us/powershell/scripting/learn/ps101/01-getting-started#execution-policy) cannot be set to `Restricted`, as it commonly is in many enterprise environments.
>
> If you cannot change the Execution Policy to a more permissive value, use the [`Link2Root` Command](#using-the-link2root-command) instead.

The `Link2Root` PowerShell Module can be used in nearly the same way as the [PowerShell scripts](#using-the-powershell-scripts). To link the current directory, import the module and invoke the `New-Link2Root` function:
```
X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> ls

    Directory: X:\Projects\Personal\My-Super-Cool-Project\assets\scripts

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d----            3/6/2026  2:59 PM                Link2Root
-a---            3/6/2026  2:56 PM             27 my-script.bat

X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> Import-Module Link2Root\Link2Root.psm1
X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> New-Link2Root
Creating Root Link: X:\$ ---> X:\Projects\Personal\My-Super-Cool-Project\assets\scripts... Success!

X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> cd /$
X:\$> ls

    Directory: X:\$

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d----            3/6/2026  2:59 PM                Link2Root
-a---            3/6/2026  2:56 PM             27 my-script.bat
```

As with the PowerShell scripts, you can customize which file or directory is linked, which drive is used, and the name of the link by passing the appropriate options to the function:
```
X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> .\my-script.bat
Hello, World!
Press any key to continue . . .

X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> Import-Module Link2Root\Link2Root.psm1
X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> New-Link2Root -Path "my-script.bat" -Shortcut "$.bat"
Creating Root Link: X:\$.bat ---> X:\Projects\Personal\My-Super-Cool-Project\assets\scripts\my-script.bat... Success!

X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> \$.bat
Hello, World!
Press any key to continue . . .
```

As with the PowerShell Scripts, you can use the `Get-Link2Root` and `Test-Link2Root` functions to retrieve information about existing links:
```
X:\> Import-Module "Link2Root\Link2Root.psm1"

X:\> Get-Link2Root
X:\$

X:\> Get-Link2Root -GetLinkedPath
X:\Projects\Personal\My-Super-Cool-Project\assets\scripts

X:\> Get-Link2Root -Shortcut "$.bat" -GetLinkedPath
X:\Projects\Personal\My-Super-Cool-Project\assets\scripts\my-script.bat

X:\> Test-Link2Root
True

X:\> Test-Link2Root -Shortcut "$.bat"
True

X:\> Test-Link2Root -Drive C
False

X:\> Remove-Link2Root
Removing Root Link: X:\$ ---> X:\Projects\Personal\My-Super-Cool-Project\assets\scripts... Success!

X:\> Remove-Link2Root -Shortcut "$.bat"
Removing Root Link: X:\$.bat ---> X:\Projects\Personal\My-Super-Cool-Project\assets\scripts\my-script.bat... Success!
```


### *Link2Root* Installed Locally
While *Link2Root* can be [run portably](#link2root-portable), it can also be installed locally using the provided scripts, making it easier to create links to files and directories.

> [!NOTE]
> *Link2Root* is installed on a per-user basis.


#### Installing *Link2Root*
*Link2Root* can be installed in three ways:
  1. Clicking on or running the `Shortcuts/Install.bat` script.
  2. Running `Link2Root /Install`
  3. Running `Setup/Install-Link2Root.ps1`

> [!TIP]
> If *Link2Root* has already been installed, you can force a reinstall by running the installation script with the `-Reinstall` option.

> [!IMPORTANT]
> Regardless of the method used, you will **always** be prompted to confirm the installation unless you run the install script with the `-Force` option.

Installing the script involves three components:
  1. Copying the scripts to the `AppData/Local` folder.
  2. Copying the PowerShell Module to `Documents/PowerShell/Modules` or `Documents/WindowsPowerShell/Modules`.
  3. Adding the installed script folder to the user's `PATH`.

When clicking on the `Shortcuts/Install.bat` script or running the installation script with the `-Confirm` option, you will also be prompted for confirmation before each component is installed, allowing you to choose which ones to install.

You can also run the installation script with the `-SkipScriptInstall`, `-SkipModuleInstall`, and `-SkipPATHUpdate` options to achieve the same effect.

Once installed, you can invoke *Link2Root* in one of the following ways:
  - [Using the `LinkThis2Root` Shortcut](#using-the-linkthis2root-shortcut)
  - [Using the `Link2Root` Command](#using-the-link2root-command-1)
  - [Using the PowerShell Module](#using-the-powershell-module-1)


#### Using the `LinkThis2Root` Shortcut
> [!IMPORTANT]
> This method only works for folders and cannot be used to create links to files.

  1. Move the `LinkThis2Root.bat` file into the directory you want to create a link to.
  2. Double-click on the `LinkThis2Root.bat` file.
  
<video controls src="https://github.com/user-attachments/assets/85438de7-33c4-4eaf-971a-33ba82e7fafa" title="Demonstration of Using the LinkThis2Root Shortcut" width="1000px"></video>


#### Using the `Link2Root` Command
Simply invoke the `Link2Root` command from the directory you want to link:
```
X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> ls

    Directory: X:\Projects\Personal\My-Super-Cool-Project\assets\scripts

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a---            3/6/2026  2:56 PM             27 my-script.bat

X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> Link2Root
Creating Root Link: X:\$ ---> X:\Projects\Personal\My-Super-Cool-Project\assets\scripts... Success!

X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> cd /$
X:\$> ls

    Directory: X:\$

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a---            3/6/2026  2:56 PM             27 my-script.bat
```

You can customize which file or directory is linked, which drive is used, and the name of the link by passing the appropriate options to the command:
```
X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> .\my-script.bat
Hello, World!
Press any key to continue . . .

X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> Link2Root -Path "my-script.bat" -Shortcut "$.bat"
Creating Root Link: X:\$.bat ---> X:\Projects\Personal\My-Super-Cool-Project\assets\scripts\my-script.bat... Success!

X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> \$.bat
Hello, World!
Press any key to continue . . .
```

You can also use the `/Get`, `/Test`, and `/Remove` options to manage existing links:
```
X:\> Link2Root /Get
X:\$

X:\> Link2Root /Get -GetLinkedPath
X:\Projects\Personal\My-Super-Cool-Project\assets\scripts

X:\> Link2Root /Get -Shortcut "$.bat" -GetLinkedPath
X:\Projects\Personal\My-Super-Cool-Project\assets\scripts\my-script.bat

X:\> Link2Root /Test
True

X:\> Link2Root /Test -Shortcut "$.bat"
True

X:\> Link2Root /Test -Drive C
False

X:\> Link2Root /Remove
Removing Root Link: X:\$ ---> X:\Projects\Personal\My-Super-Cool-Project\assets\scripts... Success!

X:\> Link2Root /Remove -Shortcut "$.bat"
Removing Root Link: X:\$.bat ---> X:\Projects\Personal\My-Super-Cool-Project\assets\scripts\my-script.bat... Success!
```

For more information about the available options when invoking the `Link2Root` command, see the [`Link2Root` Command Reference](#link2root-command-reference).


#### Using the PowerShell Module
> [!WARNING]
> To load the module from the terminal, the [PowerShell Execution Policy](https://learn.microsoft.com/en-us/powershell/scripting/learn/ps101/01-getting-started#execution-policy) cannot be set to `Restricted`, as it commonly is in many enterprise environments.
>
> If you cannot change the Execution Policy to a more permissive value, use the [`Link2Root` Command](#using-the-link2root-command-1) instead.

The `Link2Root` PowerShell Module can be used similarly to how you would invoke the `Link2Root` command. To link the current directory, simply invoke the `New-Link2Root` function:
```
X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> Get-ChildItem

    Directory: X:\Projects\Personal\My-Super-Cool-Project\assets\scripts

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a---            3/6/2026  2:56 PM             27 my-script.bat

X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> New-Link2Root
Creating Root Link: X:\$ ---> X:\Projects\Personal\My-Super-Cool-Project\assets\scripts... Success!

X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> cd /$
X:\$> Get-ChildItem

    Directory: X:\$

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a---            3/6/2026  2:56 PM             27 my-script.bat
```

Similarly, you can customize which file or directory is linked, which drive is used, and the name of the link by passing the appropriate options to the function:
```
X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> .\my-script.bat
Hello, World!
Press any key to continue . . .

X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> New-Link2Root -Path "my-script.bat" -Shortcut "$.bat"
Creating Root Link: X:\$.bat ---> X:\Projects\Personal\My-Super-Cool-Project\assets\scripts\my-script.bat... Success!

X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> \$.bat
Hello, World!
Press any key to continue . . .
```

You can also use the `Get-Link2Root` and `Test-Link2Root` functions to retrieve information about existing links:
```
X:\> Get-Link2Root
X:\$

X:\> Get-Link2Root -GetLinkedPath
X:\Projects\Personal\My-Super-Cool-Project\assets\scripts

X:\> Get-Link2Root -Shortcut "$.bat" -GetLinkedPath
X:\Projects\Personal\My-Super-Cool-Project\assets\scripts\my-script.bat

X:\> Test-Link2Root
True

X:\> Test-Link2Root -Shortcut "$.bat"
True

X:\> Test-Link2Root -Drive C
False

X:\> Remove-Link2Root
Removing Root Link: X:\$ ---> X:\Projects\Personal\My-Super-Cool-Project\assets\scripts... Success!

X:\> Remove-Link2Root -Shortcut "$.bat"
Removing Root Link: X:\$.bat ---> X:\Projects\Personal\My-Super-Cool-Project\assets\scripts\my-script.bat... Success!
```


#### Uninstalling *Link2Root*
If needed, *Link2Root* can be uninstalled in three ways:
  1. Clicking on or running the `Shortcuts/Uninstall.bat` script.
  2. Running `Link2Root /Uninstall`
  3. Running `Installation/Uninstall-Link2Root.ps1`

> [!IMPORTANT]
> Regardless of the method used, you will **always** be prompted to confirm the uninstallation unless you run the uninstall script with the `-Force` option.

When clicking on the `Shortcuts/Uninstall.bat` script or running the installation script with the `-Confirm` option, you will also be prompted for confirmation before each component is uninstalled, allowing you to choose which ones to uninstall.

You can also run the installation script with the `-KeepInstall`, `-KeepModule`, and `-KeepPATH` options to achieve the same effect.


### The *Link2Root* PowerShell Module
If you primarily work in PowerShell, you can use *Link2Root* as a PowerShell Module, allowing the *Link2Root* functions to be invoked from any PowerShell session or script on the current machine.

To add *Link2Root* as a PowerShell Module on the current machine, simply move the *Link2Root* folder into `Documents/PowerShell/Modules` or `Documents/WindowsPowerShell/Modules`, whichever is present.

> [!TIP]
> To check if the module has been installed correctly, open a new PowerShell terminal and enter the following command:
> ```PowerShell
> Get-Module -Name Link2Root -ListAvailable
> ```
> If you receive output from the command, the module has been installed successfully.

> [!TIP]
> You can also use the [*Link2Root Installer*](#installing-link2root) to install the *Link2Root* PowerShell Module by running the `InstallModule.bat` script or running the installer and either manually skipping the installation of any other components, or running the installer with the `-SkipScriptInstall` and `-SkipPATHUpdate` options.

To link the current directory, you would then simply invoke the `New-Link2Root` function:
```
X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> Get-ChildItem

    Directory: X:\Projects\Personal\My-Super-Cool-Project\assets\scripts

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a---            3/6/2026  2:56 PM             27 my-script.bat

X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> New-Link2Root
Creating Root Link: X:\$ ---> X:\Projects\Personal\My-Super-Cool-Project\assets\scripts... Success!

X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> cd /$
X:\$> Get-ChildItem

    Directory: X:\$

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a---            3/6/2026  2:56 PM             27 my-script.bat
```

You can customize which file or directory is linked, which drive is used, and the name of the link by passing the appropriate options to the function:
```
X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> .\my-script.bat
Hello, World!
Press any key to continue . . .

X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> New-Link2Root -Path "my-script.bat" -Shortcut "$.bat"
Creating Root Link: X:\$.bat ---> X:\Projects\Personal\My-Super-Cool-Project\assets\scripts\my-script.bat... Success!

X:\Projects\Personal\My-Super-Cool-Project\assets\scripts> \$.bat
Hello, World!
Press any key to continue . . .
```

You can also use the `Get-Link2Root` and `Test-Link2Root` functions to retrieve information about existing links:
```
X:\> Get-Link2Root
X:\$

X:\> Get-Link2Root -GetLinkedPath
X:\Projects\Personal\My-Super-Cool-Project\assets\scripts

X:\> Get-Link2Root -Shortcut "$.bat" -GetLinkedPath
X:\Projects\Personal\My-Super-Cool-Project\assets\scripts\my-script.bat

X:\> Test-Link2Root
True

X:\> Test-Link2Root -Shortcut "$.bat"
True

X:\> Test-Link2Root -Drive C
False

X:\> Remove-Link2Root
Removing Root Link: X:\$ ---> X:\Projects\Personal\My-Super-Cool-Project\assets\scripts... Success!

X:\> Remove-Link2Root -Shortcut "$.bat"
Removing Root Link: X:\$.bat ---> X:\Projects\Personal\My-Super-Cool-Project\assets\scripts\my-script.bat... Success!
```


### `Link2Root` Command Reference
#### `Link2Root /New`, `New-Link2Root.ps1`, and `New-Link2Root`
```
Link2Root [/N | /New] [/?] [/P | /NoPause]
          [[-Path] <String>] [[-Shortcut] <String>] [[-Drive] <String>] [-NoClobber] [-PassThru] [-Silent]
          [-WhatIf] [-Confirm] [<CommonParameters>]
```
```
New-Link2Root.ps1 [[-Path] <String>] [[-Shortcut] <String>] [[-Drive] <String>] [-NoClobber] [-PassThru] [-Silent]
                  [-WhatIf] [-Confirm] [<CommonParameters>]
```
```
New-Link2Root [[-Path] <String>] [[-Shortcut] <String>] [[-Drive] <String>] [-NoClobber] [-PassThru] [-Silent]
              [-WhatIf] [-Confirm] [<CommonParameters>]
```

##### `/?`
Display help information for the command.


##### `/P | /NoPause`
Skip pausing the command at the very end.


##### `-Path <String>`
The path to create a link at the root of the drive to. The path can point to either a file or directory.

Defaults to the Current Working Directory, or one directory higher if within the root `Link2Root` directory.


##### `-Shortcut <String>`
The name of the shortcut link to create at the root of the designated drive.

Defaults to `$`.

> [!IMPORTANT]
> In general, the shortcut link must have the same file extension as the file being linked in order to work properly.


##### `-Drive <String>`
The letter of the disk drive in which to place the shortcut link at the root of.

For example, `C` or `x`.

Defaults to the disk drive containing the specified [`-Path`](#-path-string).

> [!IMPORTANT]
> You can only create cross-drive links for *directories*. You **cannot** create cross-drive links for *files*.


##### `-NoClobber`
Indicates that if an existing shortcut link of the same name already exists on the designated drive, it will not be overwritten.

By default and when this switch is omitted, existing shortcuts of the same name will automatically be overwritten.


##### `-PassThru`
Indicates that this function should return a boolean value indicating whether or not the specified location was successfully linked to the root of the designated drive or not.

By default and when this switch is omitted, the commands do not return anything.


##### `-Silent`
Indicates that the results of the function should not be written to the host.

By default and when this switch is omitted, the results of the command are written to the host, potentially in addition to being returned if the [`-PassThru`](#-passthru) switch is also used.


##### `-WhatIf`
Displays a message that describes the effect of the command, instead of executing the command.

For more information, see [PowerShell Risk Management Parameters](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_commonparameters?view=powershell-5.1#risk-management-parameters).


##### `-Confirm`
Prompts you for confirmation before executing the command.

For more information, see [PowerShell Risk Management Parameters](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_commonparameters?view=powershell-5.1#risk-management-parameters).


##### `<CommonParameters>`
These commands support the [*Common PowerShell Parameters*](https://go.microsoft.com/fwlink/?LinkID=113216), which differ based on the version of PowerShell you are using.


#### `Link2Root /Get`, `Get-Link2Root.ps1`, and `Get-Link2Root`
```
Link2Root [/G | /Get] [/?] [/P | /NoPause]
          [[-Drive] <String>] [[-Shortcut] <String>] [-GetLinkedPath] [<CommonParameters>]
```
```
Get-Link2Root.ps1 [[-Drive] <String>] [[-Shortcut] <String>] [-GetLinkedPath] [<CommonParameters>]
```
```
Get-Link2Root [[-Drive] <String>] [[-Shortcut] <String>] [-GetLinkedPath] [<CommonParameters>]
```


##### `/?`
Display help information for the command.


##### `/P | /NoPause`
Skip pausing the command at the very end.


##### `-Drive <String>`
The letter of the disk drive in which to retrieve the shortcut link at the root for.

For example, `C` or `x`.

Defaults to the disk drive containing the Current Working Directory.


##### `-Shortcut <String>`
The name of the shortcut link to retrieve at the root of the designated drive.

Defaults to `$`.


##### `-GetLinkedPath`
Indicates that the linked path of an existing shortcut with the given name on the designated drive should be returned instead.

By default and when this parameter is omitted, this function returns the path to the shortcut itself.


##### `<CommonParameters>`
These commands support the [*Common PowerShell Parameters*](https://go.microsoft.com/fwlink/?LinkID=113216), which differ based on the version of PowerShell you are using.


#### `Link2Root /Test`, `Test-Link2Root.ps1`, and `Test-Link2Root`
```
Link2Root [/T | /Test] [/?] [/P | /NoPause]
          [[-Drive] <String>] [[-Shortcut] <String>] [[-Path] <String>] [<CommonParameters>]
```
```
Test-Link2Root.ps1 [[-Drive] <String>] [[-Shortcut] <String>] [[-Path] <String>] [<CommonParameters>]
```
```
Test-Link2Root [[-Drive] <String>] [[-Shortcut] <String>] [[-Path] <String>] [<CommonParameters>]
```


##### `/?`
Display help information for the command.


##### `/P | /NoPause`
Skip pausing the command at the very end.


##### `-Drive <String>`
The letter of the disk drive in which to search for the shortcut link at the root of.

For example, `C` or `x`.

Defaults to the disk drive containing the Current Working Directory.


##### `-Shortcut <String>`
The name of the shortcut link to search for at the root of the designated drive.

Defaults to `$`.


##### `-Path <String>`
The target path to test any matching shortcut links for.

When this parameter is specified, the commands will *also* check if the existing shortcut link has the same path as this parameter value. When omitted, the commands will only check if an existing shortcut link exists.


##### `<CommonParameters>`
These commands support the [*Common PowerShell Parameters*](https://go.microsoft.com/fwlink/?LinkID=113216), which differ based on the version of PowerShell you are using.


#### `Link2Root /Remove`, `Remove-Link2Root.ps1`, and `Remove-Link2Root`
```
Link2Root [/R | /Remove] [/?] [/P | /NoPause]
          [[-Drive] <String>] [[-Shortcut] <String>] [-PassThru] [-Silent]
          [-WhatIf] [-Confirm] [<CommonParameters>]
```
```
Remove-Link2Root.ps1 [[-Drive] <String>] [[-Shortcut] <String>] [-PassThru] [-Silent]
                     [-WhatIf] [-Confirm] [<CommonParameters>]
```
```
Remove-Link2Root [[-Drive] <String>] [[-Shortcut] <String>] [-PassThru] [-Silent]
                 [-WhatIf] [-Confirm] [<CommonParameters>]
```


##### `/?`
Display help information for the command.


##### `/P | /NoPause`
Skip pausing the command at the very end.


##### `-Drive <String>`
The letter of the disk drive in which to search for the shortcut link at the root of.

For example, `C` or `x`.

Defaults to the disk drive containing the Current Working Directory.


##### `-Shortcut <String>`
The name of the shortcut link to remove at the root of the designated drive.

Defaults to `$`.


##### `-PassThru`
Indicates that this function should return a boolean value indicating whether or not the specified location was successfully linked to the root of the designated drive or not.

By default and when this switch is omitted, the commands do not return anything.


##### `-Silent`
Indicates that the results of the function should not be written to the host.

By default and when this switch is omitted, the results of the command are written to the host, potentially in addition to being returned if the [`-PassThru`](#-passthru-1) switch is also used.


##### `-WhatIf`
Displays a message that describes the effect of the command, instead of executing the command.

For more information, see [PowerShell Risk Management Parameters](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_commonparameters?view=powershell-5.1#risk-management-parameters).


##### `-Confirm`
Prompts you for confirmation before executing the command.

For more information, see [PowerShell Risk Management Parameters](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_commonparameters?view=powershell-5.1#risk-management-parameters).


##### `<CommonParameters>`
These commands support the [*Common PowerShell Parameters*](https://go.microsoft.com/fwlink/?LinkID=113216), which differ based on the version of PowerShell you are using.


## Frequently Asked Questions
1. > File Link2Root\Scripts\New-Link2Root.ps1 cannot be loaded because running scripts is disabled on this system.
   > 
   > File Link2Root\Scripts\Get-Link2Root.ps1 cannot be loaded because running scripts is disabled on this system.
   >
   > File Link2Root\Scripts\Test-Link2Root.ps1 cannot be loaded because running scripts is disabled on this system.
   >
   > File Link2Root\Scripts\Remove-Link2Root.ps1 cannot be loaded because running scripts is disabled on this system.
   >
   > File Link2Root\Link2Root.psm1 cannot be loaded because running scripts is disabled on this system.
   
   You either need to change the [PowerShell Execution Policy](https://learn.microsoft.com/en-us/powershell/scripting/learn/ps101/01-getting-started?view=powershell-7.5#execution-policy) on your machine or use the [`Link2Root` Command](#using-the-link2root-command) instead.
  
2. > Failed! Access is denied

   Ensure you have the appropriate permissions to create the link in the root of the specified drive and for the linked file or directory. If linking to a file, ensure that the shortcut is not being created on a different drive.
