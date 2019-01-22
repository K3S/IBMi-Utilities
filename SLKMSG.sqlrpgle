      ******************************************************************
     h MAIN(AR_SLKMSG)
     h DFTACTGRP(*NO) ACTGRP(*NEW)
     h BNDDIR('QC2LE')
      ******************************************************************
      **
      **   Name: AR_SLKMSG
      **   Type: ILE RPG Program
      **   Desc: Send messages and notifications via Slack
      **   Auth: Tom Reynolds
      **
      ******************************************************************
      **                                                               *
      **  This program is used to send messages and notifications      *
      **                                                               *
      **   Change ID  Change Date Change Description                   *
      **   ---------  ----------  -------------------------------------*
      **              01-08-2019  Initially Written                    *
      **   Reynolds   01-15-2019  Working for Beta Testing             *
      ******************************************************************
       /Free
       Dcl-C token  'your-slack-token';

       Dcl-S errmsgid CHAR(7) Import('_EXCP_MSGID');

       Dcl-PR Cmd Int(10) ExtProc('system');
                cmdstring Pointer Value Options(*String);
       END-PR;

       Dcl-PR printf Int(10) ExtProc('printf');
         format Pointer Value Options(*String);
       END-PR;

       Dcl-DS  UpFile      Qualified INZ;
         Source     SQLTYPE(CLOB:1000000) CCSID(*UTF8);
         Encoded    SQLTYPE(CLOB:1000000);
         Input      SQLTYPE(CLOB:1000000);
       END-DS;

       // Program prototype for the main program
       Dcl-PR AR_SLKMSG EXTPGM;
             code    CHAR(3);
             channel CHAR(100);
             message CHAR(32000);
       END-PR;

       Dcl-PROC AR_SLKMSG;
         Dcl-PI *N;
             code    CHAR(3);
             channel CHAR(100);
             message CHAR(32000);
         END-PI;

         IF (Cmd('CHGJOB CCSID(037)') = 1);
            Print('Error : ' + errmsgid);
         ENDIF;


         IF encodeMessage(
           %SUBST(message:1:%SCAN('*':message) - 1)
           :%SCAN('*':message)
           :UpFile) = *on;
             sendMessage(
             code
             :%SUBST(channel:1:%SCAN('*':channel) - 1)
             :UpFile);
         ENDIF;


       *inlr = *on;
       return;
       END-PROC;

       Dcl-PROC sendMessage;
         Dcl-PI *N IND;
           code       CHAR(3);
           chan       CHAR(255)   VALUE;
           Target     LikeDS(UpFile);
         END-PI;


         Dcl-S   LocURL      VARCHAR(256);
         Dcl-S   LocHeader   VARCHAR(256);
         Dcl-S   LocOptions  VARCHAR(256);
         Dcl-S   LocData     SQLTYPE(CLOB:1000000);
         Dcl-S   postResp    VARCHAR(64000) INZ;


         LocURL     = 'https://slack.com/api/chat.postMessage';
         LocHeader  = '<httpHeader>'
         + '<header name="Content-Type" value="'
         +  'application/x-www-form-urlencoded"/>'
         + '<header name="Authorization" value="Bearer '
         + token  + '"/>'
         + '</httpHeader>';

         LocOptions = 'channel=#' + %trimr(chan) + '&'
         + 'text=';


          EXEC SQL SET :LocData = :LocOptions CONCAT :Target.Encoded;
          EXEC SQL SET :Target.Input = SYSTOOLS.HTTPPOSTCLOB(
                        :LocURL,
                        :LocHeader,
                        :LocData);



         postResp = %SUBST(Target.Input_data:1:Target.Input_len);
         IF %SCAN('error':postResp) > 0;
           return *off;
         ELSE;
           return *on;
         ENDIF;


       END-PROC;

       Dcl-PROC encodeMessage;
        Dcl-PI *N IND;
            message    CHAR(37000) VALUE OPTIONS(*TRIM);
            msgLength  UNS(10) VALUE;
            Target     LikeDS(UpFile);
        END-PI;
          Dcl-S   LocData     VARCHAR(1000);                // data to encode
          Dcl-S   LocSize     uns(10) inz(%len(LocData));   // encode size
          Dcl-S   LocEnc      VARCHAR(30000);               // encoded data
          Dcl-S   LocEncSize  uns(10);                      // encoded size
          Dcl-S   LocStart    uns(10);                      // start position
          Dcl-S   LocRest     uns(10);                      // rest bytes
          Dcl-S   LocInd      uns(10);                      // index

           message = %trimr(message);
           LocRest = msgLength;

           DOU LocEncSize >= msgLength;
             LocInd += 1;

             LocStart = (LocSize * (LocInd - 1)) + 1;

             IF LocRest >= LocSize;
                LocRest -= LocSize;
                LocData  = %SUBST(message:LocStart:LocSize);
                EXEC SQL SET :LocEnc = SYSTOOLS.URLENCODE(:LocData,'UTF-8');
                EXEC SQL SET :Target.Encoded = :Target.Encoded CONCAT :LocEnc;
                LocEncSize += LocSize;
              ELSE;
                LocData  = %SUBST(message:LocStart:LocRest);
                EXEC SQL SET :LocEnc = SYSTOOLS.URLENCODE(:LocData,'UTF-8');
                EXEC SQL SET :Target.Encoded = :Target.Encoded CONCAT :LocEnc;
                LocEncSize += LocRest;
             ENDIF;

           ENDDO;

          IF SQLCODE < *ZERO;
            return *off;
          ELSE;
            return *on;
          ENDIF;


       END-PROC;

       Dcl-PROC Print;
          Dcl-PI Print;
           pValue CHAR(132) VALUE;
          END-PI;
          
           printf(%Trim(pValue));

       END-PROC;



      /END-FREE                                                
