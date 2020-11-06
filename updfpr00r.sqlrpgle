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

        dcl-ds Ds_UpdFproc ExtName('FILLST00F') Qualified;
        end-ds;

        dcl-ds Ds_FPR_AllRec Qualified;
          AR_LibNom       char(10);
          AR_FilNom       char(10);
          AR_Campo        char(10);
          AR_TipoDato     char(10);
          AR_LungDato     Int(10:0);
          AR_NumScale     Int(10:0);
          AR_CritCam      char(1);
          AR_LibFldPr     char(10);
          AR_NomPgmFP     char(10);
          AR_MasCam       char(1);
          AR_MasNom       char(256);
          AR_NomUte       char(10);
          AR_DesUte       char(10);
          AR_regola       varchar(256);
        end-ds;

        dcl-ds p_UpdFproc LikeDs(Ds_UpdFproc);

        dcl-ds DsInput Qualified;
          p_LibNom       char(10);   //Nome Libreria
          p_FilNom       char(10);   //Nome File
          p_Campo        char(10);   //Nome campo del file
          p_TipoDato     char(10);   //Tipo di dato
          p_LungDato     Int(10:0);  //Lunghezza del dato
          //IN_NumScale     Int(10:0);  //Numeric scale - n� decimali
          p_CritCam      char(1);    //Campo crttografato: S=S� N=No
          p_LibPgmFP     char(10);   //Libreria del pgm della field proceure
          p_PgmFP        char(10);   //nome programma della field procedure
          p_MasCam       char(1);    //Campo mascherato: S=s� N=no
          p_MasNom       char(256);  //Nome della maschera
          p_NomUte       char(10);   //Nome utente autorizzato ai dati
          p_Error        Ind ;       //Indicatore di errore esecuzione
          p_ErrorMsg     char(256);   //Messaggio di errore
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


            UF_LIBNOM = p_UpdFproc.UF_LIBNOM;
            UF_FILNOM = p_UpdFproc.UF_FILNOM;
            UF_CAMPO  = p_UpdFproc.UF_CAMPO;
            UF_CRITCAM = p_UpdFproc.UF_CRITCAM;
            UF_LIBFLDP = p_UpdFproc.UF_LIBFLDPR;
            UF_PGMFLDP = p_UpdFproc.UF_NOMPGMFP;
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
               UF_ERRMSG = 'Libreria pgm e nome pgm per field procedure +
                            obbligatori';
               Dspf.MessageInd = *On;
               Iter;
            EndIf;
            If ((UF_LIBFLDP <> *blanks) Or (UF_PGMFLDP <> *blanks)) And
               (UF_CRITCAM = 'N');
               UF_ERRMSG = 'Per un campo NON CRITTOGRAFATO, +
                            libreria pgm e nome pgm per field procedure +
                            devono essere *blank.';
               Dspf.MessageInd = *On;
               Iter;
            EndIf;
            If (UF_LIBFLDP <> *blanks) and (UF_PGMFLDP <> *blanks);
              w_LibFile = %Trim(UF_LIBFLDP) + '/' + %Trim(UF_PGMFLDP);

              pCheckObj(w_LibFile
                        :Resp);
              If (Resp = '1');
                UF_ERRMSG = ExceptionType+ ExceptionNum + ' ' + ExceptionData;
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
              Exec Sql
               Update FILLST00F set FL_CRITCAM = :UF_CRITCAM,
                                  FLDPRLPGM  = :UF_LIBFLDP,
                                  FLDPRCPGM  = :UF_PGMFLDP
                            where FL_LIB  = :UF_LIBNOM and
                                  FL_FILE = :UF_FILNOM and
                                  FL_CAMPO = :p_UpdFproc.UF_CAMPO;
              If (SqlStt <> '00000');
                UF_ERRMSG = 'Update DB terminato con errori, +
                ALTER TABLE per  FIELD PROCEDURE non eseguito.';
                Dspf.MessageInd = *ON;
              EndIf;
              If (Dspf.MessageInd = *Off);
                DsInput.p_LibNom = %Trim(UF_LIBNOM);
                DsInput.p_FilNom = %Trim(UF_FILNOM);
                DsInput.p_Campo  = %Trim(UF_CAMPO);
                DsInput.p_CritCam = %Trim(UF_CRITCAM);
                If (UF_CRITCAM = 'S');
                   CheckDimFile(DsInput.p_LibNom
                                :DsInput.p_FilNom
                                :DsInput.p_Campo
                                :DsInput.p_CritCam
                                :DsInput.p_LibPgmFP
                                :DsInput.p_PgmFP
                                :DsInput.p_Error
                                :DsInput.p_ErrorMsg);
                EndIf;
                If (DsInput.p_CritCam = 'W');
                  Exec Sql
                   Update FILLST00F set FL_CRITCAM = :DsInput.p_CritCam
                            where FL_LIB  = :UF_LIBNOM and
                                  FL_FILE = :UF_FILNOM and
                                  FL_CAMPO = :UF_CAMPO;
                  If (SqlStt <> '00000');
                     DsInput.p_Error = *On;
                     DsInput.p_ErrorMsg = 'UPDATE FILLST00F +
                                  terminato con errori. Verificare.';
                  EndIf;
                Else;
                  UpdFprocMask(DsInput) ;
                EndIf;
                If (DsInput.p_Error <> *Off);
                  UF_ERRMSG = DsInput.p_ErrorMsg;
                  Dspf.MessageInd = *ON;
                EndIf;
                If ((SqlStt <> '00000') or (DsInput.p_Error = *On)) And
                   (Dspf.MessageInd = *Off);
                   UF_ERRMSG = 'Alter table per drop field procedure +
                   terminato con errori. Verificare.';
                   Dspf.MessageInd = *ON;
                Else;
                   p_UpdFProc.UF_Message = 'Update e alter table +
                   per field procedure  terminati correttamente.';
                   p_UpdFproc.UF_MessageInd = *ON;
                EndIf;
           EndiF;
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
                           COALESCE(C.NUMERIC_SCALE, 0),
                       CASE
                         WHEN C.SYSTEM_COLUMN_NAME = :UF_CAMPO THEN :UF_CRITCAM
                         WHEN COALESCE(F.FIELD_PROC, ' ') <> ' ' THEN 'S'
                         ELSE 'N'
                       END AS CRITCAM,
                           CASE
                         WHEN C.SYSTEM_COLUMN_NAME = :UF_CAMPO THEN :UF_LIBFLDP
                         WHEN COALESCE(F.FIELD_PROC, ' ') <> ' ' THEN
                                  LIBSST(F.FIELD_PROC)
                         ELSE ' '
                       END LIB_PGM_FIELDPROC,
                       CASE
                         WHEN C.SYSTEM_COLUMN_NAME = :UF_CAMPO THEN :UF_PGMFLDP
                         WHEN COALESCE(F.FIELD_PROC, ' ') <> ' ' THEN
                                  FILSST(F.FIELD_PROC)
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
                  Ds_FPR_AllRec.AR_NomUte = p_NomeUtente;
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
                  PRCERRMSG='Insert DB terminato con errori, ALTER TABLE per +
                             FIELD PROCEDURE non eseguito.';
                  Dspf.MessageInd = *ON;
                  Iter ;
                EndIf;
              EndDo;
              If (UF_CRITCAM = 'N') And (Dspf.MessageInd = *Off);
                DsInput.p_LibNom = %Trim(UF_LIBNOM);
                DsInput.p_FilNom = %Trim(UF_FILNOM);
                DsInput.p_Campo  = %Trim(UF_CAMPO);
                DsInput.p_CritCam = %Trim(UF_CRITCAM);
                UpdFprocMask(DsInput) ;
              Else;
              If (Dspf.MessageInd = *Off);
              EXEC SQL
                DECLARE ALTTABCSR CURSOR FOR
                  SELECT FL.FL_LIB, FL.FL_FILE, FL.FL_CAMPO, FL.FLDPRLPGM,
                         FLDPRCPGM
                              FROM FILLST00F FL LEFT JOIN QSYS2.SYSFIELDS FI
                                ON FL.FL_LIB = FI.SYSTEM_TABLE_SCHEMA AND
                                   FL.FL_FILE = FI.SYSTEM_TABLE_NAME  AND
                                   FL.FL_CAMPO = FI.SYSTEM_COLUMN_NAME
                                   WHERE FL.FL_LIB     = :UF_LIBNOM AND
                                         FL.FL_FILE    = :UF_FILNOM AND
                                         FL.FL_CRITCAM = 'S' AND
                                         FI.FIELD_PROC IS NULL
                                  GROUP BY FL.FL_LIB, FL.FL_FILE, FL.FL_CAMPO,
                                           FL.FLDPRLPGM, FL.FLDPRCPGM;
              EXEC SQL
                OPEN ALTTABCSR;
              EXEC SQL
                FETCH ALTTABCSR INTO :DsInput.p_LibNom ,
                                     :DsInput.p_FilNom ,
                                     :DsInput.p_Campo ,
                                     :DsInput.p_LibPgmFP ,
                                     :DsInput.p_PgmFP    ;
                 //DsInput.p_CritCam = 'S';
                 Dow (SqlStt = '00000') or (SqlStt = '01004');
                   CheckDimFile(DsInput.p_LibNom
                                :DsInput.p_FilNom
                                :DsInput.p_Campo
                                :DsInput.p_CritCam
                                :DsInput.p_LibPgmFP
                                :DsInput.p_PgmFP
                                :DsInput.p_Error
                                :DsInput.p_ErrorMsg);
                   If (DsInput.p_CritCam = 'W');
                     Exec Sql
                       UPDATE FILLST00F SET FL_CRITCAM = 'W'
                        WHERE FL_LIB   =  :DsInput.p_LibNom  AND
                              FL_FILE  =  :DsInput.p_FilNom  AND
                              FL_CAMPO =  :DsInput.p_Campo ;
                   Else;
                     UpdFprocMask(DsInput);
                   EndIf;

                   If (DsInput.p_Error = *On);
                      UF_ERRMSG = DsInput.p_ErrorMsg;
                      Dspf.MessageInd = *ON;
                      Leave;
                   EndIf;
                   EXEC SQL
                     FETCH ALTTABCSR INTO :DsInput.p_LibNom ,
                                          :DsInput.p_FilNom ,
                                          :DsInput.p_Campo ,
                                          :DsInput.p_LibPgmFP ,
                                          :DsInput.p_PgmFP    ;
                 EndDo;

               If (Dspf.MessageInd = *On);
                 p_UpdFproc.UF_Message='Update e alter table +
                      per field procedure  terminato correttamente.';
                 p_UpdFproc.UF_MessageInd = *ON;
               EndIf;

              Else;
                 p_UpdFproc.UF_Message='Update e alter table +
                   per field procedure  terminato con errori. Verificare.';
                 p_UpdFproc.UF_MessageInd = *ON;
              EndIf;
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


