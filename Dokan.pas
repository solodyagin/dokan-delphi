(*
  Dokan API wrapper for Delphi based on Release 2.0.5.1000
  https://github.com/dokan-dev/dokany/releases/tag/v2.0.5.1000
  Copyright (C) 2019 - 2022 Sven Harazim

  Dokan : user-mode file system library for Windows

  Copyright (C) 2015 - 2019 Adrien J. <liryna.stark@gmail.com> and Maxime C. <maxime@islog.com>
  Copyright (C) 2020 - 2022 Google, Inc.
  Copyright (C) 2007 - 2011 Hiroki Asakawa <info@dokan-dev.net>

  http://dokan-dev.github.io

  This program is free software; you can redistribute it and/or modify it under
  the terms of the GNU Lesser General Public License as published by the Free
  Software Foundation; either version 3 of the License, or (at your option) any
  later version.

  This program is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

  You should have received a copy of the GNU Lesser General Public License along
  with this program. If not, see <http://www.gnu.org/licenses/>.
*)

unit Dokan;

{$ifdef FPC}
  {$mode delphi}
{$endif FPC}

{$align 8}
{$minenumsize 4}

interface

uses
  Windows, DokanWin;

const
  DokanLibrary = 'dokan2.dll';

  //The current Dokan version (200 means ver 2.0.0).
  DOKAN_VERSION = 206;
  //Minimum Dokan version (ver 2.0.0) accepted
  DOKAN_MINIMUM_COMPATIBLE_VERSION = 200;

  //Enable ouput debug message
  DOKAN_OPTION_DEBUG = 1;
  //Enable ouput debug message to stderr
  DOKAN_OPTION_STDERR = 2;
  //Enable the use of alternate stream paths in the form
  //<file-name>:<stream-name>. If this is not specified then the driver will
  //fail any attempt to access a path with a colon.
  DOKAN_OPTION_ALT_STREAM = 4;
  //Enable mount drive as write-protected
  DOKAN_OPTION_WRITE_PROTECT = 8;
  //Use network drive - Dokan network provider needs to be installed and a DOKAN_OPTIONS.UNCName provided
  DOKAN_OPTION_NETWORK = 16;
  //Use removable drive
  //Be aware that on some environments, the userland application will be denied
  //to communicate with the drive which will result in a unwanted unmount.
  //see <a href="https://github.com/dokan-dev/dokany/issues/843">Issue #843</a>
  DOKAN_OPTION_REMOVABLE = 32;
  //Use mount manager
  DOKAN_OPTION_MOUNT_MANAGER = 64;
  //Mount the drive on current session only
  DOKAN_OPTION_CURRENT_SESSION = 128;
  //Enable Lockfile/Unlockfile operations. Otherwise Dokan will take care of it
  DOKAN_OPTION_FILELOCK_USER_MODE = 256;
  //Enable Case sensitive path.
  //By default all path are case insensitive.
  //For case sensitive: \dir\File & \diR\file are different files
  //but for case insensitive they are the same.
  DOKAN_OPTION_CASE_SENSITIVE = 512;
  //Allows unmounting of network drive via explorer */
  DOKAN_OPTION_ENABLE_UNMOUNT_NETWORK_DRIVE = 1024;
  //Forward the kernel driver global and volume logs to the userland.
  //Can be very slow if single thread is enabled.
  DOKAN_OPTION_DISPATCH_DRIVER_LOGS = 2048;
  //Pull batches of events from the driver instead of a single one and execute them parallelly.
  //This option should only be used on computers with low cpu count
  //and userland filesystem taking time to process requests (like remote storage).
  DOKAN_OPTION_ALLOW_IPC_BATCHING = 4096;

