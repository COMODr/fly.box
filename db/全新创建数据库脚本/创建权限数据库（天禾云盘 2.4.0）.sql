
/****** Object:  StoredProcedure [dbo].[fBox_KillLock]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		友百利
-- Create date: 2014-10-11
-- Description:	
-- =============================================
CREATE PROCEDURE [dbo].[fBox_KillLock]
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @spid int;
	DECLARE @sql varchar(100);
	DECLARE @dbid int;
	DECLARE @oldSpid int;

	Select @dbid=dbid From master..sysProcesses Where Spid = @@spid
	--select @dbid

	SET @spid=0;
	WHILE 1=1 BEGIN
		SET @oldSpid = @spid;
		SELECT TOP 1 @spid = spid FROM master..sysprocesses 
			WHERE dbid=@dbid AND blocked>0  AND spid>@spid AND (cpu>1000 OR  login_time<dateadd(s,-20, getdate()) );
		IF(@spid=@oldSpid)
			break

		IF(@spid =0 OR @spid IS NULL) BEGIN
			BREAK
		END ELSE BEGIN
			SET @sql='KILL '+CAST(@spid AS VARCHAR) ;
			print @sql;
			EXEC(@sql)
		END	
	END
END



GO
/****** Object:  StoredProcedure [dbo].[fBox_SetDepartmentAclBatch]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







-- =============================================
-- Author:		www.flyui.net
-- Create date: 2014-11-4 
-- Description:	保存用户权限
-- =============================================
Create PROCEDURE [dbo].[fBox_SetDepartmentAclBatch]
	@orgId varchar(36),
	@departmentIds varchar(8000),
	@spaceFileId varchar(36),
	@value int
AS
BEGIN
		DELETE fBox_SpaceFileDepartmentAuth 
			WHERE SpaceFileId=@spaceFileId 
			AND (
					(@departmentIds='*' AND DepartmentID IN(SELECT Id FROM fly_Department WHERE OrgId=@orgId))
					OR (@departmentIds<>'*' AND @departmentIds LIKE ('%'+DepartmentID+'%'))
				);
		
		INSERT fBox_SpaceFileDepartmentAuth 
			SELECT @spaceFileId as SpaceFileId,Id as DepartmentId ,@value as ACL FROM fly_Department
			WHERE(
					(@departmentIds='*' AND OrgId=@orgId)
					OR (@departmentIds<>'*' AND @departmentIds LIKE ('%'+Id+'%'))
				);
END





GO
/****** Object:  StoredProcedure [dbo].[fBox_SetRoleAclBatch]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





-- =============================================
-- Author:		www.flyui.net
-- Create date: 2014-11-3 
-- Description:	保存角色所有权限
-- =============================================
CREATE PROCEDURE [dbo].[fBox_SetRoleAclBatch]
	@orgId varchar(36),
	@roleIds varchar(8000),
	@spaceFileId varchar(36),
	@value int
AS
BEGIN
		DELETE fBox_SpaceFileRoleAuth 
			WHERE SpaceFileId=@spaceFileId 
			AND (
					(@roleIds='*' AND RoleID IN(SELECT Id FROM fly_Role WHERE IsPublic=1 OR OrgId=@orgId))
					OR (@roleIds<>'*' AND @roleIds LIKE ('%'+RoleID+'%'))
				);
		
		INSERT fBox_SpaceFileRoleAuth 
			SELECT @spaceFileId as SpaceFileId,Id as RoleId ,@value as ACL FROM fly_Role
			WHERE(
					(@roleIds='*' AND (IsPublic=1 OR OrgId=@orgId))
					OR (@roleIds<>'*' AND @roleIds LIKE ('%'+Id+'%'))
				);

	/*
		UPDATE fBox_SpaceFileRoleAuth 
			SET ACL=CASE @value 
						WHEN 0 THEN ACL | @acl 
						WHEN 1 THEN ACL ^ @acl
					END
		WHERE SpaceFileId=@spaceFileId 
		AND (
				(@roleIds='*' AND RoleID IN(SELECT Id FROM fly_Role WHERE IsPublic=1 OR OrgId=@orgId))
				OR (@roleIds<>'*' AND @roleIds LIKE ('%'+RoleID+'%'))
			);

	*/
END



GO
/****** Object:  StoredProcedure [dbo].[fBox_SetUserAclBatch]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






-- =============================================
-- Author:		www.flyui.net
-- Create date: 2014-11-4 
-- Description:	保存用户权限
-- =============================================
Create PROCEDURE [dbo].[fBox_SetUserAclBatch]
	@orgId varchar(36),
	@userIds varchar(8000),
	@spaceFileId varchar(36),
	@value int
AS
BEGIN
		DELETE fBox_SpaceFileUserAuth 
			WHERE SpaceFileId=@spaceFileId 
			AND (
					(@userIds='*' AND UserID IN(SELECT Id FROM fly_User WHERE OrgId=@orgId))
					OR (@userIds<>'*' AND @userIds LIKE ('%'+UserID+'%'))
				);
		
		INSERT fBox_SpaceFileUserAuth 
			SELECT @spaceFileId as SpaceFileId,Id as UserId ,@value as ACL FROM fly_User
			WHERE(
					(@userIds='*' AND OrgId=@orgId)
					OR (@userIds<>'*' AND @userIds LIKE ('%'+Id+'%'))
				);
END




GO
/****** Object:  StoredProcedure [dbo].[fBox_UpdateSpaceFileVersion]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		友百利
-- Create date: 2014-6-23 
-- Description:	更新版本号
-- =============================================
CREATE PROCEDURE [dbo].[fBox_UpdateSpaceFileVersion]
(
	@spaceFileId VARCHAR(36),
	@version DATETIME,
	@includeParents BIT
)

AS
BEGIN
	IF(@includeParents=0)
		UPDATE fBox_SpaceFile SET Version=@version WHERE Id=@spaceFileId;
	ELSE
		UPDATE fBox_SpaceFile SET Version=@version 
			WHERE Id IN(SELECT Id FROM dbo.fBox_GetFileParents(@spaceFileId,1));	
END




GO
/****** Object:  UserDefinedFunction [dbo].[fBox_BuildFileFullPath]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Kuiyou
-- Create date: 2016-5-20 11:00
-- Description:	计算文件的完整路径（包含根目录）
-- =============================================
CREATE FUNCTION [dbo].[fBox_BuildFileFullPath]
(
	@spaceFileId VARCHAR(36)
)
RETURNS varchar(900)
AS
BEGIN
	DECLARE @path varchar(900);
	SET @path='';	
	SELECT @path=@path+'/'+Id FROM dbo.fBox_GetFileParents(@spaceFileId,1) ORDER BY Level
	--select @path
	RETURN @path
END






GO
/****** Object:  UserDefinedFunction [dbo].[fBox_CheckDepartmentFolder]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Kuiyou
-- Create date: 2014-5-25 
-- Description:	验证部门专属目录权限
-- 返回值 ：
--	1、是本部门专属目录
--	2、是其他部门专属目录
--	4、不是部门专属目录
-- =============================================
CREATE FUNCTION [dbo].[fBox_CheckDepartmentFolder]
(
	@departmentId VARCHAR(36),
	@spaceFileId VARCHAR(36),
	@userId VARCHAR(36)
)
RETURNS int
AS
BEGIN
	DECLARE @departFolderId VARCHAR(36);

	SELECT @departFolderId=DepartmentId FROM [dbo].[fBox_GetFileParents](@spaceFileId,0) AS p
	JOIN fBox_DepartmentFolder as df ON df.FolderId=p.Id

	--不是部门专属目录
	IF(@departFolderId IS NULL)
		RETURN 1;
		--不是本部门专属目录
	ELSE IF @departFolderId<>@departmentId
		RETURN 2;
		--是本部门专属目录且自己是部门主管
	ELSE IF @userId IS NOT NULL AND EXISTS(SELECT * FROM fly_Department WHERE Id=@departmentId AND ManagerUserId=@userId) 
		RETURN 8
		--是本部门专属目录
	RETURN 4;
END




GO
/****** Object:  UserDefinedFunction [dbo].[fBox_CheckFolderCanUploadSize]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		有百利
-- Create date: 2014-10-10 
-- Description:	验证目录是否能上传指定大小的文件（含上级目录的验证）
-- 返回值 ：
--	空、可上传
--	不能上传，返回不能上传的原因
-- =============================================
CREATE FUNCTION [dbo].[fBox_CheckFolderCanUploadSize]
(
	@spaceFileId VARCHAR(36),
	@fileSize bigint
)
RETURNS VARCHAR(200)
AS
BEGIN
	DECLARE @departFolderId VARCHAR(36);
	DECLARE @folderName VARCHAR(500);

	SELECT TOP 1 @folderName='空间不足，文件夹“'+ Name+'”最大允许'+dbo.fBox_SizeFormat(sf.MaxSize)+'，还可上传'+dbo.fBox_SizeFormat(sf.MaxSize-sf.Size)  FROM [dbo].[fBox_GetFileParents](@spaceFileId,0) AS p
	JOIN fBox_SpaceFile sf ON sf.Id=p.Id 
	WHERE sf.MaxSize IS NOT NULL AND (sf.Size+@fileSize>sf.MaxSize)
	RETURN @folderName;	
END



GO
/****** Object:  UserDefinedFunction [dbo].[fBox_CheckSpaceFileUserACL]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:		友百利
-- Create date: 2014-6-24 
-- Description:	检测用户文件权限
-- 返回值 ：是否有权限
-- =============================================
CREATE FUNCTION [dbo].[fBox_CheckSpaceFileUserACL]
(
	@spaceFileId VARCHAR(36),
	@userId	VARCHAR(36),
	@checkAcl INT
)
RETURNS BIT
AS
BEGIN
/*
declare @spaceFileId VARCHAR(36)
declare 	@userId	VARCHAR(36)
set @spaceFileId='d0416eb3-3205-4d00-a343-be7a4009ad01'
set @userId='2000000001'
select dbo.[fBox_CheckSpaceFileUserACL]('d0bb57d1-0fc8-4e6b-b3aa-1a1453291cc9','2000000001',2)
*/
	--如果是自己企业空间的文件，只要是管理员就有权限
	IF( EXISTS(SELECT * FROM dbo.fBox_OrgSpace os 
		WHERE os.OrgId=(SELECT OrgId FROM dbo.fBox_User u WHERE u.Id=@userId )
			AND os.SpaceId=(SELECT SpaceId FROM dbo.fBox_SpaceFile sf WHERE sf.Id=@spaceFileId))
			AND EXISTS(SELECT * FROM fBox_User u WHERE u.Id=@userId AND u.IsDiskManager=1)
			)
		RETURN 1;
	
	DECLARE @acl INT 
	
	--如果是自己的文件，有所有权限
	IF(EXISTS(SELECT 1 FROM fBox_SpaceFile WHERE Id=@spaceFileId AND UserId=@userId))
		RETURN 1
	
	SELECT TOP 1 @acl=ACL 
	FROM fBox_SpaceFileUserAuth a 
		JOIN fBox_GetFileParents(@spaceFileId,1) pf
		ON a.SpaceFileId=pf.Id
		WHERE a.UserId=@userId 
	
	--SELECT @acl
	--如果设置了用户权限，则不用检测部门和用户组权限	
	IF(@acl IS NOT NULL) BEGIN
		RETURN dbo.[fBox_CompareACLVal](@acl,@checkAcl)
	END
	
	SET @acl=null;

	--如果设置了部门权限，且禁止，则不用继续检测
	SELECT TOP 1 @acl=ACL FROM fBox_SpaceFileDepartmentAuth a 
		JOIN fBox_GetFileParents(@spaceFileId,1) pf
		ON a.SpaceFileId=pf.Id
		WHERE a.DepartmentId=(SELECT DepartmentId FROM dbo.fly_User u WHERE u.Id=@userId)

	IF (@acl IS NOT NULL AND dbo.[fBox_CompareACLVal](@acl,@checkAcl)=0) BEGIN
		RETURN 0;
	END


	--如果有其中一个角色有权限，则有权限
	IF(EXISTS(
		SELECT TOP 1 ACL FROM (
			SELECT ACL=(
					CASE WHEN ACL IS NULL THEN 
						CASE WHEN (SELECT TOP 1 IsManager FROM fly_Role WHERE Id=ra.RoleId)=1 
							THEN dbo.fBox_FileFullACL()
						ELSE 
							dbo.fBox_FileBaseACL() 
						END
					ELSE ACL END)
				FROM(
					SELECT 
					RoleId,
					ACL=(SELECT TOP 1 ACL FROM fBox_SpaceFileRoleAuth a 
						JOIN fBox_GetFileParents(@spaceFileId,1) pf
						ON a.SpaceFileId=pf.Id
						WHERE a.RoleId=ur.RoleId)
					FROM fly_UserRole ur WHERE UserId=@userId
				) ra
		)ra2
		WHERE dbo.[fBox_CompareACLVal](ACL,@checkAcl)=1
	))
		RETURN 1
	ELSE
		RETURN 0



	RETURN 0
END



GO
/****** Object:  UserDefinedFunction [dbo].[fBox_CompareACLVal]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		友百利
-- Create date: 2015-4-21 
-- Description:	对比权限
-- =============================================
CREATE FUNCTION [dbo].[fBox_CompareACLVal]
(
	@all INT,
	@val int
)
RETURNS BIT
AS
BEGIN
	IF(@val=-34) BEGIN	--Open Or Download
		IF (@all & 2)=2 OR (@all & 32)=32
			RETURN 1
		ELSE
			RETURN 0
	END

	IF (@all & @val)=@val
		RETURN 1
	RETURN 0
END







GO
/****** Object:  UserDefinedFunction [dbo].[fBox_FileBaseACL]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		友百利
-- Create date: 2014-6-24 
-- Description:	文件基本权限（属性）
-- =============================================
CREATE FUNCTION [dbo].[fBox_FileBaseACL]
()
RETURNS INT
AS
BEGIN
	--对应SpaceFileServiceBase.BaseOrgSpaceFileACL
	--(FileACL.Comment | FileACL.Download | FileACL.Score)
	RETURN 354;
END




GO
/****** Object:  UserDefinedFunction [dbo].[fBox_FileFullACL]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		友百利
-- Create date: 2014-6-24 
-- Description:	文件所有权限（属性）
-- =============================================
CREATE FUNCTION [dbo].[fBox_FileFullACL]
()
RETURNS INT
AS
BEGIN
	--对应SpaceFileServiceBase.FullOrgSpaceFileACL属性
	--(FileACL.Manage | FileACL.Comment | FileACL.Download | FileACL.CreateDir | FileACL.Score | FileACL.Upload)
	RETURN 375;
END




GO
/****** Object:  UserDefinedFunction [dbo].[fBox_GetSpaceFileUserACL]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






-- =============================================
-- Author:		友百利
-- Create date: 2014-6-24 
-- Description:	获取用户文件权限
-- 返回值 ：用户权限
--	没有:表示没有设置用户权限，是继承部门、用户组权限
--  :后面|表示通过自己设置，否则表示通过上级设置
-- =============================================
CREATE FUNCTION [dbo].[fBox_GetSpaceFileUserACL]
(
	@spaceFileId VARCHAR(36),
	@userId	VARCHAR(36)
)
RETURNS VARCHAR(30)
AS
BEGIN
/*
declare @spaceFileId VARCHAR(36)
declare 	@userId	VARCHAR(36)
set @spaceFileId='d0416eb3-3205-4d00-a343-be7a4009ad01'
set @userId='2000000001'
--select dbo.[fBox_GetSpaceFileUserACL]('d0416eb3-3205-4d00-a343-be7a4009ad01','2000000001')
*/

	DECLARE @acl INT 
	DECLARE @aclStr VARCHAR(30) 
	DECLARE @fullACL INT
	DECLARE @baseACL INT
	

	SELECT TOP 1 @aclStr=
		CAST(ACL AS VARCHAR)+':'+
		(CASE WHEN a.SpaceFileId=@spaceFileId 
			THEN '|'
			ELSE (SELECT Name FROM fBox_SpaceFile sf WHERE sf.Id=a.SpaceFileId) END)
	FROM fBox_SpaceFileUserAuth a 
		JOIN fBox_GetFileParents(@spaceFileId,1) pf
		ON a.SpaceFileId=pf.Id
		WHERE a.UserId=@userId

	--SELECT @acl
	--如果设置了用户权限，则不用检测部门和用户组权限
	IF(@aclStr IS NOT NULL)
		RETURN @aclStr

	SET @fullACL=dbo.fBox_FileFullACL()
	SET @baseACL=dbo.fBox_FileBaseACL()

	SELECT TOP 1 @acl=ACL FROM fBox_SpaceFileDepartmentAuth a 
		JOIN fBox_GetFileParents(@spaceFileId,1) pf
		ON a.SpaceFileId=pf.Id
		WHERE a.DepartmentId=(SELECT DepartmentId FROM dbo.fly_User u WHERE u.Id=@userId)

	--如果没有设置部门权限，则默认部门有所有权限
	IF(@acl IS NULL)
		SET @acl=@fullACL

	--SELECT @acl
	DECLARE @acls TABLE(ACL INT);
	
	INSERT INTO @acls
	SELECT ACL=(
			CASE WHEN ACL IS NULL THEN 
				CASE WHEN (SELECT TOP 1 IsManager FROM fly_Role WHERE Id=ra.RoleId)=1 
					THEN @fullACL 
				ELSE @baseACL END
			ELSE ACL END)-- INTO #acls  
		FROM(
			SELECT 
			--Name=(SELECT Name FROM fly_Role WHERE Id=ur.RoleId),
			ur.RoleId,
			ACL=(SELECT TOP 1 ACL FROM fBox_SpaceFileRoleAuth a 
				JOIN fBox_GetFileParents(@spaceFileId,1) pf
				ON a.SpaceFileId=pf.Id
				WHERE a.RoleId=ur.RoleId)
			FROM fly_UserRole ur WHERE UserId=@userId
		) ra

	--SELECT * FROM #acls
	--重新计算@acl
	--计算规则，部门权限必须有，用户组权限中任意一个有
	SELECT @acl=SUM(ACL) 
		FROM fBox_SpaceFileAuths auths
		WHERE (@acl & ACL)=ACL AND EXISTS(SELECT 1 FROM @acls a WHERE (a.ACL & auths.ACL)=auths.ACL)

	--SELECT @acl

	RETURN @acl;
END









