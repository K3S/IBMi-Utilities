      ******************************************************************
     h MAIN(SLKUPL)
     h DFTACTGRP(*NO) ACTGRP(*NEW)
     h BNDDIR('QC2LE')

      *****************************************************************
      **
      **   K3S-Replenish (R) - Inventory REPLENISHment System
      **   Copyright (C) 1996-2013 by King III Solutions, Inc.
      **   Program property of King III Solutions, Inc.
      **   All rights reserved.
      **   K3S_Replenish (R) is a Registered Trade Mark of
      **   King III Solutions Inc.
      **
      *****************************************************************
      **
      **   Name: SLKUPL
      **   Type: ILE RPG Program
      **   Desc: Upload Files to Slack
      **   Auth: Tom Reynolds
      **
      ******************************************************************
      **                                                               *
      **  This program is used to upload file to Slack                 *
      **                                                               *
      **   Change ID  Change Date Change Description                   *
      **   ---------  ----------  -------------------------------------*
      **              01-08-2019  Initially Written                    *
      ******************************************************************
       /Free
       Dcl-C token  'your-token-here';
       Dcl-S errmsgid CHAR(7) Import('_EXCP_MSGID');
       Dcl-PR Cmd Int(10) ExtProc('system');
                cmdstring Pointer Value Options(*String);
       END-PR;
       Dcl-PR printf Int(10) ExtProc('printf');
         format Pointer Value Options(*String);
       END-PR;


       Dcl-DS  UpFile      Qualified INZ;
         Source    SQLTYPE(CLOB:1000000) CCSID(*UTF8);
         Encoded   SQLTYPE(CLOB:1000000);
         Input     SQLTYPE(CLOB:1000000);
       END-DS;

       // Program prototype for the main program
       Dcl-PR SLKUPL EXTPGM;
             code   CHAR(3);
             src    CHAR(255);
             ftype  CHAR(3);
       END-PR;

       Dcl-PROC SLKUPL;
         Dcl-PI *N;
             code   CHAR(3);
             src    CHAR(255);
             ftype  CHAR(3);
         END-PI;


         IF (Cmd('CHGJOB CCSID(037)') = 1);
            Print('Error : ' + errmsgid);
         ENDIF;

         IF copyFile(%subst(src:1:%SCAN(' ':src))) = *on;
           IF SQLCODE >= *ZERO AND UpFile.Source_len > *ZERO;
              urlEncode(UpFile);
              fileUpload(code:%subst(src:1:%SCAN(' ':src)):ftype:UpFile);
           ENDIF;
         ENDIF;

       *inlr = *on;
       return;
       END-PROC;

        Dcl-PROC Print;
         Dcl-PI Print;
           pValue CHAR(132) VALUE;
         END-PI;

         printf(%Trim(pValue));

       END-PROC;

      * Procedure from
      * https://github.com/RainerRoss/JavaScript-Minifier/blob/master/JSMINIFY.SQLRPGLE
       Dcl-PROC urlEncode;
         Dcl-PI *n;
                 Target      likeds(UpFile);
         END-PI;

        Dcl-S   LocData     VARCHAR(1000);                // data to encode
        Dcl-S   LocSize     uns(10) inz(%len(LocData));   // encode size
        Dcl-S   LocEnc      VARCHAR(30000);               // encoded data
        Dcl-S   LocEncSize  uns(10);                      // encoded size
        Dcl-S   LocStart    uns(10);                      // start position
        Dcl-S   LocRest     uns(10);                      // rest bytes
        Dcl-S   LocInd      uns(10);                      // index

           LocRest = Target.Source_len;

           DOU LocEncSize >= Target.Source_len;
             LocInd += 1;

             LocStart = (LocSize * (LocInd - 1)) + 1;

             IF LocRest >= LocSize;
                LocRest -= LocSize;
                LocData  = %subst(Target.Source_data:LocStart:LocSize);
                EXEC SQL SET :LocEnc = SYSTOOLS.URLENCODE(:LocData,'UTF-8');
                EXEC SQL SET :Target.Encoded = :Target.Encoded CONCAT :LocEnc;
                LocEncSize += LocSize;
              ELSE;
                LocData  = %subst(Target.Source_data:LocStart:LocRest);
                EXEC SQL SET :LocEnc = SYSTOOLS.URLENCODE(:LocData,'UTF-8');
                EXEC SQL SET :Target.Encoded = :Target.Encoded CONCAT :LocEnc;
                LocEncSize += LocRest;
             ENDIF;

           ENDDO;

         END-PROC;

         Dcl-PROC fileUpload;
           Dcl-PI *N;
                 code       CHAR(3);
                 src        CHAR(255) VALUE;
                 ftype      CHAR(3);
                 Target     LikeDS(UpFile);
           END-PI;

        Dcl-S   LocData     SQLTYPE(CLOB:1000000);   // CLOB 1 MB
        Dcl-S   LocURL      VARCHAR(256);
        Dcl-S   LocHeader   VARCHAR(256);
        Dcl-S   LocOptions  VARCHAR(256);
        Dcl-S   postResp    VARCHAR(64000) INZ;
           LocURL    = 'https://slack.com/api/files.upload';

           LocHeader = '<httpHeader>'
         + '<header name="Content-Type" value="'
         +  'application/x-www-form-urlencoded"/>'
         + '<header name="Authorization" value="Bearer '
         + token  + '"/>'
         + '</httpHeader>';

           LocOptions = 'channels=monitor-errors&'
         + 'filetype=' + %trimr(ftype) + '&'
         + 'filename=' + %trimr(src)   + '&'
         + 'title='    + %trim(code)   + ' Error Dump&'
         + 'content=';

           EXEC SQL SET :LocData = :LocOptions CONCAT :Target.Encoded;
           EXEC SQL SET :Target.Input = SYSTOOLS.HTTPPOSTCLOB(
                        :LocURL,
                        :LocHeader,
                        :LocData);
           postResp = %subst(Target.Input_data:1:Target.Input_len);
          
         END-PROC;

         Dcl-PROC copyFile;
          Dcl-PI *N IND;
            path CHAR(255) VALUE OPTIONS(*TRIM);
          END-PI;

          Dcl-S dynSQL CHAR(1024);
          path   = '''' + %trimr(path) + '''';

          dynSQL = 'SELECT GET_CLOB_FROM_FILE('
          + %trimr(path)
          + ') FROM SYSIBM.SYSDUMMY1';

          dynSQL = %trim(dynSQL);

          EXEC SQL PREPARE SQL_Stmt1 FROM :dynSQL;
          EXEC SQL DECLARE C1 CURSOR FOR SQL_Stmt1;
          EXEC SQL OPEN C1;
          EXEC SQL FETCH C1 INTO :UpFile.Source;
          EXEC SQL CLOSE C1;

          IF SQLCODE < *ZERO OR UpFile.Source_len <= *ZERO;
            return *off;
          ELSE;
            return *on;
          ENDIF;

         END-PROC;

      /END-FREE 
