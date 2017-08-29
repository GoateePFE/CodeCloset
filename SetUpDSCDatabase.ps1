break

# Download SQL Express & Mgmt Studeio installs from http://downloadsqlserverexpress.com
# Manually install SQL 2016 Express, choose the LocalDB option
# Manually install SQL Management Studio
# REBOOT THE SERVER so that the SQLPS module is available


break
# After comments above are complete, run this code to create the DSC database for testing.

$DBInstance = "dscdb"

## Update this path
$ServersCSVPath = 'C:\Users\administrator.CONTOSO\Documents\servers.csv'

# Create this path, and place the servers.csv file into it
$DBPath = "C:\DSCDB\$DBInstance"
New-Item -ItemType Directory -Path $DBPath -ErrorAction SilentlyContinue -Force | Out-Null
Copy-Item -Path $ServersCSVPath -Destination $DBPath

# Create the SQL LocalDB instance to host the database
sqllocaldb create "$DBInstance" -s

# BULK INSERT does not like quotes in the import. Clean the file first.
If (Test-Path "$DBPath\servers.csv") {
    (Get-Content "$DBPath\servers.csv").Replace('"',$null) | Set-Content "$DBPath\servers.csv"
} Else {
    Write-Warning "Copy the servers.csv into $DBPath before proceeding."
    break
}


$DBScript = @"

USE [master]
GO

/****** Object:  Database [dscdatabase]    Script Date: 1/5/2017 9:15:25 PM ******/
CREATE DATABASE [dscdatabase]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'dscdatabase', FILENAME = N'$DBPath\dscdatabase.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'dscdatabase_log', FILENAME = N'$DBPath\dscdatabase_log.ldf' , SIZE = 73728KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO

ALTER DATABASE [dscdatabase] SET COMPATIBILITY_LEVEL = 130
GO

IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [dscdatabase].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO

ALTER DATABASE [dscdatabase] SET ANSI_NULL_DEFAULT OFF 
GO

ALTER DATABASE [dscdatabase] SET ANSI_NULLS OFF 
GO

ALTER DATABASE [dscdatabase] SET ANSI_PADDING OFF 
GO

ALTER DATABASE [dscdatabase] SET ANSI_WARNINGS OFF 
GO

ALTER DATABASE [dscdatabase] SET ARITHABORT OFF 
GO

ALTER DATABASE [dscdatabase] SET AUTO_CLOSE OFF 
GO

ALTER DATABASE [dscdatabase] SET AUTO_SHRINK OFF 
GO

ALTER DATABASE [dscdatabase] SET AUTO_UPDATE_STATISTICS ON 
GO

ALTER DATABASE [dscdatabase] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO

ALTER DATABASE [dscdatabase] SET CURSOR_DEFAULT  GLOBAL 
GO

ALTER DATABASE [dscdatabase] SET CONCAT_NULL_YIELDS_NULL OFF 
GO

ALTER DATABASE [dscdatabase] SET NUMERIC_ROUNDABORT OFF 
GO

ALTER DATABASE [dscdatabase] SET QUOTED_IDENTIFIER OFF 
GO

ALTER DATABASE [dscdatabase] SET RECURSIVE_TRIGGERS OFF 
GO

ALTER DATABASE [dscdatabase] SET  DISABLE_BROKER 
GO

ALTER DATABASE [dscdatabase] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO

ALTER DATABASE [dscdatabase] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO

ALTER DATABASE [dscdatabase] SET TRUSTWORTHY OFF 
GO

ALTER DATABASE [dscdatabase] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO

ALTER DATABASE [dscdatabase] SET PARAMETERIZATION SIMPLE 
GO

ALTER DATABASE [dscdatabase] SET READ_COMMITTED_SNAPSHOT OFF 
GO

ALTER DATABASE [dscdatabase] SET HONOR_BROKER_PRIORITY OFF 
GO

ALTER DATABASE [dscdatabase] SET RECOVERY SIMPLE 
GO

ALTER DATABASE [dscdatabase] SET  MULTI_USER 
GO

ALTER DATABASE [dscdatabase] SET PAGE_VERIFY CHECKSUM  
GO

ALTER DATABASE [dscdatabase] SET DB_CHAINING OFF 
GO

ALTER DATABASE [dscdatabase] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO

ALTER DATABASE [dscdatabase] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO

ALTER DATABASE [dscdatabase] SET DELAYED_DURABILITY = DISABLED 
GO

ALTER DATABASE [dscdatabase] SET QUERY_STORE = OFF
GO

USE [dscdatabase]
GO

ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP = 0;
GO

ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET MAXDOP = PRIMARY;
GO