GO
/****** Object:  UserDefinedFunction [dbo].[fBox_IsChildren]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[fBox_IsChildren]
(
	@parentId VARCHAR(36),
	@childId VARCHAR(36)
)
RETURNS bit
AS
BEGIN
	IF(EXISTS(SELECT * FROM dbo.fBox_GetFileChildren(@parentId) WHERE [LEVEL]<>0 AND Id=@childId))
		return 1;
	return 0;
END






GO
/****** Object:  UserDefinedFunction [dbo].[fBox_SizeFormat]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		有百利
-- Create date: 2014-10-10 
-- Description:	格式化大小
-- =============================================
CREATE FUNCTION [dbo].[fBox_SizeFormat]
(
	@size bigint
)
RETURNS VARCHAR(20)
AS
BEGIN
	DECLARE @v VARCHAR(50);

    if (@size >= 1073741824)
        SET @v = CAST( CAST(@size / 1073741824.0 AS NUMERIC(10,1)) AS VARCHAR(10)) + 'G';
    else if (@size >= 1048576)
        SET @v =CAST( CAST(@size / 1048576.0 AS NUMERIC(10,1)) AS VARCHAR(10)) + 'M';
    else
        SET @v =CAST( CAST(@size / 1024.0 AS NUMERIC(10,1)) AS VARCHAR(10)) + 'K';

    SET @v =REPLACE(@v,'.0', '');

    if (@v = '0K' AND @size > 0)
        return '0.1K';
    return @v;
END



GO
/****** Object:  Table [dbo].[fBox_Comment]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_Comment](
	[Id] [varchar](36) NOT NULL,
	[FollowId] [varchar](60) NULL,
	[InfoType] [varchar](50) NOT NULL,
	[InfoId] [varchar](60) NOT NULL,
	[UserId] [varchar](36) NOT NULL,
	[Time] [datetime] NOT NULL,
	[Content] [nvarchar](500) NOT NULL,
	[State] [int] NOT NULL,
	[IP] [varchar](30) NOT NULL,
 CONSTRAINT [PK_fBox_Comment] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_Compression]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_Compression](
	[Id] [varchar](36) NOT NULL,
	[CreateUserId] [varchar](36) NOT NULL,
	[CreateTime] [datetime] NOT NULL,
	[EndTime] [datetime] NULL,
	[ItemCount] [int] NOT NULL,
	[LastVersion] [datetime] NOT NULL,
	[PackageName] [varchar](200) NOT NULL,
	[Size] [bigint] NOT NULL,
	[Path] [varchar](500) NOT NULL,
	[LastDownTime] [datetime] NULL,
	[CompProgress] [int] NOT NULL,
	[Msg] [varchar](500) NULL,
 CONSTRAINT [PK_fBox_Compression] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_CompressionItems]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_CompressionItems](
	[CompId] [varchar](36) NOT NULL,
	[SpaceFileId] [varchar](36) NOT NULL,
	[Version] [datetime] NOT NULL,
 CONSTRAINT [PK_fBox_CompressionItems] PRIMARY KEY CLUSTERED 
(
	[CompId] ASC,
	[SpaceFileId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_DepartmentFolder]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_DepartmentFolder](
	[DepartmentId] [varchar](36) NOT NULL,
	[FolderId] [varchar](36) NOT NULL,
	[MaxSize] [bigint] NOT NULL,
 CONSTRAINT [PK_fBox_DepartmentFolder] PRIMARY KEY CLUSTERED 
(
	[DepartmentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_DepartmentSpace]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_DepartmentSpace](
	[DepartmentId] [varchar](36) NOT NULL,
	[SpaceId] [varchar](36) NOT NULL,
 CONSTRAINT [PK_fBox_DepartmentSpace] PRIMARY KEY CLUSTERED 
(
	[DepartmentId] ASC,
	[SpaceId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_File]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_File](
	[Id] [varchar](36) NOT NULL,
	[UserId] [varchar](36) NOT NULL,
	[StoreId] [varchar](36) NOT NULL,
	[MD5] [varchar](50) NULL,
	[CheckSum] [varchar](100) NULL,
	[Size] [bigint] NOT NULL,
	[UploadSize] [bigint] NOT NULL,
	[Path] [varchar](500) NOT NULL,
	[ExtensionValue] [int] NOT NULL,
	[PCode] [varchar](50) NULL,
 CONSTRAINT [PK_fBox_File] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_FileReceive]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_FileReceive](
	[Id] [varchar](36) NOT NULL,
	[SendId] [varchar](36) NOT NULL,
	[UserId] [varchar](36) NOT NULL,
	[Time] [datetime] NOT NULL,
	[Cmd] [int] NOT NULL,
 CONSTRAINT [PK_fBox_FileReceive] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_FileSend]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_FileSend](
	[Id] [varchar](36) NOT NULL,
	[UserId] [varchar](36) NOT NULL,
	[FileId] [varchar](36) NOT NULL,
	[TargetType] [int] NOT NULL,
	[Target] [varchar](36) NOT NULL,
	[Time] [datetime] NOT NULL,
 CONSTRAINT [PK_fBox_FileSend] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_OrgSpace]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_OrgSpace](
	[OrgId] [varchar](36) NOT NULL,
	[SpaceId] [varchar](36) NOT NULL,
 CONSTRAINT [PK_fBox_OrgSpace_1] PRIMARY KEY CLUSTERED 
(
	[OrgId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_OrgSpaceSize]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_OrgSpaceSize](
	[OrgId] [varchar](36) NOT NULL,
	[SpaceSize] [bigint] NOT NULL,
	[Used] [bigint] NOT NULL,
 CONSTRAINT [PK_fBox_OrgSpaceSize] PRIMARY KEY CLUSTERED 
(
	[OrgId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_p_iw_AccessSystem]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_p_iw_AccessSystem](
	[Id] [varchar](36) NOT NULL,
	[Url] [varchar](200) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[FullName] [nvarchar](50) NOT NULL,
	[OrgNO] [varchar](20) NOT NULL,
	[AccessByOneUser] [bit] NOT NULL,
	[CanAccessRoles] [varchar](1000) NOT NULL,
 CONSTRAINT [PK_fBox_p_iw_AccessSystem] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_p_iw_SystemClient]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_p_iw_SystemClient](
	[Id] [varchar](36) NOT NULL,
	[Url] [varchar](200) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[FullName] [nvarchar](50) NOT NULL,
	[OrgNO] [varchar](20) NOT NULL,
	[OrgId] [varchar](50) NOT NULL,
	[Key] [varchar](50) NOT NULL,
	[AccessByOneUser] [bit] NOT NULL,
	[CanAccessRoles] [varchar](1000) NOT NULL,
 CONSTRAINT [PK_fBox_p_iw_SystemClient] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_p_iw_SystemClientUser]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_p_iw_SystemClientUser](
	[Id] [varchar](36) NOT NULL,
	[ClientId] [varchar](36) NOT NULL,
	[UserId] [varchar](36) NOT NULL,
	[BindUserId] [varchar](36) NOT NULL,
 CONSTRAINT [PK_fBox_p_iw_SystemClientUser] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_RoleSpaceSize]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_RoleSpaceSize](
	[RoleId] [varchar](36) NOT NULL,
	[OrgId] [varchar](36) NOT NULL,
	[SpaceSize] [bigint] NOT NULL,
 CONSTRAINT [PK_fBox_RoleSpaceSize] PRIMARY KEY CLUSTERED 
(
	[RoleId] ASC,
	[OrgId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_Share]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_Share](
	[FetchCode] [varchar](36) NOT NULL,
	[ShareUserId] [varchar](36) NULL,
	[FetchPassword] [varchar](36) NULL,
	[UploadPassword] [varchar](36) NULL,
	[Time] [datetime] NOT NULL,
	[EndTime] [datetime] NULL,
	[Power] [int] NOT NULL,
	[IsPublic] [bit] NOT NULL,
	[Size] [bigint] NOT NULL,
	[Title] [nvarchar](255) NOT NULL,
	[Summary] [nvarchar](500) NULL,
	[Status] [int] NOT NULL,
	[ArticleId] [varchar](36) NULL,
 CONSTRAINT [PK_fBox_Share] PRIMARY KEY CLUSTERED 
(
	[FetchCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_ShareFile]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_ShareFile](
	[Id] [varchar](36) NOT NULL,
	[FetchCode] [varchar](36) NOT NULL,
	[SpaceFileId] [varchar](36) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_ShareTarget]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_ShareTarget](
	[Id] [varchar](36) NOT NULL,
	[Type] [varchar](20) NOT NULL,
	[ToId] [varchar](50) NOT NULL,
	[FetchCode] [varchar](36) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_Shortcuts]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_Shortcuts](
	[Id] [varchar](36) NOT NULL,
	[Location] [varchar](50) NOT NULL,
	[Owner] [varchar](100) NOT NULL,
	[InfoType] [varchar](50) NOT NULL,
	[InfoId] [varchar](60) NOT NULL,
	[Name] [varchar](500) NULL,
	[Remark] [varchar](50) NULL,
 CONSTRAINT [PK_fBox_Shortcuts] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_SMS]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_SMS](
	[Id] [varchar](36) NOT NULL,
	[UserId] [varchar](36) NOT NULL,
	[NumbersDesc] [varchar](100) NOT NULL,
	[ToNumbers] [varchar](max) NOT NULL,
	[Content] [varchar](1000) NOT NULL,
	[UseMsgCount] [int] NOT NULL,
	[ActualSpendMsgCount] [int] NULL,
	[Ip] [varchar](50) NOT NULL,
	[Referer] [varchar](300) NULL,
	[CreateTime] [datetime] NOT NULL,
	[SubmitTime] [datetime] NULL,
	[SendTime] [datetime] NULL,
	[Result] [varchar](100) NULL,
 CONSTRAINT [PK_fBox_SMS] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_Space]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_Space](
	[Id] [varchar](36) NOT NULL,
	[Size] [bigint] NOT NULL,
	[Used] [bigint] NOT NULL,
	[Initialized] [bit] NOT NULL,
 CONSTRAINT [PK_fBox_Space] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_SpaceFile]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_SpaceFile](
	[Id] [varchar](36) NOT NULL,
	[FileId] [varchar](36) NULL,
	[SpaceID] [varchar](36) NULL,
	[Name] [nvarchar](255) NOT NULL,
	[ParentId] [varchar](36) NULL,
	[Size] [bigint] NOT NULL,
	[Extension] [varchar](50) NULL,
	[UserId] [varchar](36) NOT NULL,
	[Remark] [nvarchar](500) NULL,
	[Time] [datetime] NOT NULL,
	[Star] [int] NOT NULL,
	[ShareCount] [int] NOT NULL,
	[Type] [int] NOT NULL,
	[State] [int] NOT NULL,
	[ACL] [int] NULL,
	[ArticleId] [varchar](36) NULL,
	[Version] [datetime] NOT NULL,
	[ContentVersion] [datetime] NOT NULL,
	[MaxSize] [bigint] NULL,
	[Path] [varchar](900) NOT NULL,
 CONSTRAINT [PK_fBox_SpaceFile] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_SpaceFileAuths]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_SpaceFileAuths](
	[ACL] [int] NOT NULL,
	[Title] [varchar](20) NOT NULL,
	[Name] [varchar](20) NOT NULL,
 CONSTRAINT [PK_fBox_SpaceFileAuths] PRIMARY KEY CLUSTERED 
(
	[ACL] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_SpaceFileDepartmentAuth]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_SpaceFileDepartmentAuth](
	[SpaceFileId] [varchar](36) NOT NULL,
	[DepartmentId] [varchar](36) NOT NULL,
	[ACL] [int] NOT NULL,
 CONSTRAINT [PK_fBox_SpaceFileDepartmentAuth] PRIMARY KEY CLUSTERED 
(
	[SpaceFileId] ASC,
	[DepartmentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_SpaceFileEx]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_SpaceFileEx](
	[SpaceFileId] [varchar](36) NOT NULL,
	[Type] [varchar](50) NOT NULL,
	[Value] [nvarchar](500) NULL,
 CONSTRAINT [PK_fBox_SpaceFileEx] PRIMARY KEY CLUSTERED 
(
	[SpaceFileId] ASC,
	[Type] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_SpaceFileRoleAuth]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_SpaceFileRoleAuth](
	[SpaceFileId] [varchar](36) NOT NULL,
	[RoleId] [varchar](36) NOT NULL,
	[ACL] [int] NOT NULL,
 CONSTRAINT [PK_fBox_SpaceFileRoleAuth] PRIMARY KEY CLUSTERED 
(
	[SpaceFileId] ASC,
	[RoleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_SpaceFileUserAuth]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_SpaceFileUserAuth](
	[SpaceFileId] [varchar](36) NOT NULL,
	[UserId] [varchar](36) NOT NULL,
	[ACL] [int] NOT NULL,
 CONSTRAINT [PK_fBox_SpaceFileUserAuth] PRIMARY KEY CLUSTERED 
(
	[SpaceFileId] ASC,
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_Store]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_Store](
	[Id] [varchar](36) NOT NULL,
	[Path] [varchar](500) NOT NULL,
	[Size] [bigint] NOT NULL,
	[Used] [bigint] NOT NULL,
	[IsDisabled] [bit] NOT NULL,
 CONSTRAINT [PK_fBox_Store] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_SuperEx]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_SuperEx](
	[Id] [varchar](36) NOT NULL,
	[UserId] [varchar](36) NOT NULL,
	[Order] [float] NOT NULL,
	[Enable] [bit] NOT NULL,
	[Time] [datetime] NOT NULL,
	[Remark] [varchar](200) NOT NULL,
	[Script] [varchar](4000) NOT NULL,
 CONSTRAINT [PK_fBox_SuperEx] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_Tag]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_Tag](
	[SpaceId] [varchar](36) NOT NULL,
	[TagName] [nvarchar](50) NOT NULL,
	[TypeName] [nvarchar](50) NOT NULL,
	[FileCount] [int] NOT NULL,
 CONSTRAINT [PK_fBox_Tag] PRIMARY KEY CLUSTERED 
(
	[SpaceId] ASC,
	[TagName] ASC,
	[TypeName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_TagGroup]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[fBox_TagGroup](
	[GroupName] [nvarchar](50) NOT NULL,
	[Tag] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_fBox_TagGroup] PRIMARY KEY CLUSTERED 
(
	[GroupName] ASC,
	[Tag] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[fBox_UnCompression]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_UnCompression](
	[FileId] [varchar](36) NOT NULL,
	[UnCompressionUserId] [varchar](36) NOT NULL,
	[ToPath] [varchar](500) NOT NULL,
	[UnCompressionTime] [datetime] NOT NULL,
	[LastReadTime] [datetime] NOT NULL,
	[CompressionSize] [bigint] NOT NULL,
	[UnCompressionSize] [bigint] NOT NULL,
	[Password] [varchar](64) NOT NULL,
	[UnCompressionProgress] [int] NOT NULL,
	[Msg] [varchar](500) NULL,
 CONSTRAINT [PK_fBox_UnCompression] PRIMARY KEY CLUSTERED 
(
	[FileId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_UserSpace]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_UserSpace](
	[UserId] [varchar](36) NOT NULL,
	[SpaceId] [varchar](36) NOT NULL,
 CONSTRAINT [PK_fBox_UserSpace_1] PRIMARY KEY CLUSTERED 
(
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_Work]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_Work](
	[Id] [varchar](36) NOT NULL,
	[FlowNO] [varchar](30) NOT NULL,
	[Title] [nvarchar](255) NOT NULL,
	[CreateTime] [datetime] NOT NULL,
	[ProposalCompleteTime] [datetime] NULL,
	[CreatorId] [varchar](36) NOT NULL,
	[Content] [varchar](max) NOT NULL,
	[Type] [varchar](36) NULL,
	[FollowId] [varchar](60) NULL,
	[Url] [varchar](300) NULL,
	[State] [int] NOT NULL,
 CONSTRAINT [PK_fBox_Work] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_WorkAttachment]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_WorkAttachment](
	[Id] [varchar](36) NOT NULL,
	[WorkId] [varchar](36) NOT NULL,
	[FileId] [varchar](36) NOT NULL,
	[Name] [nvarchar](255) NOT NULL,
 CONSTRAINT [PK_fBox_WorkAttachment] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fBox_WorkTarget]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fBox_WorkTarget](
	[Id] [varchar](36) NOT NULL,
	[WorkId] [varchar](36) NULL,
	[UserId] [varchar](36) NOT NULL,
	[AssignTime] [datetime] NOT NULL,
	[ReceiveTime] [datetime] NULL,
	[CompleteTime] [datetime] NULL,
	[LastUpdateTime] [datetime] NOT NULL,
	[TargetViewTime] [datetime] NULL,
	[CreatorViewTime] [datetime] NOT NULL,
	[State] [int] NOT NULL,
 CONSTRAINT [PK_fBox_WorkTarget] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fEdu_Class]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fEdu_Class](
	[Id] [varchar](36) NOT NULL,
	[GradeId] [varchar](36) NOT NULL,
	[OrgId] [varchar](36) NOT NULL,
	[DepartmentId] [varchar](36) NULL,
	[ClassNO] [varchar](50) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[HeadTeacherId] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_fEdu_Class] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fEdu_ClassStudent]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fEdu_ClassStudent](
	[TermId] [varchar](36) NOT NULL,
	[ClassId] [varchar](36) NOT NULL,
	[StudentId] [varchar](36) NOT NULL,
	[NOInClass] [varchar](50) NOT NULL,
	[IgnoreResult] [bit] NOT NULL,
 CONSTRAINT [一个班级内学号不能重复] PRIMARY KEY CLUSTERED 
(
	[TermId] ASC,
	[ClassId] ASC,
	[NOInClass] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fEdu_Exam]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fEdu_Exam](
	[Id] [varchar](36) NOT NULL,
	[TermId] [varchar](36) NOT NULL,
	[OrgId] [varchar](36) NULL,
	[CreateUserId] [varchar](36) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[CreateTime] [datetime] NOT NULL,
	[Time] [datetime] NOT NULL,
 CONSTRAINT [PK_fEdu_Exam] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fEdu_ExamGrade]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fEdu_ExamGrade](
	[ExamId] [varchar](36) NOT NULL,
	[GradeId] [varchar](36) NOT NULL,
	[V] [varchar](50) NULL,
 CONSTRAINT [PK_fEdu_ExamGrade] PRIMARY KEY CLUSTERED 
(
	[ExamId] ASC,
	[GradeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fEdu_ExamSubject]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fEdu_ExamSubject](
	[ExamId] [varchar](36) NOT NULL,
	[SubjectId] [varchar](36) NOT NULL,
	[RateId] [varchar](36) NOT NULL,
 CONSTRAINT [PK_fEdu_ExamSubject] PRIMARY KEY CLUSTERED 
(
	[ExamId] ASC,
	[SubjectId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fEdu_Grade]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fEdu_Grade](
	[Id] [varchar](36) NOT NULL,
	[DepartmentId] [varchar](36) NULL,
	[Name] [nvarchar](50) NOT NULL,
	[Admin] [nvarchar](50) NULL,
	[Type] [nvarchar](20) NULL,
	[BeginDate] [datetime] NOT NULL,
	[IsFinish] [bit] NOT NULL,
 CONSTRAINT [PK_fEdu_Grade] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fEdu_GradeSubject]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fEdu_GradeSubject](
	[SubjectId] [varchar](36) NOT NULL,
	[GradeId] [varchar](36) NOT NULL,
	[V] [varchar](50) NULL,
 CONSTRAINT [PK_fEdu_GradeSubject] PRIMARY KEY CLUSTERED 
(
	[SubjectId] ASC,
	[GradeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fEdu_Parents]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fEdu_Parents](
	[Id] [varchar](36) NOT NULL,
	[OrgId] [varchar](36) NOT NULL,
	[UserId] [varchar](36) NULL,
	[Name] [nvarchar](50) NOT NULL,
	[Sex] [nvarchar](4) NOT NULL,
	[Phone] [varchar](30) NULL,
	[Phone2] [varchar](30) NULL,
 CONSTRAINT [PK_fEdu_Parents] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fEdu_Results]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fEdu_Results](
	[ExamId] [varchar](36) NOT NULL,
	[SubjectId] [varchar](36) NOT NULL,
	[StudentId] [varchar](36) NOT NULL,
	[Score] [float] NOT NULL,
	[EntryTime] [datetime] NOT NULL,
	[EntryUserId] [varchar](36) NOT NULL,
 CONSTRAINT [PK_fEdu_Results] PRIMARY KEY CLUSTERED 
(
	[ExamId] ASC,
	[SubjectId] ASC,
	[StudentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fEdu_StatisticTemp]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fEdu_StatisticTemp](
	[Id] [varchar](36) NOT NULL,
	[RateId] [varchar](36) NOT NULL,
	[Type] [varchar](50) NOT NULL,
	[Template] [varchar](max) NOT NULL,
 CONSTRAINT [PK_fEdu_StatisticTemp] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fEdu_Student]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fEdu_Student](
	[Id] [varchar](36) NOT NULL,
	[OrgId] [varchar](36) NOT NULL,
	[UserId] [varchar](36) NULL,
	[Name] [nvarchar](10) NOT NULL,
	[Sex] [varchar](10) NOT NULL,
	[Phone] [varchar](30) NULL,
	[Birthday] [datetime] NULL,
	[Hometown] [nvarchar](20) NULL,
	[Nation] [nvarchar](20) NULL,
	[IdCard] [varchar](30) NULL,
	[StateOfHealth] [nvarchar](20) NULL,
	[PoliticalAffiliation] [nvarchar](20) NULL,
	[AccountKind] [nvarchar](20) NULL,
	[BornArea] [varchar](20) NULL,
	[OwnerArea] [varchar](50) NULL,
	[StudyingWays] [nvarchar](10) NULL,
	[Address] [nvarchar](50) NULL,
	[MailingAddress] [nvarchar](50) NULL,
	[HomeAddress] [nvarchar](50) NULL,
	[IsOnlyChild] [nvarchar](4) NULL,
	[HasPreschool] [nvarchar](4) NULL,
	[IsLeftBehind] [nvarchar](20) NULL,
	[NeedSubsidize] [nvarchar](20) NULL,
	[WayToSchool] [nvarchar](20) NULL,
	[SchoolRoll] [varchar](30) NULL,
	[IsMigrantWorkers] [nvarchar](4) NULL,
	[EntryTime] [datetime] NOT NULL,
 CONSTRAINT [PK_fEdu_Student] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fEdu_StudentParents]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fEdu_StudentParents](
	[StudentId] [varchar](36) NOT NULL,
	[ParentsId] [varchar](36) NOT NULL,
	[Title] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_fEdu_StudentParents] PRIMARY KEY CLUSTERED 
(
	[StudentId] ASC,
	[ParentsId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fEdu_Subject]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fEdu_Subject](
	[Id] [varchar](36) NOT NULL,
	[Name] [nvarchar](20) NOT NULL,
	[DefaultTotalScore] [int] NOT NULL,
	[DefaultPassScore] [int] NOT NULL,
	[DefaultJoin] [bit] NOT NULL,
 CONSTRAINT [PK_fEdu_Subject] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fEdu_SubjectRate]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fEdu_SubjectRate](
	[Id] [varchar](36) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[Total] [int] NOT NULL,
	[Pass] [int] NOT NULL,
 CONSTRAINT [PK_fEdu_SubjectRate] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fEdu_SubjectRateItem]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fEdu_SubjectRateItem](
	[Id] [varchar](36) NOT NULL,
	[RateId] [varchar](36) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[StartScore] [int] NULL,
	[EndScore] [int] NULL,
	[Expression] [varchar](500) NULL,
	[Flag] [varchar](50) NULL,
	[Sort] [int] NOT NULL,
 CONSTRAINT [PK_fEdu_SubjectRateItem] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fEdu_SubjectTeach]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fEdu_SubjectTeach](
	[TermId] [varchar](36) NOT NULL,
	[ClassId] [varchar](36) NOT NULL,
	[SubjectId] [varchar](36) NOT NULL,
	[TeacherId] [varchar](36) NOT NULL,
 CONSTRAINT [PK_fEdu_SubjectTeach] PRIMARY KEY CLUSTERED 
(
	[TermId] ASC,
	[ClassId] ASC,
	[SubjectId] ASC,
	[TeacherId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fEdu_Teacher]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fEdu_Teacher](
	[Id] [varchar](36) NOT NULL,
	[UserId] [varchar](36) NOT NULL,
 CONSTRAINT [PK_fEdu_Teacher] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fEdu_Term]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fEdu_Term](
	[Id] [varchar](36) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[StartDate] [datetime] NOT NULL,
	[Inited] [bit] NOT NULL,
 CONSTRAINT [PK_fEdu_Term|重复添加] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fly_Config]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fly_Config](
	[For] [varchar](50) NOT NULL,
	[Type] [varchar](50) NOT NULL,
	[Name] [varchar](50) NOT NULL,
	[Value] [varchar](4000) NOT NULL,
 CONSTRAINT [PK_fly_Config] PRIMARY KEY CLUSTERED 
(
	[For] ASC,
	[Type] ASC,
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fly_Department]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fly_Department](
	[Id] [varchar](36) NOT NULL,
	[OrgId] [varchar](36) NOT NULL,
	[ParentId] [varchar](36) NULL,
	[Name] [nvarchar](50) NOT NULL,
	[Address] [nvarchar](200) NULL,
	[Phone] [varchar](50) NULL,
	[ContactPerson] [nvarchar](50) NULL,
	[ManagerUserId] [varchar](36) NULL,
	[Type] [varchar](20) NULL,
	[IsShow] [int] NOT NULL,
 CONSTRAINT [PK_fly_Department] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fly_Follows]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fly_Follows](
	[Id] [varchar](36) NOT NULL,
	[UserId] [varchar](36) NOT NULL,
	[InfoType] [varchar](50) NOT NULL,
	[InfoId] [varchar](60) NOT NULL,
	[Time] [datetime] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fly_Function]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fly_Function](
	[Id] [varchar](36) NOT NULL,
	[ModuleId] [varchar](36) NOT NULL,
	[Key] [varchar](50) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[Description] [nvarchar](200) NULL,
 CONSTRAINT [PK_fly_Function] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fly_im_Group]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fly_im_Group](
	[Id] [varchar](36) NOT NULL,
	[Name] [varchar](50) NOT NULL,
	[Desc] [varchar](200) NOT NULL,
	[CreateTime] [datetime] NOT NULL,
	[CreateUserId] [varchar](36) NOT NULL,
	[Status] [int] NOT NULL,
 CONSTRAINT [PK_fly_im_Group] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fly_im_GroupMember]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fly_im_GroupMember](
	[Id] [varchar](36) NOT NULL,
	[GroupId] [varchar](36) NOT NULL,
	[UserId] [varchar](36) NOT NULL,
	[JoinTime] [datetime] NOT NULL,
	[NickName] [varchar](50) NULL,
 CONSTRAINT [PK_fly_im_GroupMember] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fly_im_Message]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fly_im_Message](
	[Id] [varchar](36) NOT NULL,
	[SessionId] [varchar](36) NOT NULL,
	[SenderId] [varchar](50) NOT NULL,
	[Content] [nvarchar](500) NOT NULL,
	[Time] [datetime] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fly_im_Session]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fly_im_Session](
	[Id] [varchar](36) NOT NULL,
	[TargetType] [int] NOT NULL,
	[GroupId] [varchar](50) NULL,
	[Member1] [varchar](50) NULL,
	[Member2] [varchar](50) NULL,
	[StartTime] [datetime] NOT NULL,
	[CreateUserId] [varchar](50) NOT NULL,
	[LastMsgTime] [datetime] NOT NULL,
 CONSTRAINT [PK_fly_im_Session] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fly_im_UserInfos]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fly_im_UserInfos](
	[UserId] [varchar](50) NOT NULL,
	[OnlineState] [int] NOT NULL,
 CONSTRAINT [PK_fly_im_UserInfos] PRIMARY KEY CLUSTERED 
(
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fly_im_UserSessionInfo]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fly_im_UserSessionInfo](
	[UserId] [varchar](50) NOT NULL,
	[TargetId] [varchar](50) NOT NULL,
	[SessionId] [varchar](36) NOT NULL,
	[ReceiveMode] [int] NOT NULL,
	[LastReadTime] [datetime] NOT NULL,
	[LastNotifyTime] [datetime] NOT NULL,
 CONSTRAINT [PK_fly_im_MessageRead] PRIMARY KEY CLUSTERED 
(
	[UserId] ASC,
	[TargetId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fly_KeyValue]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fly_KeyValue](
	[Key] [varchar](100) NOT NULL,
	[Value] [varchar](max) NOT NULL,
	[Id] [bigint] IDENTITY(1,1) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fly_Log]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fly_Log](
	[Id] [varchar](36) NOT NULL,
	[UserId] [varchar](36) NULL,
	[InfoType] [varchar](50) NOT NULL,
	[InfoId] [varchar](60) NOT NULL,
	[Action] [varchar](30) NOT NULL,
	[Value] [nvarchar](200) NULL,
	[Time] [datetime] NOT NULL,
	[Referer] [nvarchar](500) NULL,
	[IP] [varchar](30) NULL,
	[Remark] [nvarchar](200) NULL,
	[NumValue] [float] NULL,
	[IsValid] [bit] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fly_MailLog]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fly_MailLog](
	[Id] [varchar](36) NOT NULL,
	[UserId] [varchar](36) NOT NULL,
	[Type] [varchar](50) NOT NULL,
	[Emails] [varchar](max) NOT NULL,
	[Subject] [nvarchar](200) NOT NULL,
	[Body] [varchar](max) NOT NULL,
	[Time] [datetime] NOT NULL,
 CONSTRAINT [PK_fly_MailLog] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fly_Message]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fly_Message](
	[Id] [varchar](36) NOT NULL,
	[Summary] [nvarchar](100) NULL,
	[Content] [varchar](max) NULL,
	[Time] [datetime] NOT NULL,
	[UserId] [varchar](36) NOT NULL,
	[Url] [varchar](300) NULL,
	[ToCount] [int] NOT NULL,
	[ReadedCount] [int] NOT NULL,
	[FollowId] [varchar](60) NULL,
 CONSTRAINT [PK_fly_Message] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fly_MessageTarget]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fly_MessageTarget](
	[Id] [varchar](36) NOT NULL,
	[UserId] [varchar](36) NOT NULL,
	[MsgId] [varchar](36) NOT NULL,
	[Readed] [int] NULL,
	[ReadTime] [datetime] NULL,
	[SendTime] [datetime] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fly_Module]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fly_Module](
	[Id] [varchar](36) NOT NULL,
	[PluginId] [varchar](36) NOT NULL,
	[Key] [varchar](50) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[ParentId] [varchar](36) NULL,
	[Type] [int] NOT NULL,
	[Url] [varchar](500) NULL,
 CONSTRAINT [PK_fly_Module] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fly_Org]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fly_Org](
	[Id] [varchar](36) NOT NULL,
	[ParentId] [varchar](36) NULL,
	[Name] [nvarchar](50) NOT NULL,
	[Address] [nvarchar](200) NULL,
	[Phone] [varchar](50) NULL,
	[ContactPerson] [nvarchar](50) NULL,
	[RegistTime] [datetime] NOT NULL,
	[Status] [int] NOT NULL,
 CONSTRAINT [PK_fly_Org] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fly_Plugin]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fly_Plugin](
	[Id] [varchar](36) NOT NULL,
	[Path] [varchar](300) NOT NULL,
	[Name] [nvarchar](200) NOT NULL,
	[Enable] [bit] NOT NULL,
	[Description] [varchar](4000) NOT NULL,
	[Author] [nvarchar](200) NOT NULL,
	[Site] [varchar](200) NOT NULL,
 CONSTRAINT [PK_fly_Plugin] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fly_Role]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fly_Role](
	[Id] [varchar](36) NOT NULL,
	[OrgId] [varchar](36) NULL,
	[Name] [nvarchar](50) NOT NULL,
	[IsManager] [bit] NOT NULL,
	[IsPublic] [bit] NOT NULL,
	[Type] [varchar](50) NOT NULL,
 CONSTRAINT [PK_fly_Role] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fly_RoleFunction]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fly_RoleFunction](
	[Id] [varchar](36) NOT NULL,
	[RoleId] [varchar](36) NOT NULL,
	[FunctionId] [varchar](36) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fly_RoleModule]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fly_RoleModule](
	[Id] [varchar](36) NOT NULL,
	[RoleId] [varchar](36) NOT NULL,
	[ModuleId] [varchar](36) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fly_RolePlugin]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fly_RolePlugin](
	[Id] [varchar](36) NOT NULL,
	[RoleId] [varchar](36) NOT NULL,
	[PluginId] [varchar](36) NOT NULL,
 CONSTRAINT [PK_fly_RolePlugin] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fly_User]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fly_User](
	[Id] [varchar](36) NOT NULL,
	[OrgId] [varchar](36) NOT NULL,
	[DepartmentId] [varchar](36) NOT NULL,
	[Email] [varchar](100) NULL,
	[LoginName] [varchar](100) NOT NULL,
	[NickName] [nvarchar](50) NOT NULL,
	[Sex] [nvarchar](4) NOT NULL,
	[Password] [varchar](128) NOT NULL,
	[MobilePhone] [varchar](20) NULL,
	[EmailVerified] [bit] NOT NULL,
	[RegisterTime] [datetime] NULL,
	[Status] [int] NOT NULL,
	[IsManager] [bit] NOT NULL,
	[Type] [varchar](20) NULL,
 CONSTRAINT [PK_fly_User] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[fly_UserRole]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[fly_UserRole](
	[Id] [varchar](36) NOT NULL,
	[UserId] [varchar](36) NOT NULL,
	[RoleId] [varchar](36) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[t_test]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[t_test](
	[id] [int] NULL,
	[pid] [int] NULL,
	[size] [int] NULL
) ON [PRIMARY]

GO
/****** Object:  UserDefinedFunction [dbo].[fly_im_GetUserFriendGroups]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:		Kuiyou
-- Create date: 2015-6-18
-- Description:	查询用户所有群
-- =============================================
CREATE FUNCTION [dbo].[fly_im_GetUserFriendGroups] 
(
	@userId varchar(50)
)
RETURNS TABLE 
AS
RETURN 
(
	  WITH temp(Id,ParentId,Level) AS(
			SELECT Id,ParentId,Level=0 FROM fly_Department WHERE id=(SELECT TOP 1 DepartmentId FROM fly_User WHERE Id= @userId)
			UNION ALL
			SELECT p.Id,p.ParentId ,Level=t.Level+1 FROM fly_Department p JOIN temp t ON p.Id=t.ParentId 
		)
		SELECT * FROM temp 
)



GO
/****** Object:  UserDefinedFunction [dbo].[fly_im_GetUserGroupIds]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





-- =============================================
-- Author:		Kuiyou
-- Create date: 2015-6-18
-- Description:	查询用户所有群Id
-- =============================================
CREATE FUNCTION [dbo].[fly_im_GetUserGroupIds] 
(
	@userId varchar(50)
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT Id From fly_im_GetUserFriendGroups(@userId)
	UNION 
	SELECT GroupId as Id From fly_im_GroupMember WHERE UserId=@userId
)






GO
/****** Object:  UserDefinedFunction [dbo].[fly_im_GetOnlineUserNoReadMsgs]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		FlyUI.NET
-- Create date: 2015-8-3
-- Description:	查询所有在线用户未接收消息
-- =============================================
CREATE FUNCTION [dbo].[fly_im_GetOnlineUserNoReadMsgs]
()
RETURNS TABLE 
AS
RETURN 
(
	SELECT m.* FROM fly_im_Message m
		LEFT JOIN fly_im_UserSessionInfo us 
		ON m.SessionId=us.SessionId
		WHERE 
			us.UserId IN(SELECT UserId FROM fly_im_UserInfos ui WHERE OnlineState=1)
			AND m.SessionId IN(
				SELECT Id FROM fly_im_Session s 
					WHERE (Member1=us.UserId OR Member2=us.UserId) OR s.GroupId IN(
						SELECT ID FROM dbo.fly_im_GetUserGroupIds(us.UserId)
					))
			AND (us.LastReadTime<m.Time OR us.LastReadTime IS NULL)
)



GO
/****** Object:  UserDefinedFunction [dbo].[fly_im_GetLeaveMsgs]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








-- =============================================
-- Author:		Kuiyou
-- Create date: 2015-6-19
-- Description:	查询用户所有留言
-- =============================================
CREATE FUNCTION [dbo].[fly_im_GetLeaveMsgs] 
(
	@userId varchar(50)
)
RETURNS TABLE 
AS
RETURN 
(
SELECT m.* FROM fly_im_Message m
	LEFT JOIN fly_im_UserSessionInfo us 
	ON us.UserId=@userId AND m.SessionId=us.SessionId

	WHERE m.SessionId IN(
		SELECT Id FROM fly_im_Session s 
			WHERE (Member1=@userId OR Member2=@userId) OR s.GroupId IN(
				SELECT ID FROM dbo.fly_im_GetUserGroupIds(@userId)
			))
		AND (us.LastReadTime<m.Time OR us.LastReadTime IS NULL)
)

--
--select * from dbo.[fly_im_GetLeaveMsgs]('2000000001')
--
--
--declare @userId varchar(36)
--set @userId='2000000001'
--SELECT * FROM fly_im_Message m
--
--	LEFT JOIN fly_im_MessageRead us 
--	ON us.UserId=@userId AND m.SessionId=us.SessionId
--
--	WHERE m.SessionId IN(
--		SELECT Id FROM fly_im_Session s 
--			WHERE (Member1=@userId OR Member2=@userId) OR s.GroupId IN(
--				SELECT ID FROM dbo.fly_im_GetUserGroups(@userId)
--			))
--		AND (us.LastReadTime<m.Time OR us.LastReadTime IS NULL)

			








GO
/****** Object:  UserDefinedFunction [dbo].[fly_im_GetLeaveCounts]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO










-- =============================================
-- Author:		Kuiyou
-- Create date: 2015-6-19
-- Description:	查询用户所有留言
-- =============================================
CREATE FUNCTION [dbo].[fly_im_GetLeaveCounts] 
(
	@userId varchar(50)
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT s.TargetType,
	   m.SessionId,
		(SELECT CASE 
				WHEN GroupId IS NOT NULL THEN GroupId 
				WHEN Member1 <> @userId THEN Member1 
				ELSE Member2 END
		FROM fly_im_Session session WHERE session.Id= m.SessionId ) AS Target,
		Count(1) AS Count
	FROM fly_im_Message m
	LEFT JOIN fly_im_Session s 
		ON m.SessionId=s.Id
	LEFT JOIN fly_im_UserSessionInfo us 
		ON us.UserId=@userId AND m.SessionId=us.SessionId

	WHERE m.SenderId<>@userId AND ((s.Member1=@userId OR s.Member2=@userId) OR s.GroupId IN(
					SELECT ID FROM dbo.fly_im_GetUserGroupIds(@userId)
				)
			)
		AND (us.LastReadTime<m.Time OR us.LastReadTime IS NULL)
	GROUP BY s.TargetType, m.SessionId 
)

--
--select * from [fly_im_GetLeaveCounts]('2000000001')
--
--
--declare @userId varchar(36)
--set @userId='2000000001'
--
--
--SELECT s.TargetType,
--	   m.SessionId,
--		(SELECT CASE 
--				WHEN GroupId IS NOT NULL THEN GroupId 
--				WHEN Member1 <> @userId THEN Member1 
--				ELSE Member2 END
--		FROM fly_im_Session session WHERE session.Id= m.SessionId ) AS Target,
--		Count(1) AS Count
--	FROM fly_im_Message m
--	LEFT JOIN fly_im_Session s 
--		ON m.SessionId=s.Id
--	LEFT JOIN fly_im_MessageRead mr 
--		ON mr.UserId=@userId AND m.SessionId=mr.SessionId
--
--	WHERE ((s.Member1=@userId OR s.Member2=@userId) OR s.GroupId IN(
--					SELECT ID FROM dbo.fly_im_GetUserGroups(@userId)
--				)
--			)
--		AND (mr.LastReadTime<m.Time OR mr.LastReadTime IS NULL)
--	GROUP BY s.TargetType, m.SessionId 
--
--			









GO
/****** Object:  UserDefinedFunction [dbo].[fly_im_GetRecentlySessions]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








-- =============================================
-- Author:		Kuiyou
-- Create date: 2015-6-25
-- Description:	查询最近会话
-- =============================================
CREATE FUNCTION [dbo].[fly_im_GetRecentlySessions] 
(
	@userId varchar(50)
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT * FROM (
		SELECT s.Id,
				(SELECT TOP 1 m.Time FROM fly_im_Message m where m.SessionId = s.Id ) AS [Time],
				s.TargetType,
				Target =CASE WHEN s.GroupId IS NOT NULL THEN s.GroupId WHEN s.Member1 <> @userId THEN s.Member1 ELSE s.Member2 END
				FROM fly_im_Session s
								where ((s.Member1 = @userId OR s.Member2 = @userId) 
										OR EXISTS(SELECT * FROM dbo.fly_im_GetUserGroupIds(@userId) ug WHERE ug.Id = s.GroupId))
		) session 
)

--
--select * from GetRecentlySessions('2000000001')
--
--


--declare @userId varchar(36)
--set @userId='2000000001'
--
--	SELECT * FROM (
--		SELECT s.Id,
--				(SELECT TOP 1 m.Time FROM fly_im_Message m where m.SessionId = s.Id ) AS [Time],
--				s.TargetType,
--				Target =CASE WHEN s.GroupId IS NOT NULL THEN s.GroupId WHEN s.Member1 <> @userId THEN s.Member1 ELSE s.Member2 END
--				FROM fly_im_Session s
--								where ((s.Member1 = @userId OR s.Member2 = @userId) 
--										OR EXISTS(SELECT * FROM dbo.fly_im_GetUserGroups(@userId) ug WHERE ug.Id = s.GroupId))
--		) session 
--		WHERE Time IS NOT NULL 
--		ORDER BY Time DESC





GO
/****** Object:  UserDefinedFunction [dbo].[fBox_CheckSpaceFileUserACL2]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		友百利
-- Create date: 2014-6-24 
-- Description:	检测用户文件权限
-- 返回值 ：是否有权限
-- =============================================
CREATE FUNCTION [dbo].[fBox_CheckSpaceFileUserACL2]
(
	@spaceFileId VARCHAR(36),
	@userId	VARCHAR(36),
	@checkAcl INT
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT Has= [dbo].[fBox_CheckSpaceFileUserACL](@spaceFileId,@userId,@checkAcl)
)




GO
/****** Object:  UserDefinedFunction [dbo].[fBox_GetFileChildren]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Kuiyou
-- Create date: 2012-11-9 3:50
-- Description:	查询所有下级Id
-- 查询结果 p.Level 表示级别，最上层的级别越大，最上层级别为0
-- =============================================
CREATE FUNCTION [dbo].[fBox_GetFileChildren] 
(
	@spaceFileId varchar(36)
)
RETURNS TABLE 
AS
RETURN 
(
	
	  WITH temp(Id,ParentId,Level) AS(
			SELECT Id,ParentId,Level=0 FROM fBox_SpaceFile WHERE id=@spaceFileId
			UNION ALL
			SELECT p.Id,p.ParentId,Level=t.Level-1 FROM fBox_SpaceFile p JOIN temp t ON p.ParentId=t.Id WHERE p.State<>2
		)
SELECT * FROM temp 
)




GO
/****** Object:  UserDefinedFunction [dbo].[fBox_GetFileParents]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Kuiyou
-- Create date: 2012-11-9 3:50
-- Description:	查询所有上级目录Id
-- 查询结果 p.Level 表示级别，最上层的级别越小
-- =============================================
CREATE FUNCTION [dbo].[fBox_GetFileParents] 
(
	@spaceFileId varchar(36),
	@includeRoot bit
)
RETURNS TABLE 
AS
RETURN 
(
	
	  WITH temp(Id,ParentId,Level) AS(
			SELECT Id,ParentId,Level=0 FROM fBox_SpaceFile WHERE id=@spaceFileId
			UNION ALL
			SELECT p.Id,p.ParentId,Level=t.Level-1 FROM fBox_SpaceFile p JOIN temp t 
				ON p.Id=t.ParentId 
				AND (@includeRoot=1 OR p.ParentId IS NOT NULL)
		)
		SELECT *,LEVEL-(SELECT MIN(LEVEL) FROM temp) as LevelPlus FROM temp 
)







GO
/****** Object:  UserDefinedFunction [dbo].[fBox_GetSpaceFileUserACL2]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





-- =============================================
-- Author:		友百利
-- Create date: 2014-6-24 
-- Description:	获取用户文件权限
-- 返回值 ：用户权限
--	没有:表示没有设置用户权限，是继承部门、用户组权限
--  :后面|表示通过自己设置，否则表示通过上级设置
-- =============================================
-- =============================================
CREATE FUNCTION [dbo].[fBox_GetSpaceFileUserACL2]
(
	@spaceFileId VARCHAR(36),
	@userId	VARCHAR(36)
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT Acl= [dbo].[fBox_GetSpaceFileUserACL](@spaceFileId,@userId)
)






GO
/****** Object:  UserDefinedFunction [dbo].[fly_GetChildOrgIds]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Kuiyou
-- Create date: 2014-3-15 19:23
-- Description:	查询所有下级单位Id
-- =============================================
CREATE FUNCTION [dbo].[fly_GetChildOrgIds] 
(
	@orgFileId varchar(36)
)
RETURNS TABLE 
AS
RETURN 
(
	  WITH temp(Id,ParentId) AS(
			SELECT Id,ParentId FROM fly_Org WHERE id=@orgFileId
			UNION ALL
			SELECT p.Id,p.ParentId FROM fly_Org p JOIN temp t ON p.ParentId=t.Id 
		)
SELECT * FROM temp 
)



GO
/****** Object:  UserDefinedFunction [dbo].[fly_GetParentOrgIds]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Kuiyou
-- Create date: 2014-3-15 19:23
-- Description:	查询所有上级单位Id
-- =============================================
CREATE FUNCTION [dbo].[fly_GetParentOrgIds] 
(
	@orgFileId varchar(36)
)
RETURNS TABLE 
AS
RETURN 
(
	  WITH temp(Id,ParentId) AS(
			SELECT Id,ParentId FROM fly_Org WHERE id=@orgFileId
			UNION ALL
			SELECT p.Id,p.ParentId FROM fly_Org p JOIN temp t ON p.Id=t.ParentId AND p.ParentId IS NOT NULL
		)
SELECT * FROM temp 
)



GO
/****** Object:  View [dbo].[fBox_User]    Script Date: 2016/6/30 13:02:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[fBox_User]
AS
SELECT   Id, OrgId, LoginName, NickName, Email, Password, MobilePhone, Sex, CASE WHEN EXISTS
                    (SELECT   *
                     FROM      fly_UserRole ur
                     WHERE   ur.UserId = u.Id AND EXISTS
                                         (SELECT   1
                                          FROM      fly_Role r
                                          WHERE   r.Id = ur.RoleId AND r.IsManager = 1 AND r.IsPublic = 1)) THEN CAST(1 AS BIT) 
                ELSE CAST(0 AS BIT) END AS IsDiskManager, DepartmentId, Status, IsManager
FROM      dbo.fly_User AS u





GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fBox_ShareFile ShareId,SpaceFileId]    Script Date: 2016/6/30 13:02:02 ******/
CREATE CLUSTERED INDEX [IX_fBox_ShareFile ShareId,SpaceFileId] ON [dbo].[fBox_ShareFile]
(
	[FetchCode] ASC,
	[SpaceFileId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fBox_ShareTarget FetchCode, Type, ToId]    Script Date: 2016/6/30 13:02:02 ******/
CREATE UNIQUE CLUSTERED INDEX [IX_fBox_ShareTarget FetchCode, Type, ToId] ON [dbo].[fBox_ShareTarget]
(
	[FetchCode] ASC,
	[Type] ASC,
	[ToId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fly_Follows UserId, InfoType, InfoId]    Script Date: 2016/6/30 13:02:02 ******/
CREATE CLUSTERED INDEX [IX_fly_Follows UserId, InfoType, InfoId] ON [dbo].[fly_Follows]
(
	[UserId] ASC,
	[InfoType] ASC,
	[InfoId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fly_im_Message]    Script Date: 2016/6/30 13:02:02 ******/
CREATE CLUSTERED INDEX [IX_fly_im_Message] ON [dbo].[fly_im_Message]
(
	[SessionId] ASC,
	[Time] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fly_KeyValue]    Script Date: 2016/6/30 13:02:02 ******/
CREATE CLUSTERED INDEX [IX_fly_KeyValue] ON [dbo].[fly_KeyValue]
(
	[Key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fBox_VisitLog FollowId,Action,UserId]    Script Date: 2016/6/30 13:02:02 ******/
CREATE CLUSTERED INDEX [IX_fBox_VisitLog FollowId,Action,UserId] ON [dbo].[fly_Log]
(
	[InfoId] ASC,
	[Action] ASC,
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fly_RoleFunction]    Script Date: 2016/6/30 13:02:02 ******/
CREATE UNIQUE CLUSTERED INDEX [IX_fly_RoleFunction] ON [dbo].[fly_RoleFunction]
(
	[RoleId] ASC,
	[FunctionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fly_RoleModule]    Script Date: 2016/6/30 13:02:02 ******/
CREATE UNIQUE CLUSTERED INDEX [IX_fly_RoleModule] ON [dbo].[fly_RoleModule]
(
	[RoleId] ASC,
	[ModuleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fly_UserRole]    Script Date: 2016/6/30 13:02:02 ******/
CREATE UNIQUE CLUSTERED INDEX [IX_fly_UserRole] ON [dbo].[fly_UserRole]
(
	[UserId] ASC,
	[RoleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
INSERT [dbo].[fBox_OrgSpace] ([OrgId], [SpaceId]) VALUES (N'80000001', N'so00o100')
INSERT [dbo].[fBox_OrgSpaceSize] ([OrgId], [SpaceSize], [Used]) VALUES (N'80000001', 107374182400, 0)
INSERT [dbo].[fBox_RoleSpaceSize] ([RoleId], [OrgId], [SpaceSize]) VALUES (N'16000001', N'80000001', 10737418240)
INSERT [dbo].[fBox_RoleSpaceSize] ([RoleId], [OrgId], [SpaceSize]) VALUES (N'16000004', N'80000001', 10737418240)
INSERT [dbo].[fBox_RoleSpaceSize] ([RoleId], [OrgId], [SpaceSize]) VALUES (N'16000016', N'80000001', 5368709120)
INSERT [dbo].[fBox_Shortcuts] ([Id], [Location], [Owner], [InfoType], [InfoId], [Name], [Remark]) VALUES (N'00000001', N'LeftMenu', N'so00o100.', N'SpaceFile', N'd0000020', NULL, NULL)
INSERT [dbo].[fBox_Shortcuts] ([Id], [Location], [Owner], [InfoType], [InfoId], [Name], [Remark]) VALUES (N'00000002', N'LeftMenu', N'so00o100.', N'SpaceFile', N'd0000035', NULL, NULL)
INSERT [dbo].[fBox_Shortcuts] ([Id], [Location], [Owner], [InfoType], [InfoId], [Name], [Remark]) VALUES (N'00000003', N'LeftMenu', N'so00o100.', N'SpaceFile', N'd0000021', NULL, NULL)
INSERT [dbo].[fBox_Shortcuts] ([Id], [Location], [Owner], [InfoType], [InfoId], [Name], [Remark]) VALUES (N'00000004', N'LeftMenu', N'so00o100.', N'SpaceFile', N'd0000023', NULL, NULL)
INSERT [dbo].[fBox_Shortcuts] ([Id], [Location], [Owner], [InfoType], [InfoId], [Name], [Remark]) VALUES (N'00000005', N'LeftMenu', N'so00o100.', N'SpaceFile', N'd0000022', NULL, NULL)
INSERT [dbo].[fBox_Shortcuts] ([Id], [Location], [Owner], [InfoType], [InfoId], [Name], [Remark]) VALUES (N'00000006', N'LeftMenu', N'so00o100.', N'SpaceFile', N'd0000040', NULL, NULL)
INSERT [dbo].[fBox_Shortcuts] ([Id], [Location], [Owner], [InfoType], [InfoId], [Name], [Remark]) VALUES (N'00000007', N'LeftMenu', N'so00o100.', N'SpaceFile', N'd0000011', NULL, NULL)
INSERT [dbo].[fBox_Shortcuts] ([Id], [Location], [Owner], [InfoType], [InfoId], [Name], [Remark]) VALUES (N'00000008', N'LeftMenu', N'so00o100.', N'SpaceFile', N'd0000031', NULL, NULL)
INSERT [dbo].[fBox_Shortcuts] ([Id], [Location], [Owner], [InfoType], [InfoId], [Name], [Remark]) VALUES (N'00000009', N'LeftMenu', N'so00o100.', N'SpaceFile', N'd0000037', NULL, NULL)
INSERT [dbo].[fBox_Shortcuts] ([Id], [Location], [Owner], [InfoType], [InfoId], [Name], [Remark]) VALUES (N'00000010', N'LeftMenu', N'so00o100.', N'SpaceFile', N'd0000016', NULL, NULL)
INSERT [dbo].[fBox_Shortcuts] ([Id], [Location], [Owner], [InfoType], [InfoId], [Name], [Remark]) VALUES (N'00000011', N'LeftMenu', N'so00o100.', N'SpaceFile', N'd0000005', NULL, NULL)
INSERT [dbo].[fBox_Space] ([Id], [Size], [Used], [Initialized]) VALUES (N'so00o100', 107374182400, 0, 1)
INSERT [dbo].[fBox_Space] ([Id], [Size], [Used], [Initialized]) VALUES (N'su00F100', 10737418240, 0, 1)
INSERT [dbo].[fBox_Space] ([Id], [Size], [Used], [Initialized]) VALUES (N'su00F101', 10737418240, 0, 1)
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000002', NULL, N'so00o100', N'活动照片、视频', N'd000o100', 0, NULL, N'2000000001', NULL, CAST(0x0000A45200B3709E AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A45200B3709E AS DateTime), CAST(0x0000A45200B3709E AS DateTime), NULL, N'/d000o100/d0000002')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000003', NULL, N'so00o100', N'教案', N'd0000024', 0, NULL, N'2000000001', NULL, CAST(0x0000A45200B94ECA AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A45200B94ECA AS DateTime), CAST(0x0000A45200B94ECA AS DateTime), NULL, N'/d000o100/d0000024/d0000003')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000004', NULL, N'su00F100', N'我的文档', N'd000F100', 0, N'document', N'2000000001', NULL, CAST(0x0000A1C40020BCC2 AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A2D5014C290F AS DateTime), CAST(0x0000A2D5014C290F AS DateTime), NULL, N'/d000F100/d0000004')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000005', NULL, N'so00o100', N'学生处', N'd0000010', 0, NULL, N'2000000001', NULL, CAST(0x0000A45200B1AF20 AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A45200B1AF20 AS DateTime), CAST(0x0000A45200B1AF20 AS DateTime), NULL, N'/d000o100/d0000010/d0000005')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000006', NULL, N'so00o100', N'高二', N'd0000014', 0, NULL, N'2000000001', NULL, CAST(0x0000A45200B2CBBB AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A45200B2CBBB AS DateTime), CAST(0x0000A45200B2CBBB AS DateTime), NULL, N'/d000o100/d0000014/d0000006')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000007', NULL, N'so00o100', N'数据报送', N'd000o100', 0, NULL, N'2000000001', NULL, CAST(0x0000A45200ABE514 AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A45200BC6014 AS DateTime), CAST(0x0000A45200BC6014 AS DateTime), NULL, N'/d000o100/d0000007')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000008', NULL, N'so00o100', N'课件', N'd0000024', 0, NULL, N'2000000001', NULL, CAST(0x0000A45200B957AF AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A45200B957AF AS DateTime), CAST(0x0000A45200B957AF AS DateTime), NULL, N'/d000o100/d0000024/d0000008')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000009', NULL, N'so00o100', N'高三', N'd0000014', 0, NULL, N'2000000001', NULL, CAST(0x0000A45200B2D432 AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A45200B2D432 AS DateTime), CAST(0x0000A45200B2D432 AS DateTime), NULL, N'/d000o100/d0000014/d0000009')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000010', NULL, N'so00o100', N'部门数据', N'd000o100', 0, NULL, N'2000000001', NULL, CAST(0x0000A45200B3283E AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A45200B3283E AS DateTime), CAST(0x0000A45200B3283E AS DateTime), NULL, N'/d000o100/d0000010')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000011', NULL, N'so00o100', N'招生办', N'd0000010', 0, NULL, N'2000000001', NULL, CAST(0x0000A45200AFE09C AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A45200B1CD83 AS DateTime), CAST(0x0000A45200B1CD83 AS DateTime), NULL, N'/d000o100/d0000010/d0000011')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000012', NULL, N'so00o100', N'重大事故月报', N'd0000007', 0, NULL, N'2000000001', NULL, CAST(0x0000A45200BC8C4F AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A45200BC8C4F AS DateTime), CAST(0x0000A45200BC8C4F AS DateTime), NULL, N'/d000o100/d0000007/d0000012')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000013', NULL, N'so00o100', N'高三三班', N'd0000009', 0, NULL, N'2000000001', NULL, CAST(0x0000A45200B8A3B8 AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A45200B8A3B8 AS DateTime), CAST(0x0000A45200B8A3B8 AS DateTime), NULL, N'/d000o100/d0000014/d0000009/d0000013')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000014', NULL, N'so00o100', N'班级数据', N'd000o100', 0, NULL, N'2000000001', NULL, CAST(0x0000A45200B2F0D8 AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A45200B2F0D8 AS DateTime), CAST(0x0000A45200B2F0D8 AS DateTime), NULL, N'/d000o100/d0000014')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000015', NULL, N'so00o100', N'高三二班', N'd0000009', 0, NULL, N'2000000001', NULL, CAST(0x0000A45200B55B14 AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A45200B55B14 AS DateTime), CAST(0x0000A45200B55B14 AS DateTime), NULL, N'/d000o100/d0000014/d0000009/d0000015')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000016', NULL, N'so00o100', N'团支部', N'd0000010', 0, NULL, N'2000000001', NULL, CAST(0x0000A45200B22258 AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A45200B196DC AS DateTime), CAST(0x0000A45200B196DC AS DateTime), NULL, N'/d000o100/d0000010/d0000016')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000017', NULL, N'so00o100', N'常用文档', N'd000o100', 0, NULL, N'2000000001', NULL, CAST(0x0000A45200B38EED AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A45200B38EED AS DateTime), CAST(0x0000A45200B38EED AS DateTime), NULL, N'/d000o100/d0000017')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000018', NULL, N'su00F100', N'我的视频', N'd000F100', 0, N'video', N'2000000001', NULL, CAST(0x0000A1C40020BCC7 AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A2D5014C290F AS DateTime), CAST(0x0000A2D5014C290F AS DateTime), NULL, N'/d000F100/d0000018')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000019', NULL, N'su00F100', N'我的相册', N'd000F100', 0, N'photo', N'2000000001', NULL, CAST(0x0000A1C40020BCC2 AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A2D5014C290F AS DateTime), CAST(0x0000A2D5014C290F AS DateTime), NULL, N'/d000F100/d0000019')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000020', NULL, N'so00o100', N'工会', N'd0000010', 0, NULL, N'2000000001', NULL, CAST(0x0000A45200B0F52C AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A45200B182BA AS DateTime), CAST(0x0000A45200B182BA AS DateTime), NULL, N'/d000o100/d0000010/d0000020')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000021', NULL, N'so00o100', N'督导室', N'd0000010', 0, NULL, N'2000000001', NULL, CAST(0x0000A45200B1793B AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A45200B1793B AS DateTime), CAST(0x0000A45200B1793B AS DateTime), NULL, N'/d000o100/d0000010/d0000021')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000022', NULL, N'so00o100', N'信息中心', N'd0000010', 0, NULL, N'2000000001', NULL, CAST(0x0000A45200B1A396 AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A45200B1A396 AS DateTime), CAST(0x0000A45200B1A396 AS DateTime), NULL, N'/d000o100/d0000010/d0000022')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000023', NULL, N'so00o100', N'校长室', N'd0000010', 0, NULL, N'2000000001', NULL, CAST(0x0000A45200B2B600 AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A45200B19D28 AS DateTime), CAST(0x0000A45200B19D28 AS DateTime), NULL, N'/d000o100/d0000010/d0000023')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000024', NULL, N'so00o100', N'教学资源', N'd000o100', 0, NULL, N'2000000001', NULL, CAST(0x0000A45200B4B1BF AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A45200B4B1BF AS DateTime), CAST(0x0000A45200B4B1BF AS DateTime), NULL, N'/d000o100/d0000024')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000025', NULL, N'so00o100', N'卫生检查', N'd0000007', 0, NULL, N'2000000001', NULL, CAST(0x0000A45200BC9F12 AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A45200BC9F12 AS DateTime), CAST(0x0000A45200BC9F12 AS DateTime), NULL, N'/d000o100/d0000007/d0000025')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000026', NULL, N'so00o100', N'高一', N'd0000014', 0, NULL, N'2000000001', NULL, CAST(0x0000A45200B2C473 AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A45200B2C473 AS DateTime), CAST(0x0000A45200B2C473 AS DateTime), NULL, N'/d000o100/d0000014/d0000026')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000027', NULL, N'so00o100', N'素材', N'd0000024', 0, NULL, N'2000000001', NULL, CAST(0x0000A45200B9675F AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A45200B9675F AS DateTime), CAST(0x0000A45200B9675F AS DateTime), NULL, N'/d000o100/d0000024/d0000027')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000028', NULL, N'so00o100', N'教师风采', N'd000o100', 0, NULL, N'2000000001', NULL, CAST(0x0000A45200B358FC AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A45200B358FC AS DateTime), CAST(0x0000A45200B358FC AS DateTime), NULL, N'/d000o100/d0000028')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000029', NULL, N'su00F101', N'我的视频', N'd000F101', 0, N'video', N'2000000002', NULL, CAST(0x0000A1C4001F36B9 AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A2D5014C290F AS DateTime), CAST(0x0000A2D5014C290F AS DateTime), NULL, N'/d000F101/d0000029')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000030', NULL, N'so00o100', N'手足口周报', N'd0000007', 0, NULL, N'2000000001', NULL, CAST(0x0000A45200BC7D8A AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A45200BC7D8A AS DateTime), CAST(0x0000A45200BC7D8A AS DateTime), NULL, N'/d000o100/d0000007/d0000030')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000031', NULL, N'so00o100', N'党支部', N'd0000010', 0, NULL, N'2000000001', NULL, CAST(0x0000A45200B24454 AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A45200B17205 AS DateTime), CAST(0x0000A45200B17205 AS DateTime), NULL, N'/d000o100/d0000010/d0000031')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000033', NULL, N'su00F101', N'我的相册', N'd000F101', 0, N'photo', N'2000000002', NULL, CAST(0x0000A1C4001F36B9 AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A2D5014C290F AS DateTime), CAST(0x0000A2D5014C290F AS DateTime), NULL, N'/d000F101/d0000033')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000034', NULL, N'so00o100', N'高三一班', N'd0000009', 0, NULL, N'2000000001', NULL, CAST(0x0000A45200B550E3 AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A45200B550E3 AS DateTime), CAST(0x0000A45200B550E3 AS DateTime), NULL, N'/d000o100/d0000014/d0000009/d0000034')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000035', NULL, N'so00o100', N'总务处', N'd0000010', 0, NULL, N'2000000001', NULL, CAST(0x0000A45200B14734 AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A45200B1D406 AS DateTime), CAST(0x0000A45200B1D406 AS DateTime), NULL, N'/d000o100/d0000010/d0000035')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000036', NULL, N'su00F100', N'作业', N'd000F100', 0, NULL, N'2000000001', NULL, CAST(0x0000A45200BD5CA3 AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A45200BD5CA3 AS DateTime), CAST(0x0000A45200BD5CA3 AS DateTime), NULL, N'/d000F100/d0000036')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000037', NULL, N'so00o100', N'教务处', N'd0000010', 0, NULL, N'2000000001', NULL, CAST(0x0000A45200B1D17C AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A45200B18B7A AS DateTime), CAST(0x0000A45200B18B7A AS DateTime), NULL, N'/d000o100/d0000010/d0000037')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000038', NULL, N'so00o100', N'校园风光', N'd000o100', 0, NULL, N'2000000001', NULL, CAST(0x0000A45200B3457C AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A45200B3457C AS DateTime), CAST(0x0000A45200B3457C AS DateTime), NULL, N'/d000o100/d0000038')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000040', NULL, N'so00o100', N'办公室', N'd0000010', 0, NULL, N'2000000001', NULL, CAST(0x0000A45200B168B2 AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A45200B168B2 AS DateTime), CAST(0x0000A45200B168B2 AS DateTime), NULL, N'/d000o100/d0000010/d0000040')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000041', NULL, N'su00F101', N'我的文档', N'd000F101', 0, N'document', N'2000000002', NULL, CAST(0x0000A1C4001F3649 AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A2D5014C290F AS DateTime), CAST(0x0000A2D5014C290F AS DateTime), NULL, N'/d000F101/d0000041')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000042', NULL, N'su00F101', N'我的音乐', N'd000F101', 0, N'music', N'2000000002', NULL, CAST(0x0000A1C4001F36B9 AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A2D5014C290F AS DateTime), CAST(0x0000A2D5014C290F AS DateTime), NULL, N'/d000F101/d0000042')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd0000043', NULL, N'su00F100', N'我的音乐', N'd000F100', 0, N'music', N'2000000001', NULL, CAST(0x0000A1C40020BCC2 AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A2D5014C290F AS DateTime), CAST(0x0000A2D5014C290F AS DateTime), NULL, N'/d000F100/d0000043')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd000F100', NULL, N'su00F100', N'', NULL, 0, NULL, N'2000000001', NULL, CAST(0x0000A2D601385B6E AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A2D601385B6E AS DateTime), CAST(0x0000A2D601385B6E AS DateTime), NULL, N'/d000F100')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd000F101', NULL, N'su00F101', N'', NULL, 0, NULL, N'2000000002', NULL, CAST(0x0000A2D601385B63 AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A2D601385B63 AS DateTime), CAST(0x0000A2D601385B63 AS DateTime), NULL, N'/d000F101')
INSERT [dbo].[fBox_SpaceFile] ([Id], [FileId], [SpaceID], [Name], [ParentId], [Size], [Extension], [UserId], [Remark], [Time], [Star], [ShareCount], [Type], [State], [ACL], [ArticleId], [Version], [ContentVersion], [MaxSize], [Path]) VALUES (N'd000o100', NULL, N'so00o100', N'', NULL, 0, NULL, N'2000000001', NULL, CAST(0x0000A2D601385B5F AS DateTime), 0, 0, -1, 1, NULL, NULL, CAST(0x0000A2D601385B5F AS DateTime), CAST(0x0000A2D601385B5F AS DateTime), NULL, N'/d000o100')
INSERT [dbo].[fBox_SpaceFileAuths] ([ACL], [Title], [Name]) VALUES (1, N'Manage', N'管理')
INSERT [dbo].[fBox_SpaceFileAuths] ([ACL], [Title], [Name]) VALUES (2, N'Open', N'浏览')
INSERT [dbo].[fBox_SpaceFileAuths] ([ACL], [Title], [Name]) VALUES (4, N'CreateDir', N'创建文件夹')
INSERT [dbo].[fBox_SpaceFileAuths] ([ACL], [Title], [Name]) VALUES (16, N'Upload', N'上传')
INSERT [dbo].[fBox_SpaceFileAuths] ([ACL], [Title], [Name]) VALUES (32, N'Download', N'下载')
INSERT [dbo].[fBox_SpaceFileAuths] ([ACL], [Title], [Name]) VALUES (64, N'Comment', N'评论')
INSERT [dbo].[fBox_SpaceFileAuths] ([ACL], [Title], [Name]) VALUES (256, N'Score', N'评分')
INSERT [dbo].[fBox_Store] ([Id], [Path], [Size], [Used], [IsDisabled]) VALUES (N'su00F100', N'~\..\upload-files\', 536870912000, 0, 0)
INSERT [dbo].[fBox_UserSpace] ([UserId], [SpaceId]) VALUES (N'2000000001', N'su00F100')
INSERT [dbo].[fBox_UserSpace] ([UserId], [SpaceId]) VALUES (N'2000000002', N'su00F101')
INSERT [dbo].[fly_Config] ([For], [Type], [Name], [Value]) VALUES (N'Fly.Box', N'Account', N'ResetPasswordMailBody', N'
<p>你好，{UserName}：</p>
<p>你申请了重设{Site}密码，点击下面的链接，你可以直接登录到系统，进入系统后进入“设置>帐号>重新输入密码”即可重设密码：</p>
<p><a href="{Link}" target="_blank">{Link}</a></p>
<p>如果链接无法点击，请完整拷贝到浏览器地址栏里直接访问。</p>
<p>-</p>
<p><a href="{SiteUrl}" target="_blank">{Site}</a>

</p>')
INSERT [dbo].[fly_Config] ([For], [Type], [Name], [Value]) VALUES (N'Fly.Box', N'Space', N'AllotSpaceByRole', N'1')
INSERT [dbo].[fly_Config] ([For], [Type], [Name], [Value]) VALUES (N'SYS', N'Email', N'Email', N'flyCms@126.com')
INSERT [dbo].[fly_Config] ([For], [Type], [Name], [Value]) VALUES (N'SYS', N'Email', N'Smtp', N'smtp.126.com,flyCms,flycms123')
INSERT [dbo].[fly_Config] ([For], [Type], [Name], [Value]) VALUES (N'SYS', N'LC', N'F', N'c,0,635247850602024512')
INSERT [dbo].[fly_Config] ([For], [Type], [Name], [Value]) VALUES (N'SYS', N'Sys.Setting', N'SuperExModifyTime', N'2015-03-05 10:26:29')
INSERT [dbo].[fly_Department] ([Id], [OrgId], [ParentId], [Name], [Address], [Phone], [ContactPerson], [ManagerUserId], [Type], [IsShow]) VALUES (N'40000001', N'80000001', NULL, N'办公室', N'', N'', N'', N'', NULL, 1)
INSERT [dbo].[fly_Department] ([Id], [OrgId], [ParentId], [Name], [Address], [Phone], [ContactPerson], [ManagerUserId], [Type], [IsShow]) VALUES (N'40000002', N'80000001', NULL, N'招生办', N'', N'', N'', NULL, NULL, 1)
INSERT [dbo].[fly_Department] ([Id], [OrgId], [ParentId], [Name], [Address], [Phone], [ContactPerson], [ManagerUserId], [Type], [IsShow]) VALUES (N'40000003', N'80000001', NULL, N'工会', N'', N'', N'', N'', NULL, 1)
INSERT [dbo].[fly_Department] ([Id], [OrgId], [ParentId], [Name], [Address], [Phone], [ContactPerson], [ManagerUserId], [Type], [IsShow]) VALUES (N'40000004', N'80000001', NULL, N'团支部', N'', N'', N'', NULL, NULL, 1)
INSERT [dbo].[fly_Department] ([Id], [OrgId], [ParentId], [Name], [Address], [Phone], [ContactPerson], [ManagerUserId], [Type], [IsShow]) VALUES (N'40000005', N'80000001', NULL, N'学生处', N'', N'', N'', N'', NULL, 1)
INSERT [dbo].[fly_Department] ([Id], [OrgId], [ParentId], [Name], [Address], [Phone], [ContactPerson], [ManagerUserId], [Type], [IsShow]) VALUES (N'40000006', N'80000001', NULL, N'信息中心', N'', N'', N'', NULL, NULL, 1)
INSERT [dbo].[fly_Department] ([Id], [OrgId], [ParentId], [Name], [Address], [Phone], [ContactPerson], [ManagerUserId], [Type], [IsShow]) VALUES (N'40000007', N'80000001', NULL, N'教务处', N'', N'', N'', N'', NULL, 1)
INSERT [dbo].[fly_Department] ([Id], [OrgId], [ParentId], [Name], [Address], [Phone], [ContactPerson], [ManagerUserId], [Type], [IsShow]) VALUES (N'40000008', N'80000001', NULL, N'督导室', N'', N'', N'', NULL, NULL, 1)
INSERT [dbo].[fly_Department] ([Id], [OrgId], [ParentId], [Name], [Address], [Phone], [ContactPerson], [ManagerUserId], [Type], [IsShow]) VALUES (N'40000009', N'80000001', NULL, N'党支部', N'', N'', N'', NULL, NULL, 1)
INSERT [dbo].[fly_Department] ([Id], [OrgId], [ParentId], [Name], [Address], [Phone], [ContactPerson], [ManagerUserId], [Type], [IsShow]) VALUES (N'40000010', N'80000001', NULL, N'总务处', N'', N'', N'', NULL, NULL, 1)
INSERT [dbo].[fly_Department] ([Id], [OrgId], [ParentId], [Name], [Address], [Phone], [ContactPerson], [ManagerUserId], [Type], [IsShow]) VALUES (N'40000011', N'80000001', NULL, N'校长室', N'', N'', N'', NULL, NULL, 1)
INSERT [dbo].[fly_Function] ([Id], [ModuleId], [Key], [Name], [Description]) VALUES (N'00000000-CB00-0000-1000-000000000010', N'00000000-CB00-0000-1000-000000000000', N'Share', N'分享', N'公开分享资源')
INSERT [dbo].[fly_Function] ([Id], [ModuleId], [Key], [Name], [Description]) VALUES (N'00000000-CB00-0000-1000-000000000020', N'00000000-CB00-0000-1000-000000000000', N'CommentShare', N'评论分享', N'')
INSERT [dbo].[fly_Function] ([Id], [ModuleId], [Key], [Name], [Description]) VALUES (N'00000000-CB00-0000-1000-000000000030', N'00000000-CB00-0000-1000-000000000000', N'CommentFile', N'评论文件', N'')
INSERT [dbo].[fly_Function] ([Id], [ModuleId], [Key], [Name], [Description]) VALUES (N'00000000-CB00-0000-1000-000000000040', N'00000000-CB00-0000-1000-000000000000', N'ScoreShare', N'给分享打分', N'')
INSERT [dbo].[fly_Function] ([Id], [ModuleId], [Key], [Name], [Description]) VALUES (N'00000000-CB00-0000-1000-000000000050', N'00000000-CB00-0000-1000-000000000000', N'ScoreFile', N'给文件打分', N'')
INSERT [dbo].[fly_Function] ([Id], [ModuleId], [Key], [Name], [Description]) VALUES (N'00000000-CB00-0000-1000-000000000060', N'00000000-CB00-0000-1000-000000000000', N'PraiseShare', N'赞分享', N'')
INSERT [dbo].[fly_Function] ([Id], [ModuleId], [Key], [Name], [Description]) VALUES (N'00000000-CB00-0000-1000-000000000070', N'00000000-CB00-0000-1000-000000000000', N'PraiseFile', N'赞文件', N'')
INSERT [dbo].[fly_Module] ([Id], [PluginId], [Key], [Name], [ParentId], [Type], [Url]) VALUES (N'00000000-BA00-0000-1000-000000000000', N'00000000-BA00-0000-0000-000000000000', N'BaseInfo', N'基础信息', NULL, -1, NULL)
INSERT [dbo].[fly_Module] ([Id], [PluginId], [Key], [Name], [ParentId], [Type], [Url]) VALUES (N'00000000-BA00-0000-2000-000000000000', N'00000000-BA00-0000-0000-000000000000', N'OrgInfo', N'单位信息设置', NULL, -1, NULL)
INSERT [dbo].[fly_Module] ([Id], [PluginId], [Key], [Name], [ParentId], [Type], [Url]) VALUES (N'00000000-BA00-0000-3000-000000000000', N'00000000-BA00-0000-0000-000000000000', N'Org', N'单位', NULL, -1, NULL)
INSERT [dbo].[fly_Module] ([Id], [PluginId], [Key], [Name], [ParentId], [Type], [Url]) VALUES (N'00000000-BA00-0000-4000-000000000000', N'00000000-BA00-0000-0000-000000000000', N'Department', N'部门', NULL, -1, NULL)
INSERT [dbo].[fly_Module] ([Id], [PluginId], [Key], [Name], [ParentId], [Type], [Url]) VALUES (N'00000000-BA00-0000-5000-000000000000', N'00000000-BA00-0000-0000-000000000000', N'UserInfo', N'个人信息设置', NULL, -1, NULL)
INSERT [dbo].[fly_Module] ([Id], [PluginId], [Key], [Name], [ParentId], [Type], [Url]) VALUES (N'00000000-BA00-0000-6000-000000000000', N'00000000-BA00-0000-0000-000000000000', N'User', N'用户', NULL, -1, NULL)
INSERT [dbo].[fly_Module] ([Id], [PluginId], [Key], [Name], [ParentId], [Type], [Url]) VALUES (N'00000000-BA00-0000-7000-000000000000', N'00000000-BA00-0000-0000-000000000000', N'Role', N'用户组', NULL, -1, NULL)
INSERT [dbo].[fly_Module] ([Id], [PluginId], [Key], [Name], [ParentId], [Type], [Url]) VALUES (N'00000000-CB00-0000-1000-000000000000', N'00000000-CB00-0000-0000-000000000000', N'Common', N'常规', NULL, -1, NULL)
INSERT [dbo].[fly_Org] ([Id], [ParentId], [Name], [Address], [Phone], [ContactPerson], [RegistTime], [Status]) VALUES (N'80000001', NULL, N'XXX第一高级中学', N'某省', N'', N'', CAST(0x0000A14D00A0DDDC AS DateTime), 1)
INSERT [dbo].[fly_Plugin] ([Id], [Path], [Name], [Enable], [Description], [Author], [Site]) VALUES (N'00000000-BA00-0000-0000-000000000000', N'', N'基础资料', 1, N'Fly 基础资料', N'Fly', N'http://www.flyui.net')
INSERT [dbo].[fly_Plugin] ([Id], [Path], [Name], [Enable], [Description], [Author], [Site]) VALUES (N'00000000-CB00-0000-0000-000000000000', N'', N'Fly.Box 企业网盘', 1, N'Fly.Box 企业网盘', N'Fly', N'http://www.flyui.net')
INSERT [dbo].[fly_Role] ([Id], [OrgId], [Name], [IsManager], [IsPublic], [Type]) VALUES (N'16000001', N'80000001', N'系统管理员', 1, 1, N'0')
INSERT [dbo].[fly_Role] ([Id], [OrgId], [Name], [IsManager], [IsPublic], [Type]) VALUES (N'16000004', N'80000001', N'普通用户', 0, 1, N'0')
INSERT [dbo].[fly_Role] ([Id], [OrgId], [Name], [IsManager], [IsPublic], [Type]) VALUES (N'16000016', N'80000001', N'注册用户', 0, 1, N'')
INSERT [dbo].[fly_RoleFunction] ([Id], [RoleId], [FunctionId]) VALUES (N'0B107F92-3699-48EF-B29D-98517EFB7898', N'16000001', N'00000000-CB00-0000-1000-000000000030')
INSERT [dbo].[fly_RoleFunction] ([Id], [RoleId], [FunctionId]) VALUES (N'1D6E7593-122F-4169-9B4C-FA493445FCC9', N'16000004', N'00000000-CB00-0000-1000-000000000030')
INSERT [dbo].[fly_RoleFunction] ([Id], [RoleId], [FunctionId]) VALUES (N'233BCE90-0CFC-4DBA-9287-803584369BDD', N'16000001', N'00000000-CB00-0000-1000-000000000050')
INSERT [dbo].[fly_RoleFunction] ([Id], [RoleId], [FunctionId]) VALUES (N'2E562B42-0378-4CF1-ADE8-ADECE65D2FF3', N'16000001', N'00000000-CB00-0000-1000-000000000070')
INSERT [dbo].[fly_RoleFunction] ([Id], [RoleId], [FunctionId]) VALUES (N'3392956B-6FD4-4070-84B8-E79B5AA424D6', N'16000004', N'00000000-CB00-0000-1000-000000000070')
INSERT [dbo].[fly_RoleFunction] ([Id], [RoleId], [FunctionId]) VALUES (N'42C89BBC-6502-40CA-B69A-D6603D10C167', N'16000001', N'00000000-CB00-0000-1000-000000000060')
INSERT [dbo].[fly_RoleFunction] ([Id], [RoleId], [FunctionId]) VALUES (N'6495260D-7EDB-495E-8EE2-F1E50DFA006E', N'16000016', N'00000000-CB00-0000-1000-000000000010')
INSERT [dbo].[fly_RoleFunction] ([Id], [RoleId], [FunctionId]) VALUES (N'6573AE56-50C7-4E57-BD70-F9B2F16AB3BE', N'16000001', N'00000000-CB00-0000-1000-000000000010')
INSERT [dbo].[fly_RoleFunction] ([Id], [RoleId], [FunctionId]) VALUES (N'66CC89E4-E223-48C0-8E8C-E8E096907250', N'16000016', N'00000000-CB00-0000-1000-000000000060')
INSERT [dbo].[fly_RoleFunction] ([Id], [RoleId], [FunctionId]) VALUES (N'7EDAAEC3-B315-4F92-9AA9-3221F9AE682F', N'16000001', N'00000000-CB00-0000-1000-000000000040')
INSERT [dbo].[fly_RoleFunction] ([Id], [RoleId], [FunctionId]) VALUES (N'82C4DF76-09FA-4D8C-80FD-B4645C0BDA24', N'16000016', N'00000000-CB00-0000-1000-000000000030')
INSERT [dbo].[fly_RoleFunction] ([Id], [RoleId], [FunctionId]) VALUES (N'85B5178C-DCAB-431B-B72A-BA746CF43C39', N'16000004', N'00000000-CB00-0000-1000-000000000060')
INSERT [dbo].[fly_RoleFunction] ([Id], [RoleId], [FunctionId]) VALUES (N'85E9FF10-0323-4ED0-9DAB-6A3775F033AC', N'16000001', N'00000000-CB00-0000-1000-000000000020')
INSERT [dbo].[fly_RoleFunction] ([Id], [RoleId], [FunctionId]) VALUES (N'9BDE37D1-761C-42AE-896D-53F480ED20BB', N'16000016', N'00000000-CB00-0000-1000-000000000070')
INSERT [dbo].[fly_RoleFunction] ([Id], [RoleId], [FunctionId]) VALUES (N'9C0DE0BE-FA1D-46B1-BA32-5D378B05BAE7', N'16000004', N'00000000-CB00-0000-1000-000000000050')
INSERT [dbo].[fly_RoleFunction] ([Id], [RoleId], [FunctionId]) VALUES (N'AC83BBB4-E38A-4237-99E3-D0849EA1095F', N'16000004', N'00000000-CB00-0000-1000-000000000010')
INSERT [dbo].[fly_RoleFunction] ([Id], [RoleId], [FunctionId]) VALUES (N'AD133B46-E308-4714-B2E8-034898F7C4A2', N'16000016', N'00000000-CB00-0000-1000-000000000050')
INSERT [dbo].[fly_RoleFunction] ([Id], [RoleId], [FunctionId]) VALUES (N'AF821E6E-F6D2-4DD2-A617-45A594C26CCA', N'16000004', N'00000000-CB00-0000-1000-000000000040')
INSERT [dbo].[fly_RoleFunction] ([Id], [RoleId], [FunctionId]) VALUES (N'B8EBD30B-A5BE-4A10-9DA3-88AF12BCA30A', N'16000016', N'00000000-CB00-0000-1000-000000000020')
INSERT [dbo].[fly_RoleFunction] ([Id], [RoleId], [FunctionId]) VALUES (N'B96FE33E-0D0B-4654-8311-E29D2EE1929B', N'16000016', N'00000000-CB00-0000-1000-000000000040')
INSERT [dbo].[fly_RoleFunction] ([Id], [RoleId], [FunctionId]) VALUES (N'ED0757BC-9A2A-40B0-83D6-8ABD31E9662A', N'16000004', N'00000000-CB00-0000-1000-000000000020')
INSERT [dbo].[fly_RoleModule] ([Id], [RoleId], [ModuleId]) VALUES (N'1887A71D-8E38-4968-871A-855C843D0213', N'16000001', N'00000000-BA00-0000-7000-000000000000')
INSERT [dbo].[fly_RoleModule] ([Id], [RoleId], [ModuleId]) VALUES (N'1D47210A-26FE-4A4F-94E8-0DCEEFD3261D', N'16000004', N'00000000-BA00-0000-3000-000000000000')
INSERT [dbo].[fly_RoleModule] ([Id], [RoleId], [ModuleId]) VALUES (N'1F80DA24-EED6-4248-A1FE-CA46BA5A0963', N'16000004', N'00000000-BA00-0000-6000-000000000000')
INSERT [dbo].[fly_RoleModule] ([Id], [RoleId], [ModuleId]) VALUES (N'21C11971-47C4-47AE-B565-57E67BBF463B', N'16000001', N'00000000-BA00-0000-1000-000000000000')
INSERT [dbo].[fly_RoleModule] ([Id], [RoleId], [ModuleId]) VALUES (N'237DA089-2643-432B-8914-0A9650C75415', N'16000001', N'00000000-BA00-0000-2000-000000000000')
INSERT [dbo].[fly_RoleModule] ([Id], [RoleId], [ModuleId]) VALUES (N'2A7AEE0D-6092-4A06-8EB0-959247D7FFFA', N'16000001', N'00000000-CB00-0000-1000-000000000000')
INSERT [dbo].[fly_RoleModule] ([Id], [RoleId], [ModuleId]) VALUES (N'3320E331-3A90-4DA9-80A8-675FE86AB279', N'16000004', N'00000000-BA00-0000-5000-000000000000')
INSERT [dbo].[fly_RoleModule] ([Id], [RoleId], [ModuleId]) VALUES (N'48DF0722-4ED4-4914-93C3-86A1D2BC08AD', N'16000001', N'00000000-BA00-0000-3000-000000000000')
INSERT [dbo].[fly_RoleModule] ([Id], [RoleId], [ModuleId]) VALUES (N'6254F562-D606-4CE8-874F-976FAB1759C0', N'16000004', N'00000000-CB00-0000-1000-000000000000')
INSERT [dbo].[fly_RoleModule] ([Id], [RoleId], [ModuleId]) VALUES (N'868116D8-AEA0-4C7E-90A7-DAACA3BADF09', N'16000004', N'00000000-BA00-0000-2000-000000000000')
INSERT [dbo].[fly_RoleModule] ([Id], [RoleId], [ModuleId]) VALUES (N'91B7A68C-D0B2-4534-840E-7FA79A558E63', N'16000001', N'00000000-BA00-0000-6000-000000000000')
INSERT [dbo].[fly_RoleModule] ([Id], [RoleId], [ModuleId]) VALUES (N'B09B70C4-2A04-4ECB-9359-099817CEC535', N'16000001', N'00000000-BA00-0000-5000-000000000000')
INSERT [dbo].[fly_RoleModule] ([Id], [RoleId], [ModuleId]) VALUES (N'C60260FC-092D-4B10-AC95-7AE486508D45', N'16000001', N'00000000-BA00-0000-4000-000000000000')
INSERT [dbo].[fly_RoleModule] ([Id], [RoleId], [ModuleId]) VALUES (N'DDE6FB23-C605-4797-902C-DE95237B18EF', N'16000004', N'00000000-BA00-0000-7000-000000000000')
INSERT [dbo].[fly_RoleModule] ([Id], [RoleId], [ModuleId]) VALUES (N'F68FD7BE-C025-43D6-8785-11B6BD135FD0', N'16000004', N'00000000-BA00-0000-1000-000000000000')
INSERT [dbo].[fly_RoleModule] ([Id], [RoleId], [ModuleId]) VALUES (N'FB7B6E3A-E141-4BF4-B08F-4FDBD6ED5CC6', N'16000004', N'00000000-BA00-0000-4000-000000000000')
INSERT [dbo].[fly_RoleModule] ([Id], [RoleId], [ModuleId]) VALUES (N'FC22F2A1-3C38-459D-8897-EE8283FD0ACC', N'16000016', N'00000000-CB00-0000-1000-000000000000')
INSERT [dbo].[fly_RolePlugin] ([Id], [RoleId], [PluginId]) VALUES (N'02BAEAC8-4677-4A35-8DA1-4F5E026F0C37', N'16000001', N'00000000-BA00-0000-0000-000000000000')
INSERT [dbo].[fly_RolePlugin] ([Id], [RoleId], [PluginId]) VALUES (N'6D612CA5-A741-49F0-92B4-E8F214E95328', N'16000004', N'00000000-CB00-0000-0000-000000000000')
INSERT [dbo].[fly_RolePlugin] ([Id], [RoleId], [PluginId]) VALUES (N'7C9570C3-A262-4816-A219-170BEFD0B3AC', N'16000001', N'00000000-CB00-0000-0000-000000000000')
INSERT [dbo].[fly_RolePlugin] ([Id], [RoleId], [PluginId]) VALUES (N'7FCC091B-AFD6-4FC5-991B-CF9FAFF5ED89', N'16000016', N'00000000-CB00-0000-0000-000000000000')
INSERT [dbo].[fly_RolePlugin] ([Id], [RoleId], [PluginId]) VALUES (N'B723E422-5116-4CAA-B8D9-5851AC08A76F', N'16000004', N'00000000-BA00-0000-0000-000000000000')
INSERT [dbo].[fly_User] ([Id], [OrgId], [DepartmentId], [Email], [LoginName], [NickName], [Sex], [Password], [MobilePhone], [EmailVerified], [RegisterTime], [Status], [IsManager], [Type]) VALUES (N'2000000001', N'80000001', N'40000001', N'', N'admin', N'超级管理员', N'男', N'233C01F98CFF8E3E', N'130000000000', 1, CAST(0x0000A12500000000 AS DateTime), 1, 1, NULL)
INSERT [dbo].[fly_User] ([Id], [OrgId], [DepartmentId], [Email], [LoginName], [NickName], [Sex], [Password], [MobilePhone], [EmailVerified], [RegisterTime], [Status], [IsManager], [Type]) VALUES (N'2000000002', N'80000001', N'40000001', N'', N'test', N'测试用户', N'女', N'999EE53EFF56114B', N'', 0, NULL, 1, 0, NULL)
INSERT [dbo].[fly_UserRole] ([Id], [UserId], [RoleId]) VALUES (N'8726b469-005f-4248-aa78-d3831dc5cb5b', N'2000000001', N'16000001')
INSERT [dbo].[fly_UserRole] ([Id], [UserId], [RoleId]) VALUES (N'9364e2d7-2dd1-49a6-a724-0dfba0e1b933', N'2000000002', N'16000004')
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fBox_Compression CreateUserId]    Script Date: 2016/6/30 13:02:02 ******/
CREATE NONCLUSTERED INDEX [IX_fBox_Compression CreateUserId] ON [dbo].[fBox_Compression]
(
	[CreateUserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fBox_File MD5]    Script Date: 2016/6/30 13:02:02 ******/
CREATE NONCLUSTERED INDEX [IX_fBox_File MD5] ON [dbo].[fBox_File]
(
	[MD5] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fBox_File StoreId, Size]    Script Date: 2016/6/30 13:02:02 ******/
CREATE NONCLUSTERED INDEX [IX_fBox_File StoreId, Size] ON [dbo].[fBox_File]
(
	[StoreId] ASC,
	[Size] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fBox_FileReceive SendId]    Script Date: 2016/6/30 13:02:02 ******/
CREATE NONCLUSTERED INDEX [IX_fBox_FileReceive SendId] ON [dbo].[fBox_FileReceive]
(
	[SendId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_fBox_FileReceive Time]    Script Date: 2016/6/30 13:02:02 ******/
CREATE NONCLUSTERED INDEX [IX_fBox_FileReceive Time] ON [dbo].[fBox_FileReceive]
(
	[Time] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fBox_FileReceive UserId]    Script Date: 2016/6/30 13:02:02 ******/
CREATE NONCLUSTERED INDEX [IX_fBox_FileReceive UserId] ON [dbo].[fBox_FileReceive]
(
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fBox_FileSend FileId]    Script Date: 2016/6/30 13:02:02 ******/
CREATE NONCLUSTERED INDEX [IX_fBox_FileSend FileId] ON [dbo].[fBox_FileSend]
(
	[FileId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fBox_FileSend TargetType,Target]    Script Date: 2016/6/30 13:02:02 ******/
CREATE NONCLUSTERED INDEX [IX_fBox_FileSend TargetType,Target] ON [dbo].[fBox_FileSend]
(
	[TargetType] ASC,
	[Target] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_fBox_FileSend Time]    Script Date: 2016/6/30 13:02:02 ******/
CREATE NONCLUSTERED INDEX [IX_fBox_FileSend Time] ON [dbo].[fBox_FileSend]
(
	[Time] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fBox_FileSend UserId]    Script Date: 2016/6/30 13:02:02 ******/
CREATE NONCLUSTERED INDEX [IX_fBox_FileSend UserId] ON [dbo].[fBox_FileSend]
(
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fBox_Share ShareUserId]    Script Date: 2016/6/30 13:02:02 ******/
CREATE NONCLUSTERED INDEX [IX_fBox_Share ShareUserId] ON [dbo].[fBox_Share]
(
	[ShareUserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_fBox_Share Status]    Script Date: 2016/6/30 13:02:02 ******/
CREATE NONCLUSTERED INDEX [IX_fBox_Share Status] ON [dbo].[fBox_Share]
(
	[Status] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [PK_fBox_ShareFile]    Script Date: 2016/6/30 13:02:02 ******/
ALTER TABLE [dbo].[fBox_ShareFile] ADD  CONSTRAINT [PK_fBox_ShareFile] PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fBox_ShareFile SpaceFileId]    Script Date: 2016/6/30 13:02:02 ******/
CREATE NONCLUSTERED INDEX [IX_fBox_ShareFile SpaceFileId] ON [dbo].[fBox_ShareFile]
(
	[SpaceFileId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [PK_fBox_ShareTarget]    Script Date: 2016/6/30 13:02:02 ******/
ALTER TABLE [dbo].[fBox_ShareTarget] ADD  CONSTRAINT [PK_fBox_ShareTarget] PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fBox_Shortcuts InfoType,InfoId]    Script Date: 2016/6/30 13:02:02 ******/
CREATE NONCLUSTERED INDEX [IX_fBox_Shortcuts InfoType,InfoId] ON [dbo].[fBox_Shortcuts]
(
	[InfoType] ASC,
	[InfoId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fBox_Shortcuts Location, Owner]    Script Date: 2016/6/30 13:02:02 ******/
CREATE NONCLUSTERED INDEX [IX_fBox_Shortcuts Location, Owner] ON [dbo].[fBox_Shortcuts]
(
	[Location] ASC,
	[Owner] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fBox_SpaceFile Id, Type]    Script Date: 2016/6/30 13:02:02 ******/
CREATE NONCLUSTERED INDEX [IX_fBox_SpaceFile Id, Type] ON [dbo].[fBox_SpaceFile]
(
	[Id] ASC,
	[Type] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fBox_SpaceFile Name]    Script Date: 2016/6/30 13:02:02 ******/
CREATE NONCLUSTERED INDEX [IX_fBox_SpaceFile Name] ON [dbo].[fBox_SpaceFile]
(
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fBox_SpaceFile Path]    Script Date: 2016/6/30 13:02:02 ******/
CREATE NONCLUSTERED INDEX [IX_fBox_SpaceFile Path] ON [dbo].[fBox_SpaceFile]
(
	[Path] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fBox_SpaceFile SpaceID,ParentId,Type]    Script Date: 2016/6/30 13:02:02 ******/
CREATE NONCLUSTERED INDEX [IX_fBox_SpaceFile SpaceID,ParentId,Type] ON [dbo].[fBox_SpaceFile]
(
	[SpaceID] ASC,
	[ParentId] ASC,
	[Time] ASC,
	[Type] ASC,
	[State] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_fBox_SpaceFile State]    Script Date: 2016/6/30 13:02:02 ******/
CREATE NONCLUSTERED INDEX [IX_fBox_SpaceFile State] ON [dbo].[fBox_SpaceFile]
(
	[State] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [一个学期每个学生只能属于一个班级]    Script Date: 2016/6/30 13:02:02 ******/
ALTER TABLE [dbo].[fEdu_ClassStudent] ADD  CONSTRAINT [一个学期每个学生只能属于一个班级] UNIQUE NONCLUSTERED 
(
	[TermId] ASC,
	[StudentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fEdu_Exam TermId, CreateTime]    Script Date: 2016/6/30 13:02:02 ******/
CREATE NONCLUSTERED INDEX [IX_fEdu_Exam TermId, CreateTime] ON [dbo].[fEdu_Exam]
(
	[TermId] ASC,
	[CreateTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fEdu_SubjectRateItem]    Script Date: 2016/6/30 13:02:02 ******/
CREATE NONCLUSTERED INDEX [IX_fEdu_SubjectRateItem] ON [dbo].[fEdu_SubjectRateItem]
(
	[RateId] ASC,
	[StartScore] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fEdu_Term Name|学期名称不能重复]    Script Date: 2016/6/30 13:02:02 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_fEdu_Term Name|学期名称不能重复] ON [dbo].[fEdu_Term]
(
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_fEdu_Term StartDate|开学时间出现重复]    Script Date: 2016/6/30 13:02:02 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_fEdu_Term StartDate|开学时间出现重复] ON [dbo].[fEdu_Term]
(
	[StartDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [PK_fly_Follows]    Script Date: 2016/6/30 13:02:02 ******/
ALTER TABLE [dbo].[fly_Follows] ADD  CONSTRAINT [PK_fly_Follows] PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fly_im_GroupMember GroupId, UserId]    Script Date: 2016/6/30 13:02:02 ******/
CREATE NONCLUSTERED INDEX [IX_fly_im_GroupMember GroupId, UserId] ON [dbo].[fly_im_GroupMember]
(
	[GroupId] ASC,
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [PK_fly_im_Message]    Script Date: 2016/6/30 13:02:02 ******/
ALTER TABLE [dbo].[fly_im_Message] ADD  CONSTRAINT [PK_fly_im_Message] PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fly_im_Session TargetType GroupId]    Script Date: 2016/6/30 13:02:02 ******/
CREATE NONCLUSTERED INDEX [IX_fly_im_Session TargetType GroupId] ON [dbo].[fly_im_Session]
(
	[TargetType] ASC,
	[GroupId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fly_im_Session TargetType Member1]    Script Date: 2016/6/30 13:02:03 ******/
CREATE NONCLUSTERED INDEX [IX_fly_im_Session TargetType Member1] ON [dbo].[fly_im_Session]
(
	[TargetType] ASC,
	[Member1] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fly_im_Session TargetType Member2]    Script Date: 2016/6/30 13:02:03 ******/
CREATE NONCLUSTERED INDEX [IX_fly_im_Session TargetType Member2] ON [dbo].[fly_im_Session]
(
	[TargetType] ASC,
	[Member2] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_fly_im_UserInfos OnlineState]    Script Date: 2016/6/30 13:02:03 ******/
CREATE NONCLUSTERED INDEX [IX_fly_im_UserInfos OnlineState] ON [dbo].[fly_im_UserInfos]
(
	[OnlineState] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fly_im_MessageRead]    Script Date: 2016/6/30 13:02:03 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_fly_im_MessageRead] ON [dbo].[fly_im_UserSessionInfo]
(
	[UserId] ASC,
	[SessionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [PK_fly_KeyValue]    Script Date: 2016/6/30 13:02:03 ******/
ALTER TABLE [dbo].[fly_KeyValue] ADD  CONSTRAINT [PK_fly_KeyValue] PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [PK_fBox_VisitLog]    Script Date: 2016/6/30 13:02:03 ******/
ALTER TABLE [dbo].[fly_Log] ADD  CONSTRAINT [PK_fBox_VisitLog] PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [fly_Log_Index_UserId_InfoType_InfoId_Action_NumValue_IsValid]    Script Date: 2016/6/30 13:02:03 ******/
CREATE NONCLUSTERED INDEX [fly_Log_Index_UserId_InfoType_InfoId_Action_NumValue_IsValid] ON [dbo].[fly_Log]
(
	[UserId] ASC,
	[InfoType] ASC,
	[InfoId] ASC,
	[Action] ASC,
	[NumValue] ASC,
	[IsValid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [PK_fly_MessageTarget]    Script Date: 2016/6/30 13:02:03 ******/
ALTER TABLE [dbo].[fly_MessageTarget] ADD  CONSTRAINT [PK_fly_MessageTarget] PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fly_Org ParentId,Name]    Script Date: 2016/6/30 13:02:03 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_fly_Org ParentId,Name] ON [dbo].[fly_Org]
(
	[ParentId] ASC,
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_fly_Org RegistTime]    Script Date: 2016/6/30 13:02:03 ******/
CREATE NONCLUSTERED INDEX [IX_fly_Org RegistTime] ON [dbo].[fly_Org]
(
	[RegistTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [PK_fly_RoleFunction]    Script Date: 2016/6/30 13:02:03 ******/
ALTER TABLE [dbo].[fly_RoleFunction] ADD  CONSTRAINT [PK_fly_RoleFunction] PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [PK_fly_RoleModule]    Script Date: 2016/6/30 13:02:03 ******/
ALTER TABLE [dbo].[fly_RoleModule] ADD  CONSTRAINT [PK_fly_RoleModule] PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fly_User]    Script Date: 2016/6/30 13:02:03 ******/
CREATE NONCLUSTERED INDEX [IX_fly_User] ON [dbo].[fly_User]
(
	[MobilePhone] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fly_User Email]    Script Date: 2016/6/30 13:02:03 ******/
CREATE NONCLUSTERED INDEX [IX_fly_User Email] ON [dbo].[fly_User]
(
	[Email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fly_User LoginName]    Script Date: 2016/6/30 13:02:03 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_fly_User LoginName] ON [dbo].[fly_User]
(
	[LoginName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_fly_User NickName]    Script Date: 2016/6/30 13:02:03 ******/
CREATE NONCLUSTERED INDEX [IX_fly_User NickName] ON [dbo].[fly_User]
(
	[NickName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [PK_fly_UserRole]    Script Date: 2016/6/30 13:02:03 ******/
ALTER TABLE [dbo].[fly_UserRole] ADD  CONSTRAINT [PK_fly_UserRole] PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[fBox_Comment] ADD  CONSTRAINT [DF_fBox_Comment_InfoType]  DEFAULT ('') FOR [InfoType]
GO
ALTER TABLE [dbo].[fBox_Comment] ADD  CONSTRAINT [DF_fBox_Comment_IP]  DEFAULT ('') FOR [IP]
GO
ALTER TABLE [dbo].[fBox_DepartmentFolder] ADD  CONSTRAINT [DF_fBox_DepartmentFolder_MaxSize]  DEFAULT ((0)) FOR [MaxSize]
GO
ALTER TABLE [dbo].[fBox_File] ADD  CONSTRAINT [DF_fbox_File_Size]  DEFAULT ((0)) FOR [Size]
GO
ALTER TABLE [dbo].[fBox_File] ADD  CONSTRAINT [DF_fBox_File_ExtensionValue]  DEFAULT ((0)) FOR [ExtensionValue]
GO
ALTER TABLE [dbo].[fBox_OrgSpaceSize] ADD  CONSTRAINT [DF_fBox_OrgSpaceSize_SpaceSize]  DEFAULT ((0)) FOR [SpaceSize]
GO
ALTER TABLE [dbo].[fBox_OrgSpaceSize] ADD  CONSTRAINT [DF_fBox_OrgSpaceSize_Used]  DEFAULT ((0)) FOR [Used]
GO
ALTER TABLE [dbo].[fBox_Share] ADD  CONSTRAINT [DF_fBox_Share_Power]  DEFAULT ((0)) FOR [Power]
GO
ALTER TABLE [dbo].[fBox_Share] ADD  CONSTRAINT [DF_fBox_Share_Size]  DEFAULT ((0)) FOR [Size]
GO
ALTER TABLE [dbo].[fBox_Share] ADD  CONSTRAINT [DF_fBox_Share_Type]  DEFAULT ((0)) FOR [Status]
GO
ALTER TABLE [dbo].[fBox_SMS] ADD  CONSTRAINT [DF_fBox_SMS_NumbersDesc]  DEFAULT ('') FOR [NumbersDesc]
GO
ALTER TABLE [dbo].[fBox_SMS] ADD  CONSTRAINT [DF_fBox_SMS_CreateTime]  DEFAULT (getdate()) FOR [CreateTime]
GO
ALTER TABLE [dbo].[fBox_Space] ADD  CONSTRAINT [DF_fBox_Space_Initialized]  DEFAULT ((0)) FOR [Initialized]
GO
ALTER TABLE [dbo].[fBox_SpaceFile] ADD  CONSTRAINT [DF_FileEntity_Size]  DEFAULT ((0)) FOR [Size]
GO
ALTER TABLE [dbo].[fBox_SpaceFile] ADD  CONSTRAINT [DF_fBox_UserFile_Star]  DEFAULT ((0)) FOR [Star]
GO
ALTER TABLE [dbo].[fBox_SpaceFile] ADD  CONSTRAINT [DF_fBox_UserFile_ShareCount]  DEFAULT ((0)) FOR [ShareCount]
GO
ALTER TABLE [dbo].[fBox_SpaceFile] ADD  CONSTRAINT [DF_fBox_UserFile_Type]  DEFAULT ((0)) FOR [Type]
GO
ALTER TABLE [dbo].[fBox_SpaceFile] ADD  CONSTRAINT [DF_fBox_SpaceFile_State]  DEFAULT ((1)) FOR [State]
GO
ALTER TABLE [dbo].[fBox_SpaceFile] ADD  CONSTRAINT [DF_fBox_SpaceFile_Version]  DEFAULT (getdate()) FOR [Version]
GO
ALTER TABLE [dbo].[fBox_SpaceFile] ADD  CONSTRAINT [DF_fBox_SpaceFile_ContentVersion]  DEFAULT (getdate()) FOR [ContentVersion]
GO
ALTER TABLE [dbo].[fBox_SpaceFile] ADD  CONSTRAINT [DF_fBox_SpaceFile_Path]  DEFAULT ('') FOR [Path]
GO
ALTER TABLE [dbo].[fBox_Store] ADD  CONSTRAINT [DF_Table_1_FIsDisable]  DEFAULT ((0)) FOR [IsDisabled]
GO
ALTER TABLE [dbo].[fBox_Tag] ADD  CONSTRAINT [DF_fBox_Tag_TypeName]  DEFAULT ('') FOR [TypeName]
GO
ALTER TABLE [dbo].[fBox_Work] ADD  CONSTRAINT [DF_fBox_Work_State]  DEFAULT ((1)) FOR [State]
GO
ALTER TABLE [dbo].[fBox_WorkTarget] ADD  CONSTRAINT [DF_fBox_WorkTarget_State]  DEFAULT ((1)) FOR [State]
GO
ALTER TABLE [dbo].[fEdu_Class] ADD  CONSTRAINT [DF_fEdu_Class_HeadTeacherId]  DEFAULT ('') FOR [HeadTeacherId]
GO
ALTER TABLE [dbo].[fEdu_ClassStudent] ADD  CONSTRAINT [DF_fEdu_ClassStudent_IgnoreResult]  DEFAULT ((0)) FOR [IgnoreResult]
GO
ALTER TABLE [dbo].[fEdu_Grade] ADD  CONSTRAINT [DF_fEdu_Grade_Type]  DEFAULT (N'初中') FOR [Type]
GO
ALTER TABLE [dbo].[fEdu_Student] ADD  CONSTRAINT [DF_fEdu_Student_EntryTime]  DEFAULT (getdate()) FOR [EntryTime]
GO
ALTER TABLE [dbo].[fEdu_SubjectRateItem] ADD  CONSTRAINT [DF_fEdu_SubjectRateItem_Sort]  DEFAULT ((0)) FOR [Sort]
GO
ALTER TABLE [dbo].[fEdu_Term] ADD  CONSTRAINT [DF_fEdu_Term_Inited]  DEFAULT ((0)) FOR [Inited]
GO
ALTER TABLE [dbo].[fly_Department] ADD  CONSTRAINT [DF_fly_Department_IsShow]  DEFAULT ((1)) FOR [IsShow]
GO
ALTER TABLE [dbo].[fly_im_Group] ADD  CONSTRAINT [DF_fly_im_Group_Status]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[fly_im_Session] ADD  CONSTRAINT [DF_fly_im_Session_LastMsgTime]  DEFAULT (((1900)-(1))-(1)) FOR [LastMsgTime]
GO
ALTER TABLE [dbo].[fly_im_UserSessionInfo] ADD  CONSTRAINT [DF_fly_im_MessageRead_LastReadTime]  DEFAULT (((1900)-(1))-(1)) FOR [LastReadTime]
GO
ALTER TABLE [dbo].[fly_im_UserSessionInfo] ADD  CONSTRAINT [DF_fly_im_MessageRead_LastNotifyTime]  DEFAULT (((1900)-(1))-(1)) FOR [LastNotifyTime]
GO
ALTER TABLE [dbo].[fly_Log] ADD  CONSTRAINT [DF_fly_Log_InfoType]  DEFAULT ('') FOR [InfoType]
GO
ALTER TABLE [dbo].[fly_Log] ADD  CONSTRAINT [DF_fly_Log_IsValid]  DEFAULT ((1)) FOR [IsValid]
GO
ALTER TABLE [dbo].[fly_Module] ADD  CONSTRAINT [DF_fly_Module_Type]  DEFAULT ((3)) FOR [Type]
GO
ALTER TABLE [dbo].[fly_Org] ADD  CONSTRAINT [DF_fly_Org_RegistTime]  DEFAULT (getdate()) FOR [RegistTime]
GO
ALTER TABLE [dbo].[fly_Org] ADD  CONSTRAINT [DF_fly_Org_Status]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[fly_User] ADD  CONSTRAINT [DF_fly_User_IsManager]  DEFAULT ((0)) FOR [IsManager]
GO
ALTER TABLE [dbo].[fBox_CompressionItems]  WITH CHECK ADD  CONSTRAINT [FK_fBox_CompressionItems_fBox_Compression] FOREIGN KEY([CompId])
REFERENCES [dbo].[fBox_Compression] ([Id])
GO
ALTER TABLE [dbo].[fBox_CompressionItems] CHECK CONSTRAINT [FK_fBox_CompressionItems_fBox_Compression]
GO
ALTER TABLE [dbo].[fBox_DepartmentFolder]  WITH CHECK ADD  CONSTRAINT [FK_fBox_DepartmentFolder_fBox_SpaceFile] FOREIGN KEY([FolderId])
REFERENCES [dbo].[fBox_SpaceFile] ([Id])
GO
ALTER TABLE [dbo].[fBox_DepartmentFolder] CHECK CONSTRAINT [FK_fBox_DepartmentFolder_fBox_SpaceFile]
GO
ALTER TABLE [dbo].[fBox_DepartmentSpace]  WITH CHECK ADD  CONSTRAINT [FK_fBox_DepartmentSpace_fBox_Space] FOREIGN KEY([SpaceId])
REFERENCES [dbo].[fBox_Space] ([Id])
GO
ALTER TABLE [dbo].[fBox_DepartmentSpace] CHECK CONSTRAINT [FK_fBox_DepartmentSpace_fBox_Space]
GO
ALTER TABLE [dbo].[fBox_File]  WITH CHECK ADD  CONSTRAINT [FK_fBox_File_fBox_Store] FOREIGN KEY([StoreId])
REFERENCES [dbo].[fBox_Store] ([Id])
GO
ALTER TABLE [dbo].[fBox_File] CHECK CONSTRAINT [FK_fBox_File_fBox_Store]
GO
ALTER TABLE [dbo].[fBox_FileReceive]  WITH CHECK ADD  CONSTRAINT [FK_fBox_FileReceive_fBox_FileSend] FOREIGN KEY([SendId])
REFERENCES [dbo].[fBox_FileSend] ([Id])
GO
ALTER TABLE [dbo].[fBox_FileReceive] CHECK CONSTRAINT [FK_fBox_FileReceive_fBox_FileSend]
GO
ALTER TABLE [dbo].[fBox_OrgSpace]  WITH CHECK ADD  CONSTRAINT [FK_fBox_OrgSpace_fBox_Space] FOREIGN KEY([SpaceId])
REFERENCES [dbo].[fBox_Space] ([Id])
GO
ALTER TABLE [dbo].[fBox_OrgSpace] CHECK CONSTRAINT [FK_fBox_OrgSpace_fBox_Space]
GO
ALTER TABLE [dbo].[fBox_ShareFile]  WITH CHECK ADD  CONSTRAINT [FK_fBox_ShareFile_fBox_Share] FOREIGN KEY([FetchCode])
REFERENCES [dbo].[fBox_Share] ([FetchCode])
GO
ALTER TABLE [dbo].[fBox_ShareFile] CHECK CONSTRAINT [FK_fBox_ShareFile_fBox_Share]
GO
ALTER TABLE [dbo].[fBox_ShareFile]  WITH CHECK ADD  CONSTRAINT [FK_fBox_ShareFile_fBox_SpaceFile] FOREIGN KEY([SpaceFileId])
REFERENCES [dbo].[fBox_SpaceFile] ([Id])
GO
ALTER TABLE [dbo].[fBox_ShareFile] CHECK CONSTRAINT [FK_fBox_ShareFile_fBox_SpaceFile]
GO
ALTER TABLE [dbo].[fBox_ShareTarget]  WITH CHECK ADD  CONSTRAINT [FK_fBox_ShareTarget_fBox_Share] FOREIGN KEY([FetchCode])
REFERENCES [dbo].[fBox_Share] ([FetchCode])
GO
ALTER TABLE [dbo].[fBox_ShareTarget] CHECK CONSTRAINT [FK_fBox_ShareTarget_fBox_Share]
GO
ALTER TABLE [dbo].[fBox_SpaceFile]  WITH CHECK ADD  CONSTRAINT [FK_fBox_SpaceFile_fBox_File] FOREIGN KEY([FileId])
REFERENCES [dbo].[fBox_File] ([Id])
GO
ALTER TABLE [dbo].[fBox_SpaceFile] CHECK CONSTRAINT [FK_fBox_SpaceFile_fBox_File]
GO
ALTER TABLE [dbo].[fBox_SpaceFile]  WITH CHECK ADD  CONSTRAINT [FK_fBox_SpaceFile_fBox_Space] FOREIGN KEY([SpaceID])
REFERENCES [dbo].[fBox_Space] ([Id])
GO
ALTER TABLE [dbo].[fBox_SpaceFile] CHECK CONSTRAINT [FK_fBox_SpaceFile_fBox_Space]
GO
ALTER TABLE [dbo].[fBox_SpaceFile]  WITH CHECK ADD  CONSTRAINT [FK_fBox_SpaceFile_fBox_SpaceFile] FOREIGN KEY([ParentId])
REFERENCES [dbo].[fBox_SpaceFile] ([Id])
GO
ALTER TABLE [dbo].[fBox_SpaceFile] CHECK CONSTRAINT [FK_fBox_SpaceFile_fBox_SpaceFile]
GO
ALTER TABLE [dbo].[fBox_SpaceFileEx]  WITH CHECK ADD  CONSTRAINT [FK_fBox_SpaceFileEx_fBox_SpaceFile] FOREIGN KEY([SpaceFileId])
REFERENCES [dbo].[fBox_SpaceFile] ([Id])
GO
ALTER TABLE [dbo].[fBox_SpaceFileEx] CHECK CONSTRAINT [FK_fBox_SpaceFileEx_fBox_SpaceFile]
GO
ALTER TABLE [dbo].[fBox_SpaceFileRoleAuth]  WITH CHECK ADD  CONSTRAINT [FK_fBox_SpaceFileRoleAuth_fBox_SpaceFile] FOREIGN KEY([SpaceFileId])
REFERENCES [dbo].[fBox_SpaceFile] ([Id])
GO
ALTER TABLE [dbo].[fBox_SpaceFileRoleAuth] CHECK CONSTRAINT [FK_fBox_SpaceFileRoleAuth_fBox_SpaceFile]
GO
ALTER TABLE [dbo].[fBox_SpaceFileUserAuth]  WITH CHECK ADD  CONSTRAINT [FK_fBox_SpaceFileUserAuth_fBox_SpaceFile] FOREIGN KEY([SpaceFileId])
REFERENCES [dbo].[fBox_SpaceFile] ([Id])
GO
ALTER TABLE [dbo].[fBox_SpaceFileUserAuth] CHECK CONSTRAINT [FK_fBox_SpaceFileUserAuth_fBox_SpaceFile]
GO
ALTER TABLE [dbo].[fBox_UserSpace]  WITH CHECK ADD  CONSTRAINT [FK_fBox_UserSpace_fBox_Space] FOREIGN KEY([SpaceId])
REFERENCES [dbo].[fBox_Space] ([Id])
GO
ALTER TABLE [dbo].[fBox_UserSpace] CHECK CONSTRAINT [FK_fBox_UserSpace_fBox_Space]
GO
ALTER TABLE [dbo].[fBox_WorkAttachment]  WITH CHECK ADD  CONSTRAINT [FK_fBox_WorkAttachment_fBox_SpaceFile] FOREIGN KEY([FileId])
REFERENCES [dbo].[fBox_SpaceFile] ([Id])
GO
ALTER TABLE [dbo].[fBox_WorkAttachment] CHECK CONSTRAINT [FK_fBox_WorkAttachment_fBox_SpaceFile]
GO
ALTER TABLE [dbo].[fBox_WorkAttachment]  WITH CHECK ADD  CONSTRAINT [FK_fBox_WorkAttachment_fBox_Work] FOREIGN KEY([WorkId])
REFERENCES [dbo].[fBox_Work] ([Id])
GO
ALTER TABLE [dbo].[fBox_WorkAttachment] CHECK CONSTRAINT [FK_fBox_WorkAttachment_fBox_Work]
GO
ALTER TABLE [dbo].[fBox_WorkTarget]  WITH CHECK ADD  CONSTRAINT [FK_fBox_WorkTarget_fBox_Work] FOREIGN KEY([WorkId])
REFERENCES [dbo].[fBox_Work] ([Id])
GO
ALTER TABLE [dbo].[fBox_WorkTarget] CHECK CONSTRAINT [FK_fBox_WorkTarget_fBox_Work]
GO
ALTER TABLE [dbo].[fEdu_Class]  WITH CHECK ADD  CONSTRAINT [FK_fEdu_Class_fEdu_Grade] FOREIGN KEY([GradeId])
REFERENCES [dbo].[fEdu_Grade] ([Id])
GO
ALTER TABLE [dbo].[fEdu_Class] CHECK CONSTRAINT [FK_fEdu_Class_fEdu_Grade]
GO
ALTER TABLE [dbo].[fEdu_ClassStudent]  WITH CHECK ADD  CONSTRAINT [FK_fEdu_ClassStudent_fEdu_Class] FOREIGN KEY([ClassId])
REFERENCES [dbo].[fEdu_Class] ([Id])
GO
ALTER TABLE [dbo].[fEdu_ClassStudent] CHECK CONSTRAINT [FK_fEdu_ClassStudent_fEdu_Class]
GO
ALTER TABLE [dbo].[fEdu_ClassStudent]  WITH CHECK ADD  CONSTRAINT [FK_fEdu_ClassStudent_fEdu_Student] FOREIGN KEY([StudentId])
REFERENCES [dbo].[fEdu_Student] ([Id])
GO
ALTER TABLE [dbo].[fEdu_ClassStudent] CHECK CONSTRAINT [FK_fEdu_ClassStudent_fEdu_Student]
GO
ALTER TABLE [dbo].[fEdu_ClassStudent]  WITH CHECK ADD  CONSTRAINT [FK_fEdu_ClassStudent_fEdu_Term] FOREIGN KEY([TermId])
REFERENCES [dbo].[fEdu_Term] ([Id])
GO
ALTER TABLE [dbo].[fEdu_ClassStudent] CHECK CONSTRAINT [FK_fEdu_ClassStudent_fEdu_Term]
GO
ALTER TABLE [dbo].[fEdu_Exam]  WITH CHECK ADD  CONSTRAINT [FK_fEdu_Exam_fly_Org] FOREIGN KEY([OrgId])
REFERENCES [dbo].[fly_Org] ([Id])
GO
ALTER TABLE [dbo].[fEdu_Exam] CHECK CONSTRAINT [FK_fEdu_Exam_fly_Org]
GO
ALTER TABLE [dbo].[fEdu_Exam]  WITH CHECK ADD  CONSTRAINT [FK_fEdu_Exam_fly_User] FOREIGN KEY([CreateUserId])
REFERENCES [dbo].[fly_User] ([Id])
GO
ALTER TABLE [dbo].[fEdu_Exam] CHECK CONSTRAINT [FK_fEdu_Exam_fly_User]
GO
ALTER TABLE [dbo].[fEdu_ExamGrade]  WITH CHECK ADD  CONSTRAINT [FK_fEdu_ExamGrade_fEdu_Exam] FOREIGN KEY([ExamId])
REFERENCES [dbo].[fEdu_Exam] ([Id])
GO
ALTER TABLE [dbo].[fEdu_ExamGrade] CHECK CONSTRAINT [FK_fEdu_ExamGrade_fEdu_Exam]
GO
ALTER TABLE [dbo].[fEdu_ExamGrade]  WITH CHECK ADD  CONSTRAINT [FK_fEdu_ExamGrade_fEdu_Grade] FOREIGN KEY([GradeId])
REFERENCES [dbo].[fEdu_Grade] ([Id])
GO
ALTER TABLE [dbo].[fEdu_ExamGrade] CHECK CONSTRAINT [FK_fEdu_ExamGrade_fEdu_Grade]
GO
ALTER TABLE [dbo].[fEdu_ExamSubject]  WITH CHECK ADD  CONSTRAINT [FK_fEdu_ExamSubject_fEdu_Exam] FOREIGN KEY([ExamId])
REFERENCES [dbo].[fEdu_Exam] ([Id])
GO
ALTER TABLE [dbo].[fEdu_ExamSubject] CHECK CONSTRAINT [FK_fEdu_ExamSubject_fEdu_Exam]
GO
ALTER TABLE [dbo].[fEdu_ExamSubject]  WITH CHECK ADD  CONSTRAINT [FK_fEdu_ExamSubject_fEdu_Subject] FOREIGN KEY([SubjectId])
REFERENCES [dbo].[fEdu_Subject] ([Id])
GO
ALTER TABLE [dbo].[fEdu_ExamSubject] CHECK CONSTRAINT [FK_fEdu_ExamSubject_fEdu_Subject]
GO
ALTER TABLE [dbo].[fEdu_ExamSubject]  WITH CHECK ADD  CONSTRAINT [FK_fEdu_ExamSubject_fEdu_SubjectRate] FOREIGN KEY([RateId])
REFERENCES [dbo].[fEdu_SubjectRate] ([Id])
GO
ALTER TABLE [dbo].[fEdu_ExamSubject] CHECK CONSTRAINT [FK_fEdu_ExamSubject_fEdu_SubjectRate]
GO
ALTER TABLE [dbo].[fEdu_GradeSubject]  WITH CHECK ADD  CONSTRAINT [FK_fEdu_GradeSubject_fEdu_Grade] FOREIGN KEY([GradeId])
REFERENCES [dbo].[fEdu_Grade] ([Id])
GO
ALTER TABLE [dbo].[fEdu_GradeSubject] CHECK CONSTRAINT [FK_fEdu_GradeSubject_fEdu_Grade]
GO
ALTER TABLE [dbo].[fEdu_GradeSubject]  WITH CHECK ADD  CONSTRAINT [FK_fEdu_GradeSubject_fEdu_Subject] FOREIGN KEY([SubjectId])
REFERENCES [dbo].[fEdu_Subject] ([Id])
GO
ALTER TABLE [dbo].[fEdu_GradeSubject] CHECK CONSTRAINT [FK_fEdu_GradeSubject_fEdu_Subject]
GO
ALTER TABLE [dbo].[fEdu_Parents]  WITH CHECK ADD  CONSTRAINT [FK_fEdu_Parents_fly_Org] FOREIGN KEY([OrgId])
REFERENCES [dbo].[fly_Org] ([Id])
GO
ALTER TABLE [dbo].[fEdu_Parents] CHECK CONSTRAINT [FK_fEdu_Parents_fly_Org]
GO
ALTER TABLE [dbo].[fEdu_Results]  WITH CHECK ADD  CONSTRAINT [FK_fEdu_Results_fEdu_Exam] FOREIGN KEY([ExamId])
REFERENCES [dbo].[fEdu_Exam] ([Id])
GO
ALTER TABLE [dbo].[fEdu_Results] CHECK CONSTRAINT [FK_fEdu_Results_fEdu_Exam]
GO
ALTER TABLE [dbo].[fEdu_Results]  WITH CHECK ADD  CONSTRAINT [FK_fEdu_Results_fEdu_Student] FOREIGN KEY([StudentId])
REFERENCES [dbo].[fEdu_Student] ([Id])
GO
ALTER TABLE [dbo].[fEdu_Results] CHECK CONSTRAINT [FK_fEdu_Results_fEdu_Student]
GO
ALTER TABLE [dbo].[fEdu_Results]  WITH CHECK ADD  CONSTRAINT [FK_fEdu_Results_fEdu_Subject] FOREIGN KEY([SubjectId])
REFERENCES [dbo].[fEdu_Subject] ([Id])
GO
ALTER TABLE [dbo].[fEdu_Results] CHECK CONSTRAINT [FK_fEdu_Results_fEdu_Subject]
GO
ALTER TABLE [dbo].[fEdu_StatisticTemp]  WITH CHECK ADD  CONSTRAINT [FK_fEdu_StatisticTemp_fEdu_SubjectRate] FOREIGN KEY([RateId])
REFERENCES [dbo].[fEdu_SubjectRate] ([Id])
GO
ALTER TABLE [dbo].[fEdu_StatisticTemp] CHECK CONSTRAINT [FK_fEdu_StatisticTemp_fEdu_SubjectRate]
GO
ALTER TABLE [dbo].[fEdu_Student]  WITH CHECK ADD  CONSTRAINT [FK_fEdu_Student_fly_Org] FOREIGN KEY([OrgId])
REFERENCES [dbo].[fly_Org] ([Id])
GO
ALTER TABLE [dbo].[fEdu_Student] CHECK CONSTRAINT [FK_fEdu_Student_fly_Org]
GO
ALTER TABLE [dbo].[fEdu_StudentParents]  WITH CHECK ADD  CONSTRAINT [FK_fEdu_StudentParents_fEdu_Parents] FOREIGN KEY([ParentsId])
REFERENCES [dbo].[fEdu_Parents] ([Id])
GO
ALTER TABLE [dbo].[fEdu_StudentParents] CHECK CONSTRAINT [FK_fEdu_StudentParents_fEdu_Parents]
GO
ALTER TABLE [dbo].[fEdu_StudentParents]  WITH CHECK ADD  CONSTRAINT [FK_fEdu_StudentParents_fEdu_Student] FOREIGN KEY([StudentId])
REFERENCES [dbo].[fEdu_Student] ([Id])
GO
ALTER TABLE [dbo].[fEdu_StudentParents] CHECK CONSTRAINT [FK_fEdu_StudentParents_fEdu_Student]
GO
ALTER TABLE [dbo].[fEdu_SubjectRateItem]  WITH CHECK ADD  CONSTRAINT [FK_fEdu_SubjectRateItem_fEdu_SubjectRate] FOREIGN KEY([RateId])
REFERENCES [dbo].[fEdu_SubjectRate] ([Id])
GO
ALTER TABLE [dbo].[fEdu_SubjectRateItem] CHECK CONSTRAINT [FK_fEdu_SubjectRateItem_fEdu_SubjectRate]
GO
ALTER TABLE [dbo].[fEdu_SubjectTeach]  WITH CHECK ADD  CONSTRAINT [FK_fEdu_SubjectTeach_fEdu_Class] FOREIGN KEY([ClassId])
REFERENCES [dbo].[fEdu_Class] ([Id])
GO
ALTER TABLE [dbo].[fEdu_SubjectTeach] CHECK CONSTRAINT [FK_fEdu_SubjectTeach_fEdu_Class]
GO
ALTER TABLE [dbo].[fEdu_SubjectTeach]  WITH CHECK ADD  CONSTRAINT [FK_fEdu_SubjectTeach_fEdu_Subject] FOREIGN KEY([SubjectId])
REFERENCES [dbo].[fEdu_Subject] ([Id])
GO
ALTER TABLE [dbo].[fEdu_SubjectTeach] CHECK CONSTRAINT [FK_fEdu_SubjectTeach_fEdu_Subject]
GO
ALTER TABLE [dbo].[fEdu_SubjectTeach]  WITH CHECK ADD  CONSTRAINT [FK_fEdu_SubjectTeach_fEdu_Term] FOREIGN KEY([TermId])
REFERENCES [dbo].[fEdu_Term] ([Id])
GO
ALTER TABLE [dbo].[fEdu_SubjectTeach] CHECK CONSTRAINT [FK_fEdu_SubjectTeach_fEdu_Term]
GO
ALTER TABLE [dbo].[fEdu_SubjectTeach]  WITH CHECK ADD  CONSTRAINT [FK_fEdu_SubjectTeach_fly_User] FOREIGN KEY([TeacherId])
REFERENCES [dbo].[fly_User] ([Id])
GO
ALTER TABLE [dbo].[fEdu_SubjectTeach] CHECK CONSTRAINT [FK_fEdu_SubjectTeach_fly_User]
GO
ALTER TABLE [dbo].[fly_Department]  WITH CHECK ADD  CONSTRAINT [FK_fly_Department_fly_Department] FOREIGN KEY([ParentId])
REFERENCES [dbo].[fly_Department] ([Id])
GO
ALTER TABLE [dbo].[fly_Department] CHECK CONSTRAINT [FK_fly_Department_fly_Department]
GO
ALTER TABLE [dbo].[fly_Department]  WITH CHECK ADD  CONSTRAINT [FK_fly_Department_fly_Org] FOREIGN KEY([OrgId])
REFERENCES [dbo].[fly_Org] ([Id])
GO
ALTER TABLE [dbo].[fly_Department] CHECK CONSTRAINT [FK_fly_Department_fly_Org]
GO
ALTER TABLE [dbo].[fly_Function]  WITH CHECK ADD  CONSTRAINT [FK_fly_Function_fly_Module] FOREIGN KEY([ModuleId])
REFERENCES [dbo].[fly_Module] ([Id])
GO
ALTER TABLE [dbo].[fly_Function] CHECK CONSTRAINT [FK_fly_Function_fly_Module]
GO
ALTER TABLE [dbo].[fly_Module]  WITH CHECK ADD  CONSTRAINT [FK_fly_Module_fly_Module] FOREIGN KEY([ParentId])
REFERENCES [dbo].[fly_Module] ([Id])
GO
ALTER TABLE [dbo].[fly_Module] CHECK CONSTRAINT [FK_fly_Module_fly_Module]
GO
ALTER TABLE [dbo].[fly_Module]  WITH CHECK ADD  CONSTRAINT [FK_fly_Module_fly_Plugin] FOREIGN KEY([PluginId])
REFERENCES [dbo].[fly_Plugin] ([Id])
GO
ALTER TABLE [dbo].[fly_Module] CHECK CONSTRAINT [FK_fly_Module_fly_Plugin]
GO
ALTER TABLE [dbo].[fly_Org]  WITH CHECK ADD  CONSTRAINT [FK_fly_Org_fly_Org] FOREIGN KEY([ParentId])
REFERENCES [dbo].[fly_Org] ([Id])
GO
ALTER TABLE [dbo].[fly_Org] CHECK CONSTRAINT [FK_fly_Org_fly_Org]
GO
ALTER TABLE [dbo].[fly_Role]  WITH CHECK ADD  CONSTRAINT [FK_fly_Role_fly_Org] FOREIGN KEY([OrgId])
REFERENCES [dbo].[fly_Org] ([Id])
GO
ALTER TABLE [dbo].[fly_Role] CHECK CONSTRAINT [FK_fly_Role_fly_Org]
GO
ALTER TABLE [dbo].[fly_RoleFunction]  WITH CHECK ADD  CONSTRAINT [FK_fly_RoleFunction_fly_Function] FOREIGN KEY([FunctionId])
REFERENCES [dbo].[fly_Function] ([Id])
GO
ALTER TABLE [dbo].[fly_RoleFunction] CHECK CONSTRAINT [FK_fly_RoleFunction_fly_Function]
GO
ALTER TABLE [dbo].[fly_RoleFunction]  WITH CHECK ADD  CONSTRAINT [FK_fly_RoleFunction_fly_Role] FOREIGN KEY([RoleId])
REFERENCES [dbo].[fly_Role] ([Id])
GO
ALTER TABLE [dbo].[fly_RoleFunction] CHECK CONSTRAINT [FK_fly_RoleFunction_fly_Role]
GO
ALTER TABLE [dbo].[fly_RoleModule]  WITH CHECK ADD  CONSTRAINT [FK_fly_RoleModule_fly_Module] FOREIGN KEY([ModuleId])
REFERENCES [dbo].[fly_Module] ([Id])
GO
ALTER TABLE [dbo].[fly_RoleModule] CHECK CONSTRAINT [FK_fly_RoleModule_fly_Module]
GO
ALTER TABLE [dbo].[fly_RoleModule]  WITH CHECK ADD  CONSTRAINT [FK_fly_RoleModule_fly_Role] FOREIGN KEY([RoleId])
REFERENCES [dbo].[fly_Role] ([Id])
GO
ALTER TABLE [dbo].[fly_RoleModule] CHECK CONSTRAINT [FK_fly_RoleModule_fly_Role]
GO
ALTER TABLE [dbo].[fly_RolePlugin]  WITH CHECK ADD  CONSTRAINT [FK_fly_RolePlugin_fly_Plugin] FOREIGN KEY([PluginId])
REFERENCES [dbo].[fly_Plugin] ([Id])
GO
ALTER TABLE [dbo].[fly_RolePlugin] CHECK CONSTRAINT [FK_fly_RolePlugin_fly_Plugin]
GO
ALTER TABLE [dbo].[fly_RolePlugin]  WITH CHECK ADD  CONSTRAINT [FK_fly_RolePlugin_fly_Role] FOREIGN KEY([RoleId])
REFERENCES [dbo].[fly_Role] ([Id])
GO
ALTER TABLE [dbo].[fly_RolePlugin] CHECK CONSTRAINT [FK_fly_RolePlugin_fly_Role]
GO
ALTER TABLE [dbo].[fly_User]  WITH CHECK ADD  CONSTRAINT [FK_fly_User_fly_Department] FOREIGN KEY([DepartmentId])
REFERENCES [dbo].[fly_Department] ([Id])
GO
ALTER TABLE [dbo].[fly_User] CHECK CONSTRAINT [FK_fly_User_fly_Department]
GO
ALTER TABLE [dbo].[fly_User]  WITH CHECK ADD  CONSTRAINT [FK_fly_User_fly_Org] FOREIGN KEY([OrgId])
REFERENCES [dbo].[fly_Org] ([Id])
GO
ALTER TABLE [dbo].[fly_User] CHECK CONSTRAINT [FK_fly_User_fly_Org]
GO
ALTER TABLE [dbo].[fly_UserRole]  WITH CHECK ADD  CONSTRAINT [FK_fly_UserRole_fly_Role] FOREIGN KEY([RoleId])
REFERENCES [dbo].[fly_Role] ([Id])
GO
ALTER TABLE [dbo].[fly_UserRole] CHECK CONSTRAINT [FK_fly_UserRole_fly_Role]
GO
ALTER TABLE [dbo].[fly_UserRole]  WITH CHECK ADD  CONSTRAINT [FK_fly_UserRole_fly_User] FOREIGN KEY([UserId])
REFERENCES [dbo].[fly_User] ([Id])
GO
ALTER TABLE [dbo].[fly_UserRole] CHECK CONSTRAINT [FK_fly_UserRole_fly_User]
GO
ALTER TABLE [dbo].[fBox_SpaceFile]  WITH NOCHECK ADD  CONSTRAINT [MSG:{超出文件夹大小限制，请检查目标文件夹及上级文件夹}] CHECK NOT FOR REPLICATION (([MaxSize] IS NULL OR [Size]<[MaxSize]))
GO
ALTER TABLE [dbo].[fBox_SpaceFile] CHECK CONSTRAINT [MSG:{超出文件夹大小限制，请检查目标文件夹及上级文件夹}]
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'大小' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fBox_File', @level2type=N'COLUMN',@level2name=N'Size'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'发送的id' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fBox_FileReceive', @level2type=N'COLUMN',@level2name=N'SendId'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'接收的用户id' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fBox_FileReceive', @level2type=N'COLUMN',@level2name=N'UserId'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'接收时间' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fBox_FileReceive', @level2type=N'COLUMN',@level2name=N'Time'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'接收的方式（Down/Open/Save/Share）' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fBox_FileReceive', @level2type=N'COLUMN',@level2name=N'Cmd'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'发送人id' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fBox_FileSend', @level2type=N'COLUMN',@level2name=N'UserId'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'不同单位可以对角色设置不同的空间大写,为空表示默认全局设置' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fBox_RoleSpaceSize', @level2type=N'COLUMN',@level2name=N'OrgId'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'文件名' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fBox_SpaceFile', @level2type=N'COLUMN',@level2name=N'Name'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'所在文件夹ＩＤ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fBox_SpaceFile', @level2type=N'COLUMN',@level2name=N'ParentId'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'大小' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fBox_SpaceFile', @level2type=N'COLUMN',@level2name=N'Size'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'后缀名' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fBox_SpaceFile', @level2type=N'COLUMN',@level2name=N'Extension'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'上传人ID' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fBox_SpaceFile', @level2type=N'COLUMN',@level2name=N'UserId'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'如果设置最大值，则Size不能超过最大值' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fBox_SpaceFile', @level2type=N'CONSTRAINT',@level2name=N'MSG:{超出文件夹大小限制，请检查目标文件夹及上级文件夹}'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'物理路径' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fBox_Store', @level2type=N'COLUMN',@level2name=N'Path'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'最大容量' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fBox_Store', @level2type=N'COLUMN',@level2name=N'Size'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'已用' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fBox_Store', @level2type=N'COLUMN',@level2name=N'Used'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'是否停用' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fBox_Store', @level2type=N'COLUMN',@level2name=N'IsDisabled'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'所属用户，为空则表示公共标签' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fBox_Tag', @level2type=N'COLUMN',@level2name=N'SpaceId'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'建议完成时间' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fBox_Work', @level2type=N'COLUMN',@level2name=N'ProposalCompleteTime'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'年级Id' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Class', @level2type=N'COLUMN',@level2name=N'GradeId'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'绑定部门' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Class', @level2type=N'COLUMN',@level2name=N'DepartmentId'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'班级编号（如201401）' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Class', @level2type=N'COLUMN',@level2name=N'ClassNO'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'班主任' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Class', @level2type=N'COLUMN',@level2name=N'HeadTeacherId'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'考试日期' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Exam', @level2type=N'COLUMN',@level2name=N'Time'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'绑定部门' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Grade', @level2type=N'COLUMN',@level2name=N'DepartmentId'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'级段长' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Grade', @level2type=N'COLUMN',@level2name=N'Admin'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'年级类型（小学、初中、高中、大学）' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Grade', @level2type=N'COLUMN',@level2name=N'Type'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'入学日期' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Grade', @level2type=N'COLUMN',@level2name=N'BeginDate'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'是否已毕业' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Grade', @level2type=N'COLUMN',@level2name=N'IsFinish'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'绑定用户' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Parents', @level2type=N'COLUMN',@level2name=N'UserId'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'姓名' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Parents', @level2type=N'COLUMN',@level2name=N'Name'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'性别' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Parents', @level2type=N'COLUMN',@level2name=N'Sex'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'成绩录入时间' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Results', @level2type=N'COLUMN',@level2name=N'EntryTime'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'成绩录入用户' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Results', @level2type=N'COLUMN',@level2name=N'EntryUserId'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'绑定用户' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Student', @level2type=N'COLUMN',@level2name=N'UserId'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'姓名' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Student', @level2type=N'COLUMN',@level2name=N'Name'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'性别（男、女）' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Student', @level2type=N'COLUMN',@level2name=N'Sex'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'联系电话' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Student', @level2type=N'COLUMN',@level2name=N'Phone'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'生日' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Student', @level2type=N'COLUMN',@level2name=N'Birthday'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'籍贯' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Student', @level2type=N'COLUMN',@level2name=N'Hometown'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'民族' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Student', @level2type=N'COLUMN',@level2name=N'Nation'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'身份证' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Student', @level2type=N'COLUMN',@level2name=N'IdCard'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'健康状态(健康或良好、一般或较弱、有慢性病、有生理缺陷、残疾)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Student', @level2type=N'COLUMN',@level2name=N'StateOfHealth'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'政治面貌(中共党员、中共预备党员、共青团员、群众)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Student', @level2type=N'COLUMN',@level2name=N'PoliticalAffiliation'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'户口性质(农、非农)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Student', @level2type=N'COLUMN',@level2name=N'AccountKind'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'出生地行政区划代码' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Student', @level2type=N'COLUMN',@level2name=N'BornArea'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'户口所在地行政区划' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Student', @level2type=N'COLUMN',@level2name=N'OwnerArea'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'就读方式(走读、住校)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Student', @level2type=N'COLUMN',@level2name=N'StudyingWays'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'现住址' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Student', @level2type=N'COLUMN',@level2name=N'Address'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'通信地址' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Student', @level2type=N'COLUMN',@level2name=N'MailingAddress'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'家庭地址' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Student', @level2type=N'COLUMN',@level2name=N'HomeAddress'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'是否独生子女(是、否)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Student', @level2type=N'COLUMN',@level2name=N'IsOnlyChild'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'是否受过学前教育(是、否)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Student', @level2type=N'COLUMN',@level2name=N'HasPreschool'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'是否留守儿童(非留守儿童、单亲留守儿童、双亲留守儿童)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Student', @level2type=N'COLUMN',@level2name=N'IsLeftBehind'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'是否需要申请资助(是、否)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Student', @level2type=N'COLUMN',@level2name=N'NeedSubsidize'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'上放学方式(步行、非机动车、公共交通、家长自行接送、校车、其他)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Student', @level2type=N'COLUMN',@level2name=N'WayToSchool'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'学籍号' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Student', @level2type=N'COLUMN',@level2name=N'SchoolRoll'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'是否进城务工人员随迁子女(是、否)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Student', @level2type=N'COLUMN',@level2name=N'IsMigrantWorkers'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'录入时间' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Student', @level2type=N'COLUMN',@level2name=N'EntryTime'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'学生' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_StudentParents', @level2type=N'COLUMN',@level2name=N'StudentId'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'家长' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_StudentParents', @level2type=N'COLUMN',@level2name=N'ParentsId'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'称谓' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_StudentParents', @level2type=N'COLUMN',@level2name=N'Title'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'100' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fEdu_Subject', @level2type=N'COLUMN',@level2name=N'DefaultTotalScore'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'如：SYS,PLUGIN_158bf177-c13c-45af-893a-4727aa94ed80' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fly_Config', @level2type=N'COLUMN',@level2name=N'For'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'如：Mail,Account ....' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fly_Config', @level2type=N'COLUMN',@level2name=N'Type'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'如：FileMaxSize,ResetPasswordMailExpirationDays ...' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fly_Config', @level2type=N'COLUMN',@level2name=N'Name'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'插件编号' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fly_Module', @level2type=N'COLUMN',@level2name=N'PluginId'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'插件内唯一键' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fly_Module', @level2type=N'COLUMN',@level2name=N'Key'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'模块名称' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fly_Module', @level2type=N'COLUMN',@level2name=N'Name'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'上级编号' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fly_Module', @level2type=N'COLUMN',@level2name=N'ParentId'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'类型，对应枚举：ModuleTypes' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fly_Module', @level2type=N'COLUMN',@level2name=N'Type'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'联系电话::phone' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fly_Org', @level2type=N'COLUMN',@level2name=N'Phone'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'是否后台管理角色' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fly_Role', @level2type=N'COLUMN',@level2name=N'IsManager'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'是否公共角色' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'fly_Role', @level2type=N'COLUMN',@level2name=N'IsPublic'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[37] 4[23] 2[24] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "u"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 181
               Right = 257
            End
            DisplayFlags = 280
            TopColumn = 7
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'fBox_User'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'fBox_User'
GO
ALTER DATABASE [Fly.Box-DB] SET  READ_WRITE 
GO