type
  DOKAN_HANDLE = THandle;

  //Dokan mount options used to describe Dokan device behavior.
  _DOKAN_OPTIONS = record
    Version: USHORT;          //Version of the Dokan features requested without dots (version "123" is equal to Dokan version 1.2.3).
    SingleThread: BOOL;       //Only use a single thread to process events. This is highly not recommended as can easily create a bottleneck.
    Options: ULONG;           //Features enabled for the mount. See \ref DOKAN_OPTION.
    GlobalContext: ULONG64;   //FileSystem can store anything here.
    MountPoint: LPCWSTR;      //Mount point. It can be a driver letter like "M:\" or a folder path "C:\mount\dokan" on a NTFS partition.
    UNCName: LPCWSTR;         //UNC Name for the Network Redirector
    Timeout: ULONG;           //Max timeout in milliseconds of each request before Dokan gives up to wait events to complete. The default timeout value is 15 seconds.
    AllocationUnitSize: ULONG;//Allocation Unit Size of the volume. This will affect the file size.
    SectorSize: ULONG;        //Sector Size of the volume. This will affect the file size.
    VolumeSecurityDescriptorLength : ULONG; //Length of the optional VolumeSecurityDescriptor provided. Set 0 will disable the option.
    VolumeSecurityDescriptor : array [0..VOLUME_SECURITY_DESCRIPTOR_MAX_SIZE-1] of WChar;//Optional Volume Security descriptor. See <a href="https://docs.microsoft.com/en-us/windows/win32/api/securitybaseapi/nf-securitybaseapi-initializesecuritydescriptor">InitializeSecurityDescriptor</a>
  end;
  DOKAN_OPTIONS = _DOKAN_OPTIONS;
  PDOKAN_OPTIONS = ^_DOKAN_OPTIONS;
  TDokanOptions = DOKAN_OPTIONS;
  PDokanOptions = PDOKAN_OPTIONS;

  //Dokan file information on the current operation.
  _DOKAN_FILE_INFO = record
    Context: ULONG64;
    DokanContext: ULONG64;
    DokanOptions: PDOKAN_OPTIONS;
    ProcessingContext : PVOID;
    ProcessId: ULONG;
    IsDirectory: ByteBool;
    DeleteOnClose: ByteBool;
    PagingIo: ByteBool;
    SynchronousIo: ByteBool;
    Nocache: ByteBool;
    WriteToEndOfFile: ByteBool;
  end;
  DOKAN_FILE_INFO = _DOKAN_FILE_INFO;
  PDOKAN_FILE_INFO = ^_DOKAN_FILE_INFO;
  TDokanFileInfo = DOKAN_FILE_INFO;
  PDokanFileInfo = PDOKAN_FILE_INFO;

const
  DOKAN_EXCEPTION_NOT_INITIALIZED = $0f0ff0ff;
  DOKAN_EXCEPTION_INITIALIZATION_FAILED = $0fbadbad;
  DOKAN_EXCEPTION_SHUTDOWN_FAILED = $0fbadf00;

