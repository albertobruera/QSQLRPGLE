         ctl-opt dftactgrp(*no) actgrp(*new);

         dcl-f ARTFAQ00V workstn indds(dspf) sfile(ARTFAQSFL:RRN);

         dcl-pr ArtFaq     extpgm('ARTFAQ01R');
         end-pr;

         dcl-pr CmdExc     extpgm('QCMDEXC');
           Cmd    Char(256) const;
           Len    Packed(15:5) const;
         end-pr;

         dcl-pr access Int(10:0) extproc('access')          ;
           Path     Pointer value options(*String);
           mode     Int(10:0) value options(*nopass);
         end-pr;

         dcl-pi ArtFaq;
         end-pi;

         dcl-ds Ds_Faq qualified;
           FQCODART char(7);
           FQDESART char(60);
           FQIDDOM  zoned(3:0);
           FQDOM    char(512);
           FQRIS    char(2024);
           FQNDOC   char(50);
         End-ds;
         dcl-ds Ds_Art ExtName('ART00') qualified;
         End-ds;
         Dcl-ds Dspf qualified;
          Exit      ind pos(3);
          Refresh   Ind pos(5);
          Insert    Ind pos(6);
          Annulla   Ind pos(12);
          SflDspCtl Ind pos(30);
          SflDsp    Ind pos(31);
          SflClr    Ind pos(32);
          Error     Ind pos(35);
          ProtectArt     Ind pos(45);
          ProtectField   Ind pos(46);
          DspDesc        Ind pos(55);
          ErrDes         Ind pos(65);
          IndDoc         Ind pos(75);
          ErrMsgDoc      Ind pos(85);
         End-ds;

         Dcl-s Id       Zoned(5:0);
         Dcl-s Rrn      Zoned(5:0);
         Dcl-s Desc     Char(50);
         Dcl-s Cmd      Char(4048);
         Dcl-s Apice    Char(1) inz('''');
         Dcl-s Count    Zoned(2:0)       ;
         Dcl-s File_In  SQLTYPE(BLOB_FILE);
         Dcl-s File_Out SQLTYPE(BLOB_FILE);
         Dcl-s fd       Int(10:0);
         Dcl-s flags    Uns(10:0);
         Dcl-s mode     Uns(10:0);
         Dcl-s Path     Char(256);
         Dcl-s NullPointer Pointer;

         Dcl-s UpdRec   Ind;

         Dcl-c Sql_Overwrite   const(16);
         Dcl-c Sql_Read        const(2);
         Dcl-c F_OK            const(0);     //Check access file
     D*                                            Reading & Writing
     D O_RDWR          C                   4
     D*                                            Create File if not exist
     D O_CREAT         C                   8
     D*                                            Exclusively create
     D O_EXCL          C                   16
     D*                                            Truncate File to 0 bytes
     D O_TRUNC         C                   64
     D*                                            Append to File
     D O_APPEND        C                   256
     D*                                            Convert text by
     d*code-page
     D O_CODEPAGE      C                   8388608
     D*                                            Open in text-mode
     D O_TEXTDATA      C                   16777216
     D*                                         owner authority
     D S_IRUSR         C                   256
     D S_IWUSR         C                   128
     D S_IXUSR         C                   64
     D S_IRWXU         C                   448
     D*                                         group authority
     D S_IRGRP         C                   32
     D S_IWGRP         C                   16
     D S_IXGRP         C                   8
     D S_IRWXG         C                   56
     D*                                         other people
     D S_IROTH         C                   4
     D S_IWOTH         C                   2
     D S_IXOTH         C                   1
     D S_IRWXO         C                   7


         Exec Sql
           Set Option Commit=*NONE, DatFmt=*ISO, Naming=*SYS;
        Dow (dspf.Exit = *Off);

          Dspf.Annulla = *Off;

          ExSr LoadSfl;
          Write Piede;
          Exfmt ARTFAQCTL;

            If (Dspf.Exit = *On);
              Iter;
            EndIf;
            If (Dspf.Insert = *On);
            //Dspf.ProtectArt = *On;
              ExSr InsFaq;
            //Dspf.ProtectArt = *Off;
            EndIf;

          If (Rrn > 0);
          ReadC ARTFAQSFL;
          Dow Not %EoF;
            If (FQVSCE = 'S');
              dspf.Protectfield = *On;
              ExSr DspFaq;
              dspf.Protectfield = *Off;
              FQVSCE = ' ';
            EndIf;
            If (FQVSCE = 'D');
              ExSr DltFaq;
              FQVSCE = ' ';
            EndIf;
            If (FQVSCE = 'M');
              UpdRec = *On;
              Exec Sql
                Select FQCODART, FQDOM, FQRIS, FQNDOC
                  Into :FQVINSART, :FQVINSDOM, :FQVINSRIS, :FQVINSPDO
                  from ARTFAQ01F
                  Where FQIDDOM = :FQVID and FQCODART = :FQVCODART;
              ExSr InsFaq;
              FQVSCE = ' ';
              UpdRec = *Off;
            EndIf;
            ReadC ARTFAQSFL;
          EndDo;
          EndIf;
        EndDo;
               Return;
               *Inlr = *on;
        //----------------------------------------------------------------------

        //----------------------------------------------------------------------
        BegSr LoadSfl;

          Dspf.SflDspCtl = *Off;
          Dspf.SflDsp    = *Off;
          Dspf.SflClr    = *On ;
          Write ARTFAQCTL;
          Dspf.SflDspCtl = *On;
          Dspf.SflDsp    = *On ;
          Dspf.SflClr    = *Off;

         
          Cmd = 'Select FQCODART, +
                        FQDESART, +
                        FQIDDOM, +
                        FQDOM, +
                        FQRIS, +
                        FQNDOC  +
                 from artfaq01f where +
                  (FQCODART like ' + Apice +
                  '%' + %Trim(FQVRICART) + '%' +
                  Apice + ' or ' + Apice + FQVRICART + Apice + ' = ' +
                  Apice + ' ' + Apice +
                  ') And (FQDESART like ' + Apice +
                  '%' + %Trim(FQVRICDES) + '%' +
                  Apice + ' or ' + Apice + FQVRICDES + Apice + ' = ' +
                  Apice + ' ' + Apice +
                  ') And (FQDOM like ' + Apice +
                  '%' + %Trim(FQVRICDOM) + '%' +
                  Apice + ' or ' + Apice + FQVRICDOM + Apice + ' = ' +
                  Apice + ' ' + Apice + ') +
                  Order by FQCODART, FQIDDOM';
          Exec Sql
            Prepare CURFAQ from :Cmd;
          Exec Sql
            Declare FAQ cursor for CURFAQ;

          Exec Sql
            Open FAQ;
          Exec Sql
            Fetch FAQ Into :Ds_Faq ;
          Rrn = 0;
          Dow SqlStt = '00000';
            Rrn = Rrn +1;
            FQVID     = Ds_Faq.FQIdDom;
            FQVCODART = Ds_Faq.FQCodArt;
            FQVDESART = Ds_Faq.FQDesArt;
            If (%Len(%Trim(Ds_Faq.FQDom)) > 30);
              FQVDOM = %Subst(Ds_Faq.FQDom:1:27) + '...';
            Else;
              FQVDOM = Ds_FAQ.FQDOM;
            EndIf;
            FQVDOCSFL = Ds_Faq.FQNDoc;
            Write ARTFAQSFL;
            Exec Sql
              Fetch FAQ Into :Ds_Faq;
          EndDo;
          Exec Sql
            Close FAQ;

          If (Rrn >= 1);
            Dspf.SflDsp = *On;
          Else;
            Dspf.SflClr = *On;
            Write ARTFAQCTL;
            Dspf.SflClr = *Off;
          EndIf;

        EndSr;
        //----------------------------------------------------------------------
        //----------------------------------------------------------------------
        BegSr InsFaq;

          Dow (Dspf.Annulla = *Off);
            ExFmt ARTFAQREC;
            If (Dspf.Annulla = *On);
             Clear ARTFAQREC;
             Iter;
            EndIf;

            If (FQVINSDOM = *blanks) Or
               (FQVINSRIS = *blanks);
              Dspf.Error = *On;
              FAQINSERR = 'Inserire domanda e risposta oppure annullare +
                          con F12';
              Write ARTFAQREC;
            Else;
              If (FQVINSART <> *blanks);
                Exec Sql
                 Select * Into :Ds_Art from ART00 where ARCOD = :FQVINSART;
                DoW (SqlStt <> '00000')  And (Dspf.Annulla = *Off);
                  ExFmt ARTFAQERR;
                  dspf.ErrDes = *off;
                  If (dspf.DspDesc = *On);
                    If (FQVERRDES = *blanks);
                      dspf.ErrDes = *on;
                      FQVERRMSG = 'Inserire la descrizione articolo.';
                      Iter;
                    Else;
                      leave;
                    EndIf;
                  EndIf;
                  If (Dspf.Annulla = *On) Or (FQVERRRIS = 'N');
                    UpdRec = *Off;
                    FQVERRRIS = 'N';
                    Dspf.Annulla = *On;
                    Iter;
                  EndIf;
                  If (FQVERRRIS = 'S');
                    dspf.DspDesc = *On;
                  EndIf;
                EndDo;
                If ((FQVERRRIS <> 'N') or (SqlStt = '00000'))
                   And (UpdRec = *Off);
                  Exec Sql
                  Select max(FQIDDOM) Into :Id from ARTFAQ01F
                    Where FQCODART = :FQVINSART;
                  Id = Id +1;
                  If (dspf.dspdesc = *On);
                    Desc = FQVERRDES;
                    dspf.dspdesc = *Off;
                  Else;
                    Desc = Ds_Art.ARDES1 + Ds_Art.ARDESX + Ds_Art.ARDES2;
                  EndIf;
                   Exec Sql
                    Insert Into ARTFAQ01F (FQCODART, FQDESART, FQIDDOM,
                                        FQDOM, FQRIS)
                              Values (:FQVINSART, :Desc, :Id, :FQVINSDOM,
                                      :FQVINSRIS);
                EndIf;
              If (UpdRec = *On);
                If (dspf.dspdesc = *On);
                  Desc = FQVERRDES;
                  dspf.dspdesc = *Off;
                Else;
                  Desc = Ds_Art.ARDES1 + Ds_Art.ARDESX + Ds_Art.ARDES2;
                EndIf;
                Exec Sql
                 Update ARTFAQ01F 
                 	set FQDESART = :Desc, 
                 		FQDOM 	 = :FQVINSDOM,
                        FQRIS 	 = :FQVINSRIS
                    where FQCODART = :FQVINSART and  FQIDDOM = :FQVID;
              EndIf ;
            Else;
              Dspf.Error = *On;
              FAQINSERR = 'Inserire codice articolo.';
              Write ARTFAQREC;
              Iter;
            EndIf;
              If (FQVINSDOC = 'S');
                ExSr InsDocumento;
              EndIf;

              Dspf.Annulla = *On;
            EndIf;
            Clear Id;
            Clear ARTFAQREC;
            Clear ARTFAQERR;
          EndDo;

        EndSr;
        //----------------------------------------------------------------------
        //----------------------------------------------------------------------
        BegSr DspFaq;

          //Check se esiste documento allegato

           If (FQVDOCSFL <> *Blanks);
                dspf.IndDoc = *On;
                FQVINSPDO = FQVDOCSFL ;
              Else;
                dspf.IndDoc = *Off;
                FQVINSPDO = 'NO';
           EndIf;
          dspf.ProtectArt   = *On;
          Dow (dspf.Annulla = *Off);
            Exec Sql
              Select FQCODART, 
              		 FQDOM, 
              		 FQRIS, 
              		 FQNDOC
                Into :FQVINSART, :FQVINSDOM, :FQVINSRIS, :FQVINSPDO
                from ARTFAQ01F
                Where FQIDDOM = :FQVID and FQCODART = :FQVCODART;

            Exfmt ARTFAQREC;
            Cmd='RMVLNK OBJLNK(' + Apice + '/FAQDOC/*' +
                 Apice + ')';
            Monitor;
              CmdExc (Cmd
                     :%Len(Cmd));
              On-Error;
            EndMon;
            If (Dspf.Annulla = *on);
              Iter;
            EndIf;

            If (FQVINSDOC = 'S');
              If (FQVINSPDO <> *blanks);
                ExSr DspDocumento;
              Else;
                ExSr InsDocumento;
              EndIf;
            EndIf;
          EndDo;
          dspf.ProtectArt   = *Off;
          Clear ARTFAQREC;
          Clear ARTFAQERR;

        EndSr;
        //----------------------------------------------------------------------
        //----------------------------------------------------------------------
        BegSr DltFaq;

            ExFmt ARTFAQDLT;
            If (FQVDLTRIS = 'S') And (dspf.Annulla = *Off);
              Exec Sql
                Delete from ARTFAQ01F where FQIDDOM = :FQVID and
                                            FQCODART = :FQVCODART;
            EndIf;

        EndSr;
        //----------------------------------------------------------------------
        //----------------------------------------------------------------------
        BegSr InsDocumento;

         dspf.ErrMsgDoc = *Off;
         Dow (Dspf.Annulla = *Off);
           ExFmt ARTFAQDOC;
           If (Dspf.Annulla = *On);
             Iter;
           EndIf;
           If (fd >= 0) And (Dspf.ErrMsgDoc = *On);
             Clear ARTFAQDOC;
             Dspf.ErrMsgDoc = *Off;
             Leave;
           EndIf;

           If (FQVDOCNOM <> *blanks) And (FQVDOCRIS = 'S');
             Path  = '/FAQDOC/' + %Trim(FQVDOCNOM);
             fd = access(%Trimr(Path): F_OK);
             If (fd < 0);
               dspf.ErrMsgDoc = *On;
               FQVERRMSG = 'File ' + %trim(FQVDOCNOM) + ' nella directory +
                            V:/non trovato.';
               Iter;
             EndIf;
             // Store an object into the blob table
             File_In_fo = SQL_READ;
             File_In_Name =   '/FAQDOC/' + %Trim(FQVDOCNOM);
             File_In_NL = %Len(%Trimr(File_In_Name));

             Exec Sql
               Update artfaq01f set FQDOC = Blob(:File_In), FQNDOC = :FQVDOCNOM
                 where FQCODART = :FQVINSART and FQIDDOM = :ID   ;
               If (SqlStt = '00000');
                 dspf.ErrMsgDoc = *On;
                 FQVERRMSG = 'Allegato inserito con successo.';
                 Cmd='RMVLNK OBJLNK(' + Apice + '/FAQDOC/' + %Trim(FQVDOCNOM) +
                      Apice + ')';
                 Monitor;
                  CmdExc(Cmd
                        :%Len(Cmd));
                 On-Error;
                 EndMon;
                 Iter;
               Else;
                 dspf.ErrMsgDoc = *On;
                 FQVERRMSG = 'Allegato non inserito verificare.';
                 Iter;
               EndIf;

           Else;
             dspf.ErrMsgDoc = *On;
             FQVERRMSG = 'Inserire nome documento e risposta alla domanda';
             Iter;
           EndIf;
         EndDo;
        EndSr;
        //----------------------------------------------------------------------
        //----------------------------------------------------------------------
        BegSr DspDocumento;
        // Restore an object from blob table in IFS
         File_Out_Fo = SQL_OVERWRITE;
         File_Out_Name = '/FAQDOC/' + %Trim(FQVINSPDO);
         File_Out_Nl = %Len(%Trimr(File_Out_Name));

             EXEC SQL   Select FQDOC Into :File_Out
                          From ARTFAQ01F where FQCODART = :FQVCODART
                          and  FQIDDOM = :FQVID;
         Cmd = 'STRPCO';
         Monitor;
           CmdExc (Cmd
                  :%len(Cmd));
           On-Error;
         EndMon;
         Cmd = 'STRPCCMD PCCMD('+
               Apice + 'START V:\' + %Trim(FQVINSPDO) + Apice + ') +
                PAUSE(*NO)';
         Monitor;
           CmdExc (Cmd
                  :%Len(Cmd));
           On-Error;
         EndMon;
        EndSr;
        //----------------------------------------------------------------------
