# How to enable event collection in Windows Server

This guide provides steps to identify Windows Event Channels and configure specific event collection settings, including SQL Server Audits.

## 1. Run (List Channels)

First, count and identify the available Event Log Channels on the system.

### 1.1 Run command

Use the **`wevtutil`** (Windows Event Utility) command with the `el` (Enum Logs) parameter. This lists all event channel names registered on the local computer.

It is recommended to redirect the output to a text file for easier searching.

```powershell
# List all event channels and save to wevtchlist.txt
wevtutil el > wevtchlist.txt
````

> **Note:** The `wevtchlist.txt` file in this repository contains the output of this command.

## 2\. Specific Configurations

### SQL Server Audit

For details on configuring SQL Server Audit to write to the **Application** channel (Event IDs 24000+):

  - [**SQL Server Audit Configuration**](sql-server.md)

## X. Useful Links

  - [**Ultimate Windows Security**](https://www.ultimatewindowssecurity.com/securitylog/encyclopedia/default.aspx) - Encyclopedia of Windows Security Log Event IDs.
  - [**Microsoft Docs: wevtutil**](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/wevtutil) - Official documentation for the Windows Event Utility.