type
  //FillFindData Used to add an entry in FindFiles operation
  //return 1 if buffer is full, otherwise 0 (currently it never returns 1)
  TDokanFillFindData = function (
    var FindData: WIN32_FIND_DATAW;
    var DokanFileInfo: DOKAN_FILE_INFO
  ): Integer; stdcall;

  //FillFindStreamData Used to add an entry in FindStreams
  //return FALSE if the buffer is full, otherwise TRUE
  TDokanFillFindStreamData = function (
    var FindStreamData: WIN32_FIND_STREAM_DATA;
    var FindStreamContext: PVOID
  ): BOOL; stdcall;

  _DOKAN_ACCESS_STATE = record
    SecurityEvaluated: ByteBool;
    GenerateAudit: ByteBool;
    GenerateOnClose: ByteBool;
    AuditPrivileges: ByteBool;
    Flags: ULONG;
    RemainingDesiredAccess: ACCESS_MASK;
    PreviouslyGrantedAccess: ACCESS_MASK;
    OriginalDesiredAccess: ACCESS_MASK;
    SecurityDescriptor: PSECURITY_DESCRIPTOR;
    ObjectName: UNICODE_STRING;
    ObjectType: UNICODE_STRING;
  end;
  DOKAN_ACCESS_STATE = _DOKAN_ACCESS_STATE;
  PDOKAN_ACCESS_STATE = ^_DOKAN_ACCESS_STATE;
  TDokanAccessState = DOKAN_ACCESS_STATE;
  PDokanAccessState = PDOKAN_ACCESS_STATE;

  _DOKAN_IO_SECURITY_CONTEXT = record
    AccessState: DOKAN_ACCESS_STATE;
    DesiredAccess: ACCESS_MASK;
  end;
  DOKAN_IO_SECURITY_CONTEXT = _DOKAN_IO_SECURITY_CONTEXT;
  PDOKAN_IO_SECURITY_CONTEXT = ^_DOKAN_IO_SECURITY_CONTEXT;
  TDokanIOSecurityContext = DOKAN_IO_SECURITY_CONTEXT;
  PDokanIOSecurityContext = PDOKAN_IO_SECURITY_CONTEXT;

  TDokanZwCreateFile = function (
    FileName: LPCWSTR;
    var SecurityContext: DOKAN_IO_SECURITY_CONTEXT;
    DesiredAccess: ACCESS_MASK;
    FileAttributes: ULONG;
    ShareAccess: ULONG;
    CreateDisposition: ULONG;
    CreateOptions: ULONG;
    var DokanFileInfo: DOKAN_FILE_INFO
  ): NTSTATUS; stdcall;

  TDokanCleanup = procedure (
    FileName: LPCWSTR;
    var DokanFileInfo: DOKAN_FILE_INFO
  ); stdcall;

  TDokanCloseFile = procedure (
    FileName: LPCWSTR;
    var DokanFileInfo: DOKAN_FILE_INFO
  ); stdcall;

  TDokanReadFile = function (
    FileName: LPCWSTR;
    var Buffer;
    BufferLength: DWORD;
    var ReadLength: DWORD;
    Offset: LONGLONG;
    var DokanFileInfo: DOKAN_FILE_INFO
  ): NTSTATUS; stdcall;

  TDokanWriteFile = function (
    FileName: LPCWSTR;
    const Buffer;
    NumberOfBytesToWrite: DWORD;
    var NumberOfBytesWritten: DWORD;
    Offset: LONGLONG;
    var DokanFileInfo: DOKAN_FILE_INFO
  ): NTSTATUS; stdcall;

  TDokanFlushFileBuffers = function (
    FileName: LPCWSTR;
    var DokanFileInfo: DOKAN_FILE_INFO
  ): NTSTATUS; stdcall;

  TDokanGetFileInformation = function (
    FileName: LPCWSTR;
    var Buffer: BY_HANDLE_FILE_INFORMATION;
    var DokanFileInfo: DOKAN_FILE_INFO
  ): NTSTATUS; stdcall;

  TDokanFindFiles = function (
    PathName: LPCWSTR;
    FillFindData: TDokanFillFindData;
    var DokanFileInfo: DOKAN_FILE_INFO
  ): NTSTATUS; stdcall;

  TDokanFindFilesWithPattern = function (
    PathName: LPCWSTR;
    SearchPattern: LPCWSTR;
    FillFindData: TDokanFillFindData;
    var DokanFileInfo: DOKAN_FILE_INFO
  ): NTSTATUS; stdcall;

  TDokanSetFileAttributes = function (
    FileName: LPCWSTR;
    FileAttributes: DWORD;
    var DokanFileInfo: DOKAN_FILE_INFO
  ): NTSTATUS; stdcall;

  TDokanSetFileTime = function (
    FileName: LPCWSTR;
    var CreationTime: FILETIME;
    var LastAccessTime: FILETIME;
    var LastWriteTime: FILETIME;
    var DokanFileInfo: DOKAN_FILE_INFO
  ): NTSTATUS; stdcall;

  TDokanDeleteFile = function (
    FileName: LPCWSTR;
    var DokanFileInfo: DOKAN_FILE_INFO
  ): NTSTATUS; stdcall;

  TDokanDeleteDirectory = function (
    FileName: LPCWSTR;
    var DokanFileInfo: DOKAN_FILE_INFO
  ): NTSTATUS; stdcall;

  TDokanMoveFile = function (
    FileName: LPCWSTR;
    NewFileName: LPCWSTR;
    ReplaceIfExisting: BOOL;
    var DokanFileInfo: DOKAN_FILE_INFO
  ): NTSTATUS; stdcall;

  TDokanSetEndOfFile = function (
    FileName: LPCWSTR;
    ByteOffset: LONGLONG;
    var DokanFileInfo: DOKAN_FILE_INFO
  ): NTSTATUS; stdcall;

  TDokanSetAllocationSize = function (
    FileName: LPCWSTR;
    AllocSize: LONGLONG;
    var DokanFileInfo: DOKAN_FILE_INFO
  ): NTSTATUS; stdcall;

  TDokanLockFile = function (
    FileName: LPCWSTR;
    ByteOffset: LONGLONG;
    Length: LONGLONG;
    var DokanFileInfo: DOKAN_FILE_INFO
  ): NTSTATUS; stdcall;

  TDokanUnlockFile = function (
    FileName: LPCWSTR;
    ByteOffset: LONGLONG;
    Length: LONGLONG;
    var DokanFileInfo: DOKAN_FILE_INFO
  ): NTSTATUS; stdcall;

  TDokanGetDiskFreeSpace = function (
    var FreeBytesAvailable: ULONGLONG;
    var TotalNumberOfBytes: ULONGLONG;
    var TotalNumberOfFreeBytes: ULONGLONG;
    var DokanFileInfo: DOKAN_FILE_INFO
  ): NTSTATUS; stdcall;

  TDokanGetVolumeInformation = function (
    VolumeNameBuffer: LPWSTR;
    VolumeNameSize: DWORD;
    var VolumeSerialNumber: DWORD;
    var MaximumComponentLength: DWORD;
    var FileSystemFlags: DWORD;
    FileSystemNameBuffer: LPWSTR;
    FileSystemNameSize: DWORD;
    var DokanFileInfo: DOKAN_FILE_INFO
  ): NTSTATUS; stdcall;

  TDokanMounted = function (
    var MountPoint: LPCWSTR;
    var DokanFileInfo: DOKAN_FILE_INFO
  ): NTSTATUS; stdcall;

  TDokanUnmounted = function (
    var DokanFileInfo: DOKAN_FILE_INFO
  ): NTSTATUS; stdcall;

  TDokanGetFileSecurity = function (
    FileName: LPCWSTR;
    var SecurityInformation: SECURITY_INFORMATION;
    SecurityDescriptor: PSECURITY_DESCRIPTOR;
    BufferLength: ULONG;
    var LengthNeeded: ULONG;
    var DokanFileInfo: DOKAN_FILE_INFO
  ): NTSTATUS; stdcall;

  TDokanSetFileSecurity = function (
    FileName: LPCWSTR;
    var SecurityInformation: SECURITY_INFORMATION;
    SecurityDescriptor: PSECURITY_DESCRIPTOR;
    BufferLength: ULONG;
    var DokanFileInfo: DOKAN_FILE_INFO
  ): NTSTATUS; stdcall;

  TDokanFindStreams = function (
    FileName: LPCWSTR;
    FillFindStreamData: TDokanFillFindStreamData;
    var FindStreamContext : PVOID;
    var DokanFileInfo: DOKAN_FILE_INFO
  ): NTSTATUS; stdcall;

  _DOKAN_OPERATIONS = record
    ZwCreateFile: TDokanZwCreateFile;
    Cleanup: TDokanCleanup;
    CloseFile: TDokanCloseFile;
    ReadFile: TDokanReadFile;
    WriteFile: TDokanWriteFile;
    FlushFileBuffers: TDokanFlushFileBuffers;
    GetFileInformation: TDokanGetFileInformation;
    FindFiles: TDokanFindFiles;
    FindFilesWithPattern: TDokanFindFilesWithPattern;
    SetFileAttributes: TDokanSetFileAttributes;
    SetFileTime: TDokanSetFileTime;
    DeleteFile: TDokanDeleteFile;
    DeleteDirectory: TDokanDeleteDirectory;
    MoveFile: TDokanMoveFile;
    SetEndOfFile: TDokanSetEndOfFile;
    SetAllocationSize: TDokanSetAllocationSize;
    LockFile: TDokanLockFile;
    UnlockFile: TDokanUnlockFile;
    GetDiskFreeSpace: TDokanGetDiskFreeSpace;
    GetVolumeInformation: TDokanGetVolumeInformation;
    Mounted: TDokanMounted;
    Unmounted: TDokanUnmounted;
    GetFileSecurity: TDokanGetFileSecurity;
    SetFileSecurity: TDokanSetFileSecurity;
    FindStreams: TDokanFindStreams;
  end;
  DOKAN_OPERATIONS = _DOKAN_OPERATIONS;
  PDOKAN_OPERATIONS = ^_DOKAN_OPERATIONS;
  TDokanOperations = DOKAN_OPERATIONS;
  PDokanOperations = PDOKAN_OPERATIONS;

  _DOKAN_MOUNT_POINT_INFO = record
    Type_ : ULONG;
    MountPoint: array [0 .. MAX_PATH - 1] of WCHAR;
    UNCName: array [0 .. 63] of WCHAR;
    DeviceName: array [0 .. 63] of WCHAR;
    DeviceObject: Pointer;
    SessionId : ULONG;
    MountOptions : ULONG;
  end;
  DOKAN_MOUNT_POINT_INFO = _DOKAN_MOUNT_POINT_INFO;
  PDOKAN_MOUNT_POINT_INFO = ^DOKAN_MOUNT_POINT_INFO;
  TDokanMountPointInfo = _DOKAN_MOUNT_POINT_INFO;
  PDokanMountPointInfo = PDOKAN_MOUNT_POINT_INFO;

