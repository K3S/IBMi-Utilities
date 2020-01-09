**FREE
Ctl-Opt DftActGrp(*No);
Dcl-Ds Row Qualified;
  jobname varchar(28);
End-Ds;
dcl-pr QCMDEXC extpgm ;
    *n char(250) options(*varsize) const ;
    *n packed(15:5) const ;
end-pr ;
dcl-s Command varchar(250) ;
dcl-s Length packed(15:5) ;
dcl-s vusr varchar(10) ;
//Dcl-pr endjobs ExtPgm;
//  *N char(10);
//End-pr;
//Dcl-pi endjobs;
//  usr char(10);
//End-pi;
   
   //vusr = %trim(usr);
    EXEC SQL
      DECLARE Cur CURSOR FOR
        select JOB_NAME from table(qsys2.active_job_info(RESET_STATISTICS =>
        'YES')) x where JOB_NAME LIKE '%QUSER/QZDASOINIT%';
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
    Enddo;
    EXEC SQL CLOSE Cur;
Return;
