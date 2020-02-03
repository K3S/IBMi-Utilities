//***********************************************************************
//*
//* Name: AR_RLSMISC - Release Locks created from ODBC Connections
//* Type: ILE RPG Program
//* Desc: Release Locks created from ODBC Connections
//* Auth: Carlos Palacios {Took from Stephanie Rabbini from IBM}
//* Credit: Stephanie Rabbni
//*
//* copyright('(C) Copyright 1996 - 2020 King III Solutions, Inc. +
//* Rel 5.1 2014-01-01 Program Property of King III Solutions, Inc. +
//* All rights reserved +
//* K3S_Replenish (R) is a Registered Trade Mark of King III Solutions Inc.')
//*
//* This program is used to perform the function of releasing locks created by
//* persistent connections via ODBC.
//*
//* Every Connection via ODBC is viewable via query on DB2 Table:
//* 'Active_job_Info' within QSYS2 Lib.
//*
//* Any persistent connection via ODBC uses QUSER as the main driver of the connection.
//*
//* However, it keeps the user that starts the ODBC under the field AUTHORIZATION_NAME
//*
//* Selection Criteria require this value, so that is specific for ending the job
//* of the user initiating the ODBC Connection.
//*
//* When Program is invoked, it receives the User ( different than QUSER ), so that
//* API can ends all jobs associated to the AUTHORIZATION_NAME field
//*
//* *************************************************************
//*
//* GH632 01/22/2020 - Initially Written.
//*
//*
//* *************************************************************
//*
/free
Ctl-Opt OPTION(*NODEBUGIO:*SRCSTMT)
DFTACTGRP(*NO)
ACTGRP('K3S_ACTG_5')
BNDDIR('QC2LE');
Dcl-Ds Row Qualified;
jobname varchar(28);
author varchar(10);
End-Ds;
dcl-pr QCMDEXC extpgm ;
*n char(250) options(*varsize) const ;
*n packed(15:5) const ;
end-pr ;
dcl-s Command varchar(250) ;
dcl-s Length packed(15:5) ;
dcl-s vusr varchar(10) ;
dcl-pr ar_rlsmisc extpgm;
r6user char(10);
end-pr;
dcl-pi ar_rlsmisc;
r6user char(10);
end-pi;
EXEC SQL
DECLARE Cur CURSOR FOR
select JOB_NAME, AUTHORIZATION_NAME from
table(qsys2.active_job_info(RESET_STATISTICS =>
'YES')) x where JOB_NAME LIKE '%QUSER/%' and
AUTHORIZATION_NAME = :r6user;
EXEC SQL OPEN Cur;
EXEC SQL
FETCH NEXT FROM Cur
INTO :Row;
Dow (SQLSTATE = '00000');
Command = 'ENDJOB JOB(' + row.jobname + ') OPTION(*IMMED)' ;
QCMDEXC(Command:%len(%trimr(Command))) ;
EXEC SQL
FETCH NEXT FROM Cur
INTO :Row;
EndDo;
EXEC SQL CLOSE Cur;
Return;