const
  DOKAN_SUCCESS = 0;
  DOKAN_ERROR = -1;
  DOKAN_DRIVE_LETTER_ERROR = -2;
  DOKAN_DRIVER_INSTALL_ERROR = -3;
  DOKAN_START_ERROR = -4;
  DOKAN_MOUNT_ERROR = -5;
  DOKAN_MOUNT_POINT_ERROR = -6;
  DOKAN_VERSION_ERROR = -7;

{$ifdef DOKAN_EXPLICIT_LINK}


DokanDebugMode	0x0000000180004d30	0x00004d30	3 (0x3)	dokan2.dll	C:\Windows\System32\dokan2.dll	Exported Function
DokanNetworkProviderInstall	0x000000018000d2c0	0x0000d2c0	11 (0xb)	dokan2.dll	C:\Windows\System32\dokan2.dll	Exported Function
DokanNetworkProviderUninstall	0x000000018000d540	0x0000d540	12 (0xc)	dokan2.dll	C:\Windows\System32\dokan2.dll	Exported Function
DokanServiceDelete	0x000000018000d170	0x0000d170	23 (0x17)	dokan2.dll	C:\Windows\System32\dokan2.dll	Exported Function
DokanServiceInstall	0x000000018000d030	0x0000d030	24 (0x18)	dokan2.dll	C:\Windows\System32\dokan2.dll	Exported Function
DokanSetDebugMode	0x0000000180008000	0x00008000	25 (0x19)	dokan2.dll	C:\Windows\System32\dokan2.dll	Exported Function
DokanUseStdErr	0x0000000180004d20	0x00004d20	28 (0x1c)	dokan2.dll	C:\Windows\System32\dokan2.dll	Exported Function

