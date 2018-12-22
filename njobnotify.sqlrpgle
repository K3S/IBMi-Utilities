
      /Free
       Ctl-Opt
         MAIN(NJOBNOTIFY)
         DFTACTGRP(*NO)
         ACTGRP(*NEW)
         BNDDIR('QC2LE');
       Dcl-S  errmsgid CHAR(7) Import('_EXCP_MSGID');
       Dcl-PR Cmd Int(10) ExtProc('system');
              cmdstring Pointer Value Options(*String);
       END-PR;
       Dcl-S  jobData SQLTYPE(CLOB:2000);
       Dcl-DS Request Qualified;
              URL  Char(128);
              Head Char(1024);
              Body Char(1024);
       END-DS;

       Dcl-PR printf Int(10) ExtProc('printf');
              format Pointer Value Options(*String);
       END-PR;
       Dcl-DS Company Qualified;
              Comp  Char(3);
              Date  Char(10);
       END-DS;
       Dcl-PR NJOBNOTIFY EXTPGM;
         *N CHAR(1);
         *N CHAR(3);
         *N CHAR(25);
         *N CHAR(1);
       END-PR;

       Dcl-PROC NJOBNOTIFY;
         Dcl-PI NJOBNOTIFY;
           comp     CHAR(1);
           compcod  CHAR(3);
           procname CHAR(25);
           status   CHAR(1);
         END-PI;


        Eval procname = %TrimR(procname);

       //**********************************************************
      //* Change the character code for the job to 37
      //**********************************************************
       IF (Cmd('CHGJOB CCSID(037)') = 1);
         Print('Error : ' + errmsgid);
       ENDIF;
       EXEC SQL SET OPTION commit = *none,
                           datfmt = *iso,
                        closqlcsr = *endactgrp;

         // Declare a cursor for the result set determined by the select
       EXEC SQL DECLARE CMP_Cur CURSOR FOR
           SELECT CM_SYSDATE,
                  CM_COMPCOD
             FROM K_COMPANY;
      // Open the cursor
       EXEC SQL Open CMP_Cur;
       IF (SQLSTATE = '00000');
      // Fetch the data and store it in the DS Company
          EXEC SQL Fetch CMP_cur
                   INTO :Company.Comp,
                        :Company.Date;
       ENDIF;

      // Close the cursor
       EXEC SQL Close CMP_Cur;
       //Debuggin Print
             Print('Company Code: ' + Company.Comp);
             Print('Company Date: ' + Company.Date);

             Request.Head = '<httpHeader>' +
	             '<header name="Content-Type" value="application/json"/>' +
                    '</httpHeader>';
             Request.Body = '{"key":"VQ9B5EbvJ4z@q!jZ",' +
                    '"company_key":"asdf",' +
                    '"company_date":"' + %Char(%Date():*USA) + '",' +
                    '"process_name":"' + procname + '",' +
                    '"process_timestamp":"' + %Char(%TIMESTAMP():*ISO0) + '",' +
                    '"process_status":"' + status + '"}';

              Request.URL  = 'https://dashboard.k3s.com/' +
                'wp-json/k3sstatus/update/';

              printf(Request.Body + x'25');

              EXEC SQL SET :jobData = SYSTOOLS.HTTPPOSTCLOB(
                        :Request.URL,
                        :Request.Head,
                        :Request.Body
                      );


       return;
       END-PROC;

       Dcl-PROC Print;
       Dcl-PI Print;
           pValue CHAR(132) VALUE;
       END-PI;

         pValue = %TrimR(pValue) + x'25';   //Adds a line break
         printf(%Trim(pValue));

       END-PROC;


      /END-FREE







                                           
