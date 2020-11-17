        //ctl-opt dftactgrp(*no) Option(*nodebugio);
        dcl-f cfgdsp00v workstn IndDs(Dspf) ;

        Dcl-pr UpdFproc;
          p_UpdFproc LikeDs(Ds_UpdFproc);
        End-pr;
        dcl-pr CmdExec ExtPgm('QCMDEXC');
          Cmd Char(256) options(*varsize) const;
          Len Packed(15:5) const;
        end-pr;
        Dcl-Pr pCheckObj;
          p_LibFile char(21);
          p_Resp    char(1) ;
        End-Pr;
        Dcl-pr FindAutUser;
          SourceString varChar(256);
          NomeUtente   Char(10);
          p_Posi       Zoned(5:0);
          EndProc      Ind;
        End-pr;
        Dcl-Pr UpdateAlter;
             p_UpdFProc  LikeDs(Ds_UpdFproc);
             MsgInd      Ind;
        End-Pr;
        Dcl-Pr InsertAlter;
             p_UpdFProc  LikeDs(Ds_UpdFproc);
             MsgInd      Ind;
        End-Pr;
        dcl-pr UpdFprocMask;
          p_DsInput LikeDs(DsInput);
        end-pr;
        Dcl-pr CheckDimFile ExtPgm('DIMFIL00C');
            p_LibNom    char(10);
            p_FilNom    char(10);
            p_Campo     char(10);
            p_CritCam   char(1);
            p_LibPgmFP  char(10);
            p_PgmFP     char(10);
            p_Error     Ind;
            p_ErrorMsg  char(80);
        End-pr;

        Dcl-ds Dspf qualified ;
             Annulla      ind pos(12);
             MessageInd   ind pos(90);
        End-Ds;

        dcl-ds PgmStat PSDS ;
             ExceptionType char(3) pos(40) ;
             ExceptionNum  char(4) pos(43) ;
             ExceptionData char(80) pos(91) ;
        end-ds;

        dcl-ds Ds_FilLst ExtName('FILLST00F') qualified;
        end-ds;

        dcl-ds Ds_UpdFproc ExtName('FILLST00F') qualified Prefix(UF_:3);
            UF_Message      char (7);
            UF_MessageInd   ind;
        end-ds;
        dcl-ds Ds_FPR_AllRec ExtName('FILLST00F') qualified Prefix(AR_:3);
          AR_regola       varchar(256);
        end-ds;

        dcl-ds DsInput ExtName('FILLST00F') qualified Prefix(In_:3);
          In_Error        Ind ;       //Indicatore di errore esecuzione
          In_ErrorMsg     char(256);   //Messaggio di errore
        end-ds;
        dcl-s Counter      Zoned(4:0);
        dcl-s Cmd          char(256);
        dcl-s w_LibFile    char(21);
        dcl-s Resp         char(1);
        dcl-s PosI         zoned(5:0);
        dcl-s Fine         Ind;
        dcl-s p_NomeUtente char(10);
        dcl-s p_Posi       Zoned(5:0);
        dcl-s RetCod       Ind;

        *InLr = *On;

        Dcl-Proc UpdFProc export;
        Dcl-pi UpdFproc;
          p_UpdFproc LikeDs(Ds_UpdFproc);
        End-pi;


            UF_LIBNOM = p_UpdFproc.UF_LIB   ;
            UF_FILNOM = p_UpdFproc.UF_FILE;
            UF_CAMPO  = p_UpdFproc.UF_CAMPO;
            UF_CRITCAM = p_UpdFproc.UF_CRITCAM;
            UF_LIBFLDP = p_UpdFproc.UF_FPRLPGM;
            UF_PGMFLDP = p_UpdFproc.UF_FPRPGM;
            Dspf.Annulla = *Off;
            Dspf.MessageInd = *Off;
          DoW (Dspf.Annulla = *Off And p_UpdFproc.UF_MessageInd = *Off);
            Exfmt FPRCUPD;
            Dspf.MessageInd = *Off;
            If (Dspf.Annulla = *On);
              Leave;
            EndIf;
            Resp = '0';
            If ((UF_LIBFLDP = *blanks) Or (UF_PGMFLDP = *blanks)) And
                (UF_CRITCAM = 'S');
               MSGID = 'ENC0001';
               Dspf.MessageInd = *On;
                   Iter;
            EndIf;
            If ((UF_LIBFLDP <> *blanks) Or (UF_PGMFLDP <> *blanks)) And
               (UF_CRITCAM = 'N');
               MSGID = 'ENC0002';
               Dspf.MessageInd = *On;
               Iter;
            EndIf;
            If (UF_LIBFLDP <> *blanks) and (UF_PGMFLDP <> *blanks);
              w_LibFile = %Trim(UF_LIBFLDP) + '/' + %Trim(UF_PGMFLDP);

              pCheckObj(w_LibFile
                        :Resp);
              If (Resp = '1');
                MSGID = 'ENC0023';
                Dspf.MessageInd = *On;
                Iter;
              EndIf;
            EndIf;
            Exec Sql
              Select count(*) Into :Counter
                from FILLST00F
                where FL_LIB    = :UF_LIBNOM and
                      FL_FILE   = :UF_FILNOM ;
                     // FL_CAMPO  = :UF_CAMPO;
            If (Counter > 0);
              UpdateAlter(p_UpdFProc
                          :Dspf.MessageInd);
            Else;
              InsertAlter(p_UpdFProc
                          :Dspf.MessageInd);
            EndIF;

          EndDo;
        End-Proc;

        Dcl-Proc UpdateAlter;
        Dcl-Pi UpdateALter;
             p_UpdFProc  LikeDs(Ds_UpdFproc);
             MsgInd      Ind;
        End-Pi;
                DsInput.In_Lib  = %Trim(UF_LIBNOM);
                DsInput.In_File = %Trim(UF_FILNOM);
                DsInput.In_Campo  = %Trim(UF_CAMPO);
                DsInput.In_CritCam = %Trim(UF_CRITCAM);
                DsInput.In_FprLPgm  = %Trim(UF_LIBFLDP);
                DsInput.In_FprPgm = %Trim(UF_PGMFLDP);
                CheckDimFile(DsInput.In_Lib
                            :DsInput.In_File
                            :DsInput.In_Campo
                            :DsInput.In_CritCam
                            :DsInput.In_FprLPgm
                            :DsInput.In_FprPgm
                            :DsInput.In_Error
                            :DsInput.In_ErrorMsg);
                If (DsInput.In_CritCam <> 'W');
                  UpdFprocMask(DsInput) ;
                EndIf;

                If (DsInput.In_Error = *off);
                  Exec Sql
                   Update FILLST00F set FL_CRITCAM = :DsInput.In_CritCam
                            where FL_LIB  = :UF_LIBNOM and
                                  FL_FILE = :UF_FILNOM and
                                  FL_CAMPO = :UF_CAMPO;
                EndIf;

                If ((SqlStt <> '00000') or (DsInput.In_Error = *On)) And
                   (Dspf.MessageInd = *Off);
                   p_UpdFproc.UF_Message = 'ENC0005';
                   Dspf.MessageInd = *ON;
                Else;
                   p_UpdFproc.UF_Message = 'ENC0006';
                   p_UpdFproc.UF_MessageInd = *ON;
                EndIf;
        End-Proc;

        Dcl-Proc InsertAlter;
        Dcl-Pi InsertAlter;
             p_UpdFProc  LikeDs(Ds_UpdFproc);
             MsgInd      Ind;
        End-Pi;
              Exec Sql
                DECLARE INS_ALLREC CURSOR FOR
                SELECT C.SYSTEM_TABLE_SCHEMA, C.SYSTEM_TABLE_NAME,
                           C.SYSTEM_COLUMN_NAME, C.DATA_TYPE, C."LENGTH",
                       CASE
                         WHEN C.SYSTEM_COLUMN_NAME = :UF_CAMPO THEN :UF_CRITCAM
                         WHEN COALESCE(F.FIELD_PROC, ' ') <> ' ' THEN 'S'
                         ELSE 'N'
                       END AS CRITCAM,
                           CASE
                         WHEN C.SYSTEM_COLUMN_NAME = :UF_CAMPO
                         THEN :UF_LIBFLDP
                         WHEN COALESCE(F.FIELD_PROC, ' ') <> ' '
                         THEN LIBSST(F.FIELD_PROC)
                         ELSE ' '
                       END LIB_PGM_FIELDPROC,
                       CASE
                         WHEN C.SYSTEM_COLUMN_NAME = :UF_CAMPO
                         THEN :UF_PGMFLDP
                         WHEN COALESCE(F.FIELD_PROC, ' ') <> ' '
                         THEN FILSST(F.FIELD_PROC)
                         ELSE ' '
                       END NOME_PGM_FIELDPROC,
                       CASE
                         WHEN COALESCE(CT.RULETEXT, ' ') <> ' '
                         THEN 'S'
                         ELSE 'N'
                       END CAMPO_MSACHERATO,
                       CASE
                         WHEN COALESCE(CT.RCAC_NAME, ' ') <> ' '
                         THEN CT.RCAC_NAME
                         ELSE ' '
                       END AS NOME_MASCHERA,
                           ' ' AS NOME_UTENTE,
                           ' ' AS DESC_UTENTE,
                           COALESCE(CT.RULETEXT, ' ')
                    FROM QSYS2.SYSCOLUMNS C LEFT JOIN QSYS2.SYSFIELDS F ON
                              C.SYSTEM_TABLE_SCHEMA = F.SYSTEM_TABLE_SCHEMA AND
                              C.SYSTEM_TABLE_NAME   = F.SYSTEM_TABLE_NAME   AND
                              C.SYSTEM_COLUMN_NAME  = F.SYSTEM_COLUMN_NAME
                                            LEFT JOIN QSYS2.SYSCONTROLS CT ON
                              C.SYSTEM_TABLE_SCHEMA = CT.SYSTEM_TABLE_SCHEMA AND
                              C.SYSTEM_TABLE_NAME   = CT.SYSTEM_TABLE_NAME   AND
                              C.SYSTEM_COLUMN_NAME  = CT.SYSTEM_COLUMN_NAME

                    WHERE (C.SYSTEM_TABLE_SCHEMA = :UF_LIBNOM)
                      AND (C.SYSTEM_TABLE_NAME = :UF_FILNOM);
              EXEC SQL
                OPEN INS_ALLREC;
              EXEC SQL
                FETCH INS_ALLREC INTO :Ds_FPR_AllRec;
              DoW (SqlStt = '00000') or (SqlStt = '01004');
                Fine = *Off;
                p_PosI = 1;
                DoW (Fine = *Off);
                  FindAutUser(Ds_FPR_AllRec.AR_Regola
                            :p_NomeUtente
                            :p_PosI
                            :Fine);
                  If (Fine = *On);
                    Leave;
                  EndIf;
                  Ds_FPR_AllRec.AR_Utente = p_NomeUtente;
                  Ds_FilLst = Ds_FPR_AllRec;
                  Clear Ds_FilLSt.FL_DESUTE;
                  EXEC SQL
                    INSERT INTO FILLST00F
                                VALUES(:DS_FilLst);
                EndDo;
                If (p_PosI = 1);
                  Ds_FilLst = Ds_FPR_AllRec;
                  EXEC SQL
                    INSERT INTO FILLST00F
                                VALUES(:DS_FilLst);
                EndIf;

                If (SqlStt = '00000');
                  EXEC SQL
                    FETCH INS_ALLREC INTO :Ds_FPR_AllRec;
                Else;
                  MSGID = 'ENC0007';
                  Dspf.MessageInd = *ON;
                  Leave ;
                EndIf;
              EndDo;
              If (UF_CRITCAM = 'N') And (Dspf.MessageInd = *Off);
                DsInput.In_Lib  = %Trim(UF_LIBNOM);
                DsInput.In_File = %Trim(UF_FILNOM);
                DsInput.In_Campo  = %Trim(UF_CAMPO);
                DsInput.In_CritCam = %Trim(UF_CRITCAM);
                UpdFprocMask(DsInput) ;
              Else;
              If (Dspf.MessageInd = *Off);
              EXEC SQL
                DECLARE ALTTABCSR CURSOR FOR
                  SELECT FL.FL_LIB, FL.FL_FILE, FL.FL_CAMPO, FL.FL_CRITCAM,
                         FL.FL_FPRLPGM, FL_FPRPGM
                              FROM FILLST00F FL LEFT JOIN QSYS2.SYSFIELDS FI
                                ON FL.FL_LIB = FI.SYSTEM_TABLE_SCHEMA AND
                                   FL.FL_FILE = FI.SYSTEM_TABLE_NAME  AND
                                   FL.FL_CAMPO = FI.SYSTEM_COLUMN_NAME
                                   WHERE FL.FL_LIB     = :UF_LIBNOM AND
                                         FL.FL_FILE    = :UF_FILNOM AND
                                         FL.FL_CRITCAM = 'S' AND
                                         FI.FIELD_PROC IS NULL
                                  GROUP BY FL.FL_LIB, FL.FL_FILE, FL.FL_CAMPO,
                                           FL.FL_CRITCAM, FL.FL_FPRLPGM,
                                           FL.FL_FPRPGM;
              EXEC SQL
                OPEN ALTTABCSR;
              EXEC SQL
                FETCH ALTTABCSR INTO :DsInput.In_Lib ,
                                     :DsInput.In_File ,
                                     :DsInput.In_Campo ,
                                     :DsInput.In_CritCam,
                                     :DsInput.In_FprLPgm ,
                                     :DsInput.In_FprPgm    ;
                 //DsInput.In_CritCam = 'S';
                 Dow (SqlStt = '00000') or (SqlStt = '01004');
                   CheckDimFile(DsInput.In_Lib
                                :DsInput.In_File
                                :DsInput.In_Campo
                                :DsInput.In_CritCam
                                :DsInput.In_FprLPgm
                                :DsInput.In_FprPgm
                                :DsInput.In_Error
                                :DsInput.In_ErrorMsg);
                   If (DsInput.In_CritCam = 'W');
                     Exec Sql
                       UPDATE FILLST00F SET FL_CRITCAM = 'W'
                        WHERE FL_LIB   =  :DsInput.In_Lib  AND
                              FL_FILE  =  :DsInput.In_File  AND
                              FL_CAMPO =  :DsInput.In_Campo ;
                   Else;
                     UpdFprocMask(DsInput);
                   EndIf;

                   If (DsInput.In_Error = *On);
                      MSGID = DsInput.In_ErrorMsg;
                      Dspf.MessageInd = *ON;
                      Leave;
                   EndIf;
                   EXEC SQL
                     FETCH ALTTABCSR INTO :DsInput.In_Lib  ,
                                          :DsInput.In_File ,
                                          :DsInput.In_Campo ,
                                          :DsInput.In_FprLPgm ,
                                          :DsInput.In_FprPgm    ;
                 EndDo;
              EndIf;

             EndIf;

             If (Dspf.MessageInd = *On);
                 p_UpdFproc.UF_Message='ENC0009';
                 p_UpdFproc.UF_MessageInd = *ON;
             Else;
                 p_UpdFproc.UF_Message='ENC0008';
                 p_UpdFproc.UF_MessageInd = *ON;
             EndIf;




        End-Proc;

        Dcl-Proc pCheckObj;
        Dcl-Pi pCheckObj;
           p_LibFile char(21);
           p_Resp   char(1) ;
        End-Pi;
           Monitor;
             Cmd = 'CHKOBJ ' + %Trim(p_LibFile) + ' OBJTYPE(*PGM)';
             CmdExec(Cmd
                    :%Len(Cmd));
           On-Error;
             p_Resp = '1';
           EndMon;
        End-Proc;