ALTER DATABASE SCOPED CONFIGURATION SET LEGACY_CARDINALITY_ESTIMATION = OFF;
GO

ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET LEGACY_CARDINALITY_ESTIMATION = PRIMARY;
GO

ALTER DATABASE SCOPED CONFIGURATION SET PARAMETER_SNIFFING = ON;
GO

ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET PARAMETER_SNIFFING = PRIMARY;
GO

ALTER DATABASE SCOPED CONFIGURATION SET QUERY_OPTIMIZER_HOTFIXES = OFF;
GO

ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET QUERY_OPTIMIZER_HOTFIXES = PRIMARY;
GO

ALTER DATABASE [dscdatabase] SET  READ_WRITE 
GO


USE [dscdatabase]
GO

/****** Object:  Table [dbo].[Servers]    Script Date: 1/5/2017 9:16:55 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[Servers](
	[Server_Id] [int] NOT NULL,
	[Status] [varchar](1) NULL,
	[HardwarePlatform] [varchar](1) NULL
PRIMARY KEY CLUSTERED 
(
	[Server_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

USE [dscdatabase]
GO

/****** Object:  Table [dbo].[Nodes]    Script Date: 1/5/2017 9:16:40 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[Nodes](
	[Node_Id] [int] IDENTITY,
	[Server_Id] [int] NOT NULL,
	[Hostname] [varchar](30) NULL,
	[Environment] [varchar](30) NULL,
	[AgentID] [varchar](36) NULL,
	[Role] [varchar](20) NULL,
	[CertificatePath] [varchar](200) NULL,
	[CertificateThumbprint] [varchar](40) NULL,
PRIMARY KEY CLUSTERED 
(
	[Node_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[Nodes]  WITH CHECK ADD  CONSTRAINT [FK_Nodes_Servers] FOREIGN KEY([Server_Id])
REFERENCES [dbo].[Servers] ([Server_Id])
GO

ALTER TABLE [dbo].[Nodes] CHECK CONSTRAINT [FK_Nodes_Servers]
GO

USE [dscdatabase]
GO

BULK INSERT [dscdatabase].[dbo].[Servers]
FROM '$DBPath\Servers.csv'
WITH (
FIELDTERMINATOR = '|',
ROWTERMINATOR = '\n'
)
GO


USE [dscdatabase]
GO

/****** Object:  View [dbo].[vAllNodesWithData]    Script Date: 1/6/2017 8:19:23 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vAllNodesWithData]
AS
SELECT        dbo.Nodes.Hostname, dbo.Nodes.Environment, dbo.Nodes.AgentID, dbo.Nodes.Role, dbo.Nodes.CertificatePath, dbo.Nodes.CertificateThumbprint, dbo.Servers.Server_Id, dbo.Servers.Status, 
                         dbo.Servers.HardwarePlatform
FROM            dbo.Nodes INNER JOIN
                         dbo.Servers ON dbo.Nodes.Server_Id = dbo.Servers.Server_Id

GO

"@

# There is an error generated in this command, but you can safely ignore it.
Invoke-Sqlcmd -ServerInstance "(localdb)\$DBInstance" -Query $DBScript -ErrorAction SilentlyContinue


# Create dummy node data for the first 10 servers
$Servers = Invoke-Sqlcmd -ServerInstance "(localdb)\$DBInstance" -Query "SELECT TOP (10) * FROM dscdatabase.dbo.Servers ORDER BY Server_Id"
ForEach ($Server in $Servers) {
    $INSERT = "
        INSERT INTO dscdatabase.dbo.Nodes (Server_Id, HostName, Environment, Role)
        VALUES
           ($($Server.Server_Id), 'WEB$($Server.Server_Id)', 'PROD', 'WEB01'),
           ($($Server.Server_Id), 'VM$($Server.Server_Id)1',  'QA', 'HOST1'),
           ($($Server.Server_Id), 'VM$($Server.Server_Id)2',  'DEV', 'HOST2')
        GO
    "
    Invoke-Sqlcmd -ServerInstance "(localdb)\$DBInstance" -Query $INSERT
}


# Open SQL Management Studio
# Connect to (localdb)\DBInstanceNameFromDBInstanceVariable





break

# Run this cleanup code if you want to reset the database environment

# Cleanup
$LocalInstances = sqllocaldb info | Where-Object {$_ -ne 'MSSQLLocalDB'}
ForEach ($LocalDB in $LocalInstances) {
    sqllocaldb stop $LocalDB -k
    sqllocaldb delete $LocalDB
}
Get-ChildItem C:\DSCDB -Directory | Where-Object {$_.Name -in $LocalInstances} | Remove-Item -Force -Recurse -Confirm:$false