var
  DokanLibHandle: HMODULE = 0;
  DokanInit: procedure; stdcall = nil;
  DokanShutdown procedure; stdcall = nil;
  DokanMain: function (var Options: DOKAN_OPTIONS; var Operations: DOKAN_OPERATIONS): Integer; stdcall = nil;
  DokanCreateFileSystem: function (DokanOptions : DOKAN_OPTIONS; DokanOperations : DOKAN_OPERATIONS; var DokanInstance : DOKAN_HANDLE) : Integer; stdcall = nil;
  DokanIsFileSystemRunning: function (DokanInstance : DOKAN_HANDLE) : BOOL; stdcall = nil;
  DokanWaitForFileSystemClosed: function (DokanInstance : DOKAN_HANDLE; dwMilliseconds : DWORD) : DWORD; stdcall = nil;
  DokanCloseHandle: procedure (DokanInstance : DOKAN_HANDLE); stdcall = nil;
  DokanUnmount: function (DriveLetter: WCHAR): BOOL; stdcall = nil;
  DokanRemoveMountPoint: function (MountPoint: LPCWSTR): BOOL; stdcall = nil;
  DokanIsNameInExpression: function (Expression, Name: LPCWSTR; IgnoreCase: BOOL): BOOL; stdcall = nil;
  DokanVersion: function (): ULONG; stdcall = nil;
  DokanDriverVersion: function (): ULONG; stdcall = nil;
  DokanResetTimeout: function (Timeout: ULONG; var DokanFileInfo: DOKAN_FILE_INFO): BOOL; stdcall = nil;
  DokanOpenRequestorToken: function (var DokanFileInfo: DOKAN_FILE_INFO): THandle; stdcall = nil;
  DokanGetMountPointList: function (uncOnly: BOOL; var nbRead: ULONG): PDOKAN_CONTROL; stdcall = nil;
  DokanReleaseMountPointList: procedure (list: PDOKAN_CONTROL); stdcall = nil;
  DokanMapKernelToUserCreateFileFlags: procedure (DesiredAccess: ACCESS_MASK; FileAttributes, CreateOptions,
    CreateDisposition: ULONG;outDesiredAccess: PACCESS_MASK; outFileAttributesAndFlags,
    outCreationDisposition: PDWORD); stdcall = nil;
  DokanNotifyCreate: function (FilePath: LPCWSTR; IsDirectory : BOOL) : BOOL; stdcall = nil;
  DokanNotifyDelete: function (FilePath : LPCWSTR; BOOL IsDirectory) : BOOL; stdcall = nil;
  DokanNotifyUpdate: function (FilePath : LPCWSTR) : BOOL; stdcall = nil;
  DokanNotifyXAttrUpdate: function (FilePath : LPCWSTR) : BOOL; stdcall = nil;
  DokanNotifyRename: function (OldPath: LPCWSTR; NewPath : LPCWSTR; IsDirectory : BOOL;
    IsInSameDirectory: BOOL) : BOOL; stdcall = nil;
  DokanNtStatusFromWin32: function (Error: DWORD): NTSTATUS; stdcall = nil;

