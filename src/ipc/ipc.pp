{
    This file is part of the Free Pascal run time library.
    Copyright (c) 1999-2004 by the Free Pascal development team

    This file implements IPC calls calls for Linu/FreeBSD

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit ipc;

interface

Uses BaseUnix,UnixType;

{ ----------------------------------------------------------------------
  General IPC stuff
  ----------------------------------------------------------------------}

//Var
//  IPCError : longint;

Type

   {$IFDEF FreeBSD}
   TKey   = clong;
   {$ELSE}
   TKey   = cint;
   {$ENDIF}
   key_t  = TKey;


Const
  { IPC flags for get calls }

{$if defined(FreeBSD) or defined(NetBSD)}  // BSD_VISIBLE
  IPC_R      =  4 shl 6;
  IPC_W      =  2 shl 6;
  IPC_M      =  2 shl 12;
{$endif}

  IPC_CREAT  =  1 shl 9;  { create if key is nonexistent }
  IPC_EXCL   =  2 shl 9;  { fail if key exists }
  IPC_NOWAIT =  4 shl 9;  { return error on wait }

{$if defined(FreeBSD) or defined(Linux)}
  IPC_PRIVATE : TKey = 0;
{$endif}

  { Actions for ctl calls }

  IPC_RMID = 0;     { remove resource }
  IPC_SET  = 1;     { set ipc_perm options }
  IPC_STAT = 2;     { get ipc_perm options }
  IPC_INFO = 3;     { see ipcs }

type
  PIPC_Perm = ^TIPC_Perm;
{$ifdef FreeBSD}
  TIPC_Perm = record
        cuid  : cushort;  { creator user id }
        cgid  : cushort;  { creator group id }
        uid   : cushort;  { user id }
        gid   : cushort;  { group id }
        mode  : cushort;  { r/w permission }
        seq   : cushort;  { sequence # (to generate unique msg/sem/shm id) }
        key   : key_t;    { user specified msg/sem/shm key }
  End;
{$else} // linux

 {$ifdef cpui386}
   {$ifndef linux_ipc64}
     {$define linux_ipc32}
   {$endif}
 {$endif}

 {$ifndef linux_ipc32}
  TIPC_Perm = record
        key   : TKey;
        uid   : uid_t;
        gid   : gid_t;
        cuid  : uid_t;
        cgid  : gid_t;
        mode  : mode_t;
        __pad1    : cushort;
        seq       : cushort;
        __pad2    : cushort;
        __unused1 : culong;
        __unused2 : culong;
  End;
{$else linux_ipc32}
  TIPC_Perm = record
        key   : TKey;
        uid   : uid_t;
        gid   : gid_t;
        cuid  : uid_t;
        cgid  : gid_t;
        mode  : mode_t;
        seq   : cushort;
  End;
{$endif linux_ipc32}
{$endif}

{ Function to generate a IPC key. }
Function ftok (Path : pchar;  ID : cint) : TKey; {$ifdef FPC_USE_LIBC} cdecl; external name 'ftok'; {$endif}

{ ----------------------------------------------------------------------
  Sys V Shared memory stuff
  ----------------------------------------------------------------------}

Type
  PShmid_DS = ^TShmid_ds;
{$ifdef linux}
{$ifdef cpux86_64}
  TShmid_ds = record
    shm_perm  : TIPC_Perm;
    shm_segsz : size_t;
    shm_atime : time_t;
    shm_dtime : time_t;
    shm_ctime : time_t;
    shm_cpid  : pid_t;
    shm_lpid  : pid_t;
    shm_nattch : culong;
    __unused4 : culong;
    __unused5 : culong;
  end;
{$else cpux86_64}  
  TShmid_ds = record
    shm_perm  : TIPC_Perm;
    shm_segsz : cint;
    shm_atime : time_t;
    shm_dtime : time_t;
    shm_ctime : time_t;
    shm_cpid  : ipc_pid_t;
    shm_lpid  : ipc_pid_t;
    shm_nattch : word;
    shm_npages : word;
    shm_pages  : Pointer;
    attaches   : pointer;
  end;
{$endif cpux86_64}  
{$else} // FreeBSD checked
  TShmid_ds = record
    shm_perm  : TIPC_Perm;
    shm_segsz : cint;
    shm_lpid  : pid_t;
    shm_cpid  : pid_t;
    shm_nattch : cshort;
    shm_atime : time_t;
    shm_dtime : time_t;
    shm_ctime : time_t;
    shm_internal : pointer;
  end;
{$endif}

  const
{$ifdef linux}
     SHM_R      = 4 shl 6;
     SHM_W      = 2 shl 6;
{$else}
     SHM_R      = IPC_R;
     SHM_W      = IPC_W;
{$endif}

     SHM_RDONLY = 1 shl 12;
     SHM_RND    = 2 shl 12;
{$ifdef Linux}
     SHM_REMAP  = 4 shl 12;
{$endif}

     SHM_LOCK   = 11;
     SHM_UNLOCK = 12;

{$ifdef FreeBSD}        // ipcs shmctl commands
     SHM_STAT   = 13;
     SHM_INFO   = 14;
{$endif}

type            // the shm*info kind is "kernel" only.
  PSHMinfo = ^TSHMinfo;
  TSHMinfo = record             // comment under FreeBSD: do we really need
                                // this?
    shmmax : cint;
    shmmin : cint;
    shmmni : cint;
    shmseg : cint;
    shmall : cint;
  end;

{$if defined(freebsd) or defined(linux)}
  PSHM_info = ^TSHM_info;
  TSHM_info = record
    used_ids : cint;
    shm_tot,
    shm_rss,
    shm_swp,
    swap_attempts,
    swap_successes : culong;
  end;
{$endif}

Function shmget(key: Tkey; size:size_t; flag:cint):cint; {$ifdef FPC_USE_LIBC} cdecl; external name 'shmget'; {$endif}
Function shmat (shmid:cint; shmaddr:pointer; shmflg:cint):pointer; {$ifdef FPC_USE_LIBC} cdecl; external name 'shmat'; {$endif}
Function shmdt (shmaddr:pointer):cint; {$ifdef FPC_USE_LIBC} cdecl; external name 'shmdt'; {$endif}
Function shmctl(shmid:cint; cmd:cint; buf: pshmid_ds): cint; {$ifdef FPC_USE_LIBC} cdecl; external name 'shmctl'; {$endif}

{ ----------------------------------------------------------------------
  Message queue stuff
  ----------------------------------------------------------------------}

const
  MSG_NOERROR = 1 shl 12;

{$ifdef Linux}
  MSG_EXCEPT  = 2 shl 12;

  MSGMNI = 128;
  MSGMAX = 4056;
  MSGMNB = 16384;
{$endif}

type
  msglen_t = culong;
  msgqnum_t= culong;

  PMSG = ^TMSG;
  TMSG = record
{$ifndef FreeBSD}                       // opague in FreeBSD
    msg_next  : PMSG;
    msg_type  : Longint;
    msg_spot  : PChar;
    msg_stime : Longint;
    msg_ts    : Integer;
{$endif}
  end;

type

{$ifdef Linux}
  PMSQid_ds = ^TMSQid_ds;
  TMSQid_ds = record
    msg_perm   : TIPC_perm;
    msg_first  : PMsg;
    msg_last   : PMsg;
    msg_stime  : time_t;
    msg_rtime  : time_t;
    msg_ctime  : time_t;
    msg_cbytes : word;
    msg_qnum   : word;
    msg_qbytes : word;
    msg_lspid  : ipc_pid_t;
    msg_lrpid  : ipc_pid_t;
  end;
{$else}
  PMSQid_ds = ^TMSQid_ds;
  TMSQid_ds = record
    msg_perm   : TIPC_perm;
    msg_first  : PMsg;
    msg_last   : PMsg;
    msg_cbytes : msglen_t;
    msg_qnum   : msgqnum_t;
    msg_qbytes : msglen_t;
    msg_lspid  : pid_t;
    msg_lrpid  : pid_t;
    msg_stime  : time_t;
    msg_pad1   : clong;
    msg_rtime  : time_t;
    msg_pad2   : clong;
    msg_ctime  : time_t;
    msg_pad3   : clong;
    msg_pad4   : array [0..3] of clong;
  end;
{$endif}

  PMSGbuf = ^TMSGbuf;
  TMSGbuf = record              // called mymsg on freebsd and SVID manual
    mtype : clong;
    mtext : array[0..0] of char;
  end;

{$ifdef linux}
  PMSGinfo = ^TMSGinfo;
  TMSGinfo = record
    msgpool : cint;
    msgmap  : cint;
    msgmax  : cint;
    msgmnb  : cint;
    msgmni  : cint;
    msgssz  : cint;
    msgtql  : cint;
    msgseg  : cushort;
  end;
{$else}
  PMSGinfo = ^TMSGinfo;
  TMSGinfo = record
    msgmax,
    msgmni,
    msgmnb,
    msgtql,
    msgssz,
    msgseg  : cint;
  end;
{$endif}

Function msgget(key: TKey; msgflg:cint):cint; {$ifdef FPC_USE_LIBC} cdecl; external name 'msgget'; {$endif}
Function msgsnd(msqid:cint; msgp: PMSGBuf; msgsz: size_t; msgflg:cint): cint; {$ifdef FPC_USE_LIBC} cdecl; external name 'msgsnd'; {$endif}
Function msgrcv(msqid:cint; msgp: PMSGBuf; msgsz: size_t; msgtyp:clong; msgflg:cint):cint; {$ifdef FPC_USE_LIBC} cdecl; external name 'msgrcv'; {$endif}
Function msgctl(msqid:cint; cmd: cint; buf: PMSQid_ds): cint; {$ifdef FPC_USE_LIBC} cdecl; external name 'msgctl'; {$endif}

{ ----------------------------------------------------------------------
  Semaphores stuff
  ----------------------------------------------------------------------}

const
{$ifdef Linux}                  // renamed to many name clashes
  SEM_UNDO = $1000;
  SEM_GETPID = 11;
  SEM_GETVAL = 12;
  SEM_GETALL = 13;
  SEM_GETNCNT = 14;
  SEM_GETZCNT = 15;
  SEM_SETVAL = 16;
  SEM_SETALL = 17;

  SEM_SEMMNI = 128;
  SEM_SEMMSL = 32;
  SEM_SEMMNS = (SEM_SEMMNI * SEM_SEMMSL);
  SEM_SEMOPM = 32;
  SEM_SEMVMX = 32767;
{$else}
  SEM_UNDO = 1 shl 12;
  MAX_SOPS = 5;

  SEM_GETNCNT = 3;   { Return the value of sempid {READ}  }
  SEM_GETPID  = 4;   { Return the value of semval {READ}  }
  SEM_GETVAL  = 5;   { Return semvals into arg.array {READ}  }
  SEM_GETALL  = 6;   { Return the value of semzcnt {READ}  }
  SEM_GETZCNT = 7;   { Set the value of semval to arg.val {ALTER}  }
  SEM_SETVAL  = 8;   { Set semvals from arg.array {ALTER}  }
  SEM_SETALL  = 9;

  { Permissions  }

  SEM_A = 2 shl 6;  { alter permission  }
  SEM_R = 4 shl 6;  { read permission  }
{$endif}

type
{$ifdef Linux}
  PSEMid_ds = ^TSEMid_ds;

  {$ifndef linux_ipc32}
  TSEMid_ds = record
    sem_perm  : tipc_perm;
    sem_otime : time_t;   // kernel
    unused1   : culong;
    sem_ctime : time_t;
    unused2   : culong;
    sem_nsems : culong;
    unused3   : culong;
    unused4   : culong;
   end;
   {$else}
  TSEMid_ds = record
    sem_perm : tipc_perm;
    sem_otime : time_t;   // kernel
    sem_ctime : time_t;
    sem_base         : pointer;
    sem_pending      : pointer;
    sem_pending_last : pointer;
    undo             : pointer;
    sem_nsems : cushort;
  end;
  {$endif}
{$else}

     sem=record end; // opague

  PSEMid_ds = ^TSEMid_ds;
  TSEMid_ds = record
          sem_perm : tipc_perm;
          sem_base : ^sem;
          sem_nsems : cushort;
          sem_otime : time_t;
          sem_pad1 : cint;
          sem_ctime : time_t;
          sem_pad2 : cint;
          sem_pad3 : array[0..3] of cint;
       end;
{$endif}

  PSEMbuf = ^TSEMbuf;
  TSEMbuf = record
    sem_num : cushort;
    sem_op  : cshort;
    sem_flg : cshort;
  end;


  PSEMinfo = ^TSEMinfo;
  TSEMinfo = record
    semmap : cint;
    semmni : cint;
    semmns : cint;
    semmnu : cint;
    semmsl : cint;
    semopm : cint;
    semume : cint;
    semusz : cint;
    semvmx : cint;
    semaem : cint;
  end;

{ internal mode bits}

{$ifdef FreeBSD}
Const
  SEM_ALLOC = 1 shl 9;
  SEM_DEST  = 2 shl 9;
{$endif}

Type
  PSEMun = ^TSEMun;
  TSEMun = record
   case cint of
      0 : ( val : cint );
      1 : ( buf : PSEMid_ds );
      2 : ( arr : PWord );              // ^ushort
{$ifdef linux}
      3 : ( padbuf : PSeminfo );
      4 : ( padpad : pointer );
{$endif}
   end;

Function semget(key:Tkey; nsems:cint; semflg:cint): cint; {$ifdef FPC_USE_LIBC} cdecl; external name 'semget'; {$endif}
Function semop(semid:cint; sops: psembuf; nsops: cuint): cint; {$ifdef FPC_USE_LIBC} cdecl; external name 'semop'; {$endif}
Function semctl(semid:cint; semnum:cint; cmd:cint; var arg: tsemun): cint; {$ifdef FPC_USE_LIBC} cdecl; external name 'semctl'; {$endif}
Function semtimedop(semid:cint; sops: psembuf; nsops: cuint; timeOut: ptimespec): cint; {$ifdef FPC_USE_LIBC} cdecl; external name 'semtimedop'; {$endif}

implementation

uses Syscall;

{$ifndef FPC_USE_LIBC}
 {$ifdef Linux}
  {$ifdef cpux86_64}
    {$i ipcsys.inc}
  {$else}
    {$i ipccall.inc}
  {$endif}
 {$endif}
 {$ifdef BSD}
   {$i ipcbsd.inc}
 {$endif}
{$endif}


end.
