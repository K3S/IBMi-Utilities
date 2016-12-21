      //***********************************************************
      //*
      //*   Name: HB_PING -- Ping Server
      //*   Type: ILE RPG Program
      //*   Desc: Check HOST connectivity
      //*   Auth: Thomas Reynolds
      //*   Credit: Input from Liam
      //***********************************************************
      //*
      /FREE
       Ctl-Opt DFTACTGRP(*NO)
               ACTGRP(*NEW)
               BNDDIR('QC2LE')
               OPTION(*NODEBUGIO:*SRCSTMT);
       Dcl-s IPADDR   CHAR(13) Inz('00.0.00.00');      // IP Address of the server to ping
       Dcl-c FNAME    '/home/USER/server.txt';          // log file full name
       Dcl-c EMADDR   'technicalalert@me.com';// email to send alerts to
       Dcl-s cmdstr   CHAR(500);
       Dcl-s ServErr  IND;
       Dcl-s NoFile   IND;


       Dcl-DS File_Temp Qualified Template;
         PathFile  CHAR(128);
         RtvData   CHAR(256);
         OpenMode  CHAR(5);
         FilePtr   POINTER INZ;
       END-DS;

       Dcl-DS gServFile LikeDS(File_Temp);

       Dcl-PR Cmd Int(10) ExtProc('system');
                cmdstring Pointer Value Options(*String);
       END-PR;

       Dcl-s errmsgid CHAR(7) Import('_EXCP_MSGID');

       Dcl-PR access Int(10) ExtProc('access');
               path     Pointer Value Options(*String);
               amode    INT(10) Value;
       END-PR;

       Dcl-PR unlink Int(10) ExtProc('unlink');
               path     Pointer Value Options(*String);
       END-PR;

       Dcl-PR OpenFile POINTER ExtProc('_C_IFS_fopen');
         fname   POINTER VALUE;
         fmode   POINTER VALUE;
       END-PR;

       Dcl-PR ReadFile POINTER ExtProc('_C_IFS_fgets');
         rdata   POINTER VALUE;
         dsize   INT(10) VALUE;
         mptr    POINTER VALUE;
       END-PR;

       Dcl-PR WriteFile POINTER ExtProc('_C_IFS_fwrite');
         wdata   POINTER VALUE;
         dsize   INT(10) VALUE;
         bsize   INT(10) VALUE;
         mptr    POINTER VALUE;
       END-PR;

       Dcl-PR CloseFile ExtProc('_C_IFS_fclose');
         mptr    POINTER VALUE;
       END-PR;

       Dcl-PR printf Int(10) ExtProc('printf');
         format Pointer Value Options(*String);
       END-PR;

       Dcl-C F_OK            0;       // File exists
       //*---------------------------------------------------------
       //* Begin Main Program Flow
       //*---------------------------------------------------------
       Eval cmdstr = 'VFYTCPCNN RMTSYS(*INTNETADR) INTNETADR(''' +
                     %Trim(IPADDR) +
                     ''') PKTLEN(32) WAITTIME(3) MSGMODE(*VERBOSE *ESCAPE)';

       IF (Cmd(cmdstr) = 1);   //Check the connectivity
         ServErr = *On;        //Failure
       ELSE;
         ServErr = *Off;       //Success
       ENDIF;

       IF access(%Trim(FNAME):F_OK) < 0;// Check the log file
          NoFile = *On;                 // Doesn't exist
       ELSE;
          NoFile = *Off;                // It exists
       ENDIF;

       IF NoFile and (not ServErr); // Everything is good
          *InLr = *On;              // Signal that its okay to end
       ENDIF;

       IF NoFile and ServErr; // The first instance of the server going down
          WriteData(FNAME:%Char(%Date():*USA):%Char(%Time():*USA));
          SendAlert(EMADDR);
       ENDIF;

       IF (not NoFile) and ServErr; // Another fail
          WriteData(FNAME:%Char(%Date():*USA):%Char(%Time():*USA));
          SendAlert(EMADDR);
       ENDIF;

       IF (not NoFile) and (not ServErr);// Server is up, but log exists
          WriteData(FNAME:%Char(%Date():*USA):%Char(%Time():*USA));
          ReadData(FNAME);
          RemoveFile(FNAME);
       ENDIF;

       *InLr = *On;



      //***********************************************************
      //* Print a string: credit to Liam (WorksOfBarry)
      //***********************************************************
       Dcl-PROC Print;
         Dcl-PI Print;
           pValue CHAR(132) VALUE;
         END-PI;

         pValue = %TrimR(pValue) + x'25';   //Adds a line break
         printf(%Trim(pValue));

       END-PROC;
      //***********************************************************
      //* RemoveFile: delete a file if it exists, otherwise do nothing
      //***********************************************************
       Dcl-PROC RemoveFile;
         Dcl-PI RemoveFile;
           path CHAR(200) VALUE;
         END-PI;
         IF not (access(%TrimR(path):F_OK) < 0); // IF the file exists
             unlink(%TrimR(path));               // delete it
         ENDIF;
       END-PROC;
      //***********************************************************
      //* ReadData: read entries in the log file, report the first and last dates/times
      //***********************************************************
       Dcl-PROC ReadData;
         Dcl-PI ReadData;
           path CHAR(200) VALUE;
         END-PI;

         Dcl-s counter  INT(10);
         Dcl-s fstTime  CHAR(8);
         Dcl-s fstDate  CHAR(10);
         Dcl-s lstTime  CHAR(8);
         Dcl-s lstDate  CHAR(10);
         Dcl-s emailts  CHAR(500);
         counter = 1;

         IF not (access(%TrimR(path):F_OK) < 0);
            gServFile.OpenMode = 'r' +  x'00';
            gServFile.PathFile = %Trim(path) + x'00';
            gServFile.FilePtr  = OpenFile(%addr(gServFile.PathFile)
                                         :%addr(gServFile.OpenMode));

           IF (gServFile.FilePtr <> *null);

         DOW (ReadFile(%addr(gServFile.RtvData)
                      :%Len(gServFile.RtvData)
                      :gServFile.FilePtr) <> *null);
             gServFile.RtvData = %xlate(x'00':' ':gServFile.RtvData);
             gServFile.RtvData = %xlate(x'25':' ':gServFile.RtvData);
             gServFile.RtvData = %xlate(x'0D':' ':gServFile.RtvData);
             gServFile.RtvData = %xlate(x'05':' ':gServFile.RtvData);

             IF (gServFile.RtvData <> ' ');
               IF (counter = 1);
                 fstDate = gServFile.RtvData;
               ELSEIF (counter = 2);
                 fstTime = gServFile.RtvData;
               ELSE;

                 IF (%rem(counter:2) <> 0);// Check if counter is even or odd
                    lstDate = gServFile.RtvData;// Even
                 ELSE;
                    lstTime = gServFile.RtvData;// Odd
                 ENDIF;

               ENDIF;
               counter += 1;
             ENDIF;
             gServFile.RtvData = ' ';// Clear the buffer

         ENDDO;
         ENDIF;
         ENDIF;

         CloseFile(gServFile.FilePtr); //Close the file

         Eval emailts = 'SNDSMTPEMM RCP((' + EMADDR + ' *PRI)) ' +
                        'SUBJECT(''' + 'ARTHUR UP' + ''') NOTE(''' +
                     '<h3> SERVER UP </h3> <h1> First Down </h1>' +
                     '<p>DATE: ' + fstDate + '</p>' +
                     '<p>TIME: ' + fstTime + '</p> <h1> Last Down </h1>' +
                     '<p>DATE: ' + lstDate + '</p>' +
                     '<p>TIME: ' + lstTime + '</p>' + ''') CONTENT(*HTML)' +
                     ' ATTACH((''' + FNAME +  ''' *PLAIN *TXT))';


        IF (Cmd(emailts) = 1);
           Print('Email error: ' + errmsgid);
           Print('Email : ' + emailts);
        ENDIF;

       END-PROC;
      //***********************************************************
      //* WriteData: write a date and time to a log file
      //***********************************************************
       Dcl-PROC WriteData;
         Dcl-PI WriteData;
            path  CHAR(200) VALUE;
            wdate CHAR(32)  VALUE;
            wtime CHAR(32)  VALUE;
         END-PI;
         wdate = %Trim(wdate) + x'25';
         wtime = %Trim(wtime) + x'25';
         gServFile.OpenMode = 'ab' +  x'00';
         gServFile.PathFile = %Trim(path) + x'00';
         gServFile.FilePtr  = OpenFile(%addr(gServFile.PathFile)
                                      :%addr(gServFile.OpenMode));

         WriteFile(%addr(wdate)
                  :%Len(%TrimR(wdate))
                  :1
                  :gServFile.FilePtr);

         WriteFile(%addr(wtime)
                  :%Len(%TrimR(wtime))
                  :1
                  :gServFile.FilePtr);

         CloseFile(gServFile.FilePtr); //Close the file

       END-PROC;
      //***********************************************************
      //* SendAlert: send an email to the tech support email
      //***********************************************************
       Dcl-PROC SendAlert;
         Dcl-PI SendAlert;
           rcp  CHAR(200) VALUE;
         END-PI;

         Dcl-s email CHAR(500);

         Eval rcp = 'RCP((' + %Trim(rcp) + ' *PRI)) ';

         Eval email = 'SNDSMTPEMM ' + rcp + 'SUBJECT(''' +
                      'SERVER DOWN' + ''') NOTE(''' +
                      '<h1> SERVER DOWN </h1><p>DATE: ' + %Char(%Date():*USA) +
                      '</p><p>TIME: ' + %Char(%Time():*USA) + '</p>' +
                      ''') CONTENT(*HTML)';

        IF (Cmd(email) = 1);
           Print('Email error: ' + errmsgid);
           Print('Email : ' + email);
        ENDIF;

       END-PROC;

      /END-FREE

 