function DokanLoad(const LibFileName: string = DokanLibrary): Boolean;
procedure DokanFree();

{$else DOKAN_EXPLICIT_LINK}

procedure DokanInit; stdcall;
procedure DokanShutdown; stdcall;
function DokanMain(Options: DOKAN_OPTIONS; Operations: DOKAN_OPERATIONS): Integer; stdcall;
function DokanCreateFileSystem(DokanOptions : DOKAN_OPTIONS; DokanOperations : DOKAN_OPERATIONS; var DokanInstance : DOKAN_HANDLE) : Integer; stdcall;
function DokanIsFileSystemRunning(DokanInstance : DOKAN_HANDLE) : BOOL; stdcall;
function DokanWaitForFileSystemClosed(DokanInstance : DOKAN_HANDLE; dwMilliseconds : DWORD) : DWORD; stdcall;
procedure DokanCloseHandle(DokanInstance : DOKAN_HANDLE); stdcall;
function DokanUnmount(DriveLetter: WCHAR): BOOL; stdcall;
function DokanRemoveMountPoint(MountPoint: LPCWSTR): BOOL; stdcall;
function DokanIsNameInExpression(Expression, Name: LPCWSTR; IgnoreCase: BOOL): BOOL; stdcall;
function DokanVersion(): ULONG; stdcall;
function DokanDriverVersion(): ULONG; stdcall;
function DokanResetTimeout(Timeout: ULONG; var DokanFileInfo: DOKAN_FILE_INFO): BOOL; stdcall;
function DokanOpenRequestorToken(var DokanFileInfo: DOKAN_FILE_INFO): THandle; stdcall;
function DokanGetMountPointList(uncOnly: BOOL; var nbRead: ULONG): PDOKAN_MOUNT_POINT_INFO; stdcall;
procedure DokanReleaseMountPointList(list: PDOKAN_MOUNT_POINT_INFO); stdcall;
procedure DokanMapKernelToUserCreateFileFlags(DesiredAccess: ACCESS_MASK; FileAttributes, CreateOptions,
  CreateDisposition: ULONG; outDesiredAccess: PACCESS_MASK; outFileAttributesAndFlags,
  outCreationDisposition: PDWORD); stdcall;
function DokanNotifyCreate(DokanInstance : DOKAN_HANDLE; FilePath: LPCWSTR; IsDirectory : BOOL) : BOOL; stdcall;
function DokanNotifyDelete(DokanInstance : DOKAN_HANDLE; FilePath : LPCWSTR; IsDirectory : BOOL) : BOOL; stdcall;
function DokanNotifyUpdate(DokanInstance : DOKAN_HANDLE; FilePath : LPCWSTR) : BOOL; stdcall;
function DokanNotifyXAttrUpdate(DokanInstance : DOKAN_HANDLE; FilePath : LPCWSTR) : BOOL; stdcall;
function DokanNotifyRename(DokanInstance : DOKAN_HANDLE; OldPath: LPCWSTR; NewPath : LPCWSTR; IsDirectory : BOOL;
  IsInSameDirectory: BOOL) : BOOL; stdcall;
function DokanNtStatusFromWin32(Error: DWORD): NTSTATUS; stdcall;

{$endif DOKAN_EXPLICIT_LINK}

implementation

{$ifdef DOKAN_EXPLICIT_LINK}

function DokanLoad(const LibFileName: string = DokanLibrary): Boolean;
  function GetProc(const ProcName: string): Pointer;
  begin
    Result := GetProcAddress(DokanLibHandle, PChar(ProcName));
    if Result = nil then
      DokanLoad := False;
  end;
begin
  if DokanLibHandle <> 0 then begin
    Result := True;
    Exit;
  end;

  DokanLibHandle := LoadLibrary(PChar(LibFileName));
  if DokanLibHandle = 0 then begin
    Result := False;
    Exit;
  end;

  Result := True;

  DokanInit := GetProc('DokanInit');
  DokanShutdown := GetProc('DokanShutdown');
  DokanMain := GetProc('DokanMain');
  DokanCreateFileSystem := GetProc('DokanCreateFileSystem');
  DokanIsFileSystemRunning := GetProc('DokanIsFileSystemRunning');
  DokanWaitForFileSystemClosed := GetProc('DokanWaitForFileSystemClosed');
  DokanCloseHandle := GetProc('DokanCloseHandle');
  DokanUnmount := GetProc('DokanUnmount');
  DokanRemoveMountPoint := GetProc('DokanRemoveMountPoint');
  //DokanRemoveMountPointEx := GetProc('DokanRemoveMountPointEx');
  DokanIsNameInExpression := GetProc('DokanIsNameInExpression');
  DokanVersion := GetProc('DokanVersion');
  DokanDriverVersion := GetProc('DokanDriverVersion');
  DokanResetTimeout := GetProc('DokanResetTimeout');
  DokanOpenRequestorToken := GetProc('DokanOpenRequestorToken');
  DokanGetMountPointList := GetProc('DokanGetMountPointList');
  DokanReleaseMountPointList := GetProc('DokanReleaseMountPointList');
  DokanMapKernelToUserCreateFileFlags := GetProc('DokanMapKernelToUserCreateFileFlags');
  DokanNotifyCreate := GetProc('DokanNotifyCreate');
  DokanNotifyDelete := GetProc('DokanNotifyDelete');
  DokanNotifyUpdate := GetProc('DokanNotifyUpdate');
  DokanNotifyXAttrUpdate := GetProc('DokanNotifyXAttrUpdate');
  DokanNotifyRename := GetProc('DokanNotifyRename');
  DokanNtStatusFromWin32 := GetProc('DokanNtStatusFromWin32');

  if not Result then
    DokanFree();
end;

procedure DokanFree();
begin
  if DokanLibHandle = 0 then
    Exit;

  DokanInit := nil
  DokanShutdown := nil;
  DokanMain := nil;
  DokanCreateFileSystem := nil;
  DokanIsFileSystemRunning := nil;
  DokanWaitForFileSystemClosed := nil;
  DokanCloseHandle := nil;
  DokanUnmount := nil;
  DokanRemoveMountPoint := nil;
  //DokanRemoveMountPointEx := nil;
  DokanIsNameInExpression := nil;
  DokanVersion := nil;
  DokanDriverVersion := nil;
  DokanResetTimeout := nil;
  DokanOpenRequestorToken := nil;
  DokanGetMountPointList := nil;
  DokanReleaseMountPointList := nil;
  DokanMapKernelToUserCreateFileFlags := nil;
  DokanNotifyCreate := nil;
  DokanNotifyDelete := nil;
  DokanNotifyUpdate := nil;
  DokanNotifyXAttrUpdate := nil;
  DokanNotifyRename := nil;
  DokanNtStatusFromWin32 := nil;

  FreeLibrary(DokanLibHandle);
  DokanLibHandle := 0;
end;

{$else DOKAN_EXPLICIT_LINK}

procedure DokanInit; external DokanLibrary;
procedure DokanShutdown; external DokanLibrary;
function DokanMain; external DokanLibrary;
function DokanCreateFileSystem; external DokanLibrary;
function DokanIsFileSystemRunning; external DokanLibrary;
function DokanWaitForFileSystemClosed; external DokanLibrary;
procedure DokanCloseHandle; external DokanLibrary;
function DokanUnmount; external DokanLibrary;
function DokanRemoveMountPoint; external DokanLibrary;
//function DokanRemoveMountPointEx; external DokanLibrary;
function DokanIsNameInExpression; external DokanLibrary;
function DokanVersion; external DokanLibrary;
function DokanDriverVersion; external DokanLibrary;
function DokanResetTimeout; external DokanLibrary;
function DokanOpenRequestorToken; external DokanLibrary;
function DokanGetMountPointList; external DokanLibrary;
procedure DokanReleaseMountPointList; external DokanLibrary;
procedure DokanMapKernelToUserCreateFileFlags; external DokanLibrary;
function DokanNotifyCreate; external DokanLibrary;
function DokanNotifyDelete; external DokanLibrary;
function DokanNotifyUpdate; external DokanLibrary;
function DokanNotifyXAttrUpdate; external DokanLibrary;
function DokanNotifyRename; external DokanLibrary;
function DokanNtStatusFromWin32; external DokanLibrary;

{$endif DOKAN_EXPLICIT_LINK}

initialization

finalization

{$ifdef DOKAN_EXPLICIT_LINK}
  DokanFree();
{$endif DOKAN_EXPLICIT_LINK}

end.
