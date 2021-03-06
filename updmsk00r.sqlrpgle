        dcl-f cfgdsp00v workstn IndDs(Dspf) ;

        dcl-pr UpdMask;
          p_UpdMask LikeDs(Ds_UpdMask);
        end-pr;

        Dcl-pr FindAutUser;
          SourceString varChar(256);
          NomeUtente   Char(10);
          p_Posi       Zoned(5:0);
          EndProc      Ind;
        End-pr;
        Dcl-Pr UpdateAlter;
             p_UpdMask  LikeDs(Ds_UpdMask);
             MsgInd Ind;
        End-Pr;
        Dcl-Pr RemovetAlter;
             p_UpdMask  LikeDs(Ds_UpdMask);
             MsgInd Ind;
        End-Pr;
        dcl-pr UpdFprocMask;
          p_DsInput LikeDs(DsInput);
        end-pr;
        Dcl-Pr pCheckObj;
          p_NomObj  char(10) const;
          p_TipObj  char(10) const;
          p_Resp    char(1) ;
        End-Pr;
        dcl-pr CmdExec ExtPgm('QCMDEXC');
          Cmd Char(256) options(*varsize) const;
          Len Packed(15:5) const;
        end-pr;
        Dcl-pr ElencoCampi;
          p_NomeLibreria char(10);
          p_NomeFile     char(10);
          p_NomeCampo    char(10);
          p_TipoDato     char(10);
          p_LunDat       packed(10:0);
          p_MasNom       char(35);
        end-pr;

        Dcl-ds Dspf qualified ;
             EleCamInd    ind pos(04);
             InsertInd    ind pos(06);
             Annulla      ind pos(12);
             CampoOK      ind pos(50);
             MasNomOK     ind pos(60);
             UtenteInd    ind pos(70);
             MessageInd   ind pos(90);
        End-Ds;
        dcl-ds Ds_UpdMask ExtName('FILLST00F') qualified Prefix(UM_:3);
          UM_Message     char(125);
          UM_InsertInd    ind;
          UM_MessageInd   ind  inz('0');
        end-ds;
        dcl-ds Ds_CrtMask qualified;
           M_NomUte    char(10)  ;
           M_TipDat    char(10);
           M_Lunghezza bindec(9);
           M_NumSca    bindec(9);
        end-ds;
        dcl-ds Ds_FilLst ExtName('FILLST00F') qualified;
        end-ds;
        dcl-ds Ds_MSK_AllRec ExtName('FILLST00F') qualified Prefix(AR_:3);
          AR_regola       varchar(256);
        end-ds;

        dcl-ds DsInput ExtName('FILLST00F') qualified Prefix(IN_:3);
          In_Error        Ind ;       //Indicatore di errore esecuzione
          In_ErrorMsg     char(256);   //Messaggio di errore
        end-ds;
        dcl-ds p_UpdMask LikeDs(Ds_UpdMask);

        dcl-s Counter zoned(4:0);
        dcl-s wRetval char(256);
        dcl-s Cmd     char(1024);
        dcl-s i       zoned(3:0);
        dcl-s Fine         Ind;
        dcl-s p_NomeUtente char(10);
        dcl-s p_Posi       Zoned(5:0);
        dcl-s p_CheckRule       Ind;
        dcl-s p_Resp      Ind;
        dcl-s CntUser   Zoned(4:0);

        Dcl-Proc UpdMask export;
        Dcl-pi UpdMask;
          p_UpdMask LikeDs(Ds_UpdMask);
        end-pi;
            clear Dspf;
            UM_LIBNOM = p_UpdMask.UM_Lib;
            UM_FILNOM = p_UpdMask.UM_File;
            UM_CAMPO  = p_UpdMask.UM_Campo;
            UM_MASCAM = p_UpdMask.UM_MasCam;
            UM_MASNOM = p_UpdMask.UM_MasNom;
            UM_NOMUTE = p_UpdMask.UM_Utente;
            //Dspf.InsertInd = p_UpdMask.UM_InsertInd;
            Dspf.Annulla = *off;
          DoW (Dspf.Annulla = *Off And p_UpdMask.UM_MessageInd = *Off);
            Dspf.InsertInd = p_UpdMask.UM_InsertInd;
            If (UM_CAMPO <> *blanks);
                Dspf.CampoOK = *On;
            EndIf;
            If (UM_MASNOM <> *blanks);
               Dspf.MasNomOK = *on;
            EndIf;

            If (UM_NOMUTE <> *blanks);
               Dspf.UtenteInd = *On;
            EndIf;

            Exfmt MSKUPD;
            P_UpdMask.UM_MasCam = UM_MASCAM;
            Dspf.MessageInd = *Off;
            If (Dspf.Annulla = *On);
              leave;
            EndIf;
            If (UM_MASCAM <> 'S') And (UM_MASCAM <> 'N');
                MSGID = 'MSK0010';
                Dspf.MessageInd = *On;
                Iter;
            EndIf;
            If (UM_CAMPO <> *blanks) And (UM_MASNOM = *blanks);
              Exec Sql
                 SELECT COALESCE(FL.FL_MASNOM, ' '),
                    SC.DATA_TYPE, SC.LENGTH
                    INTO :p_UpdMask.UM_MasNom,
                         :p_UpdMask.UM_TipDat,
                         :p_UpdMask.UM_LunDat
                   FROM FILLST00F FL RIGHT JOIN QSYS2/SYSCOLUMNS SC
                   ON FL.FL_LIB = SC.SYSTEM_TABLE_SCHEMA AND
                      FL.FL_FILE = SC.SYSTEM_TABLE_NAME AND
                      FL.FL_CAMPO = SC.SYSTEM_COLUMN_NAME
                  WHERE SC.SYSTEM_TABLE_SCHEMA = :UM_LIBNOM
                    AND SC.SYSTEM_TABLE_NAME   = :UM_FILNOM
                    AND SC.SYSTEM_COLUMN_NAME = :UM_CAMPO
                    FETCH FIRST ROW ONLY;
                    If (SqlStt <> '00000');
                        MSGID = 'MSK0009';
                        Dspf.MessageInd = *On;
                        Iter;
                    EndIf;
                    If (p_UpdMask.Um_MasNom <> ' ');
                      UM_MASNOM = %SubSt(p_UpdMask.Um_MasNom:1:35) ;
                      Dspf.MasNomOk = *On;

                    EndIf;
              p_UpdMask.Um_Campo = UM_CAMPO;
              Dspf.CampoOk = *On;
              Iter;
            EndIf;
            If (p_UpdMask.UM_InsertInd = *On) And (Dspf.CampoOk = *Off);
               If (Dspf.EleCamInd = *On);
                 ElencoCampi(UM_LIBNOM
                            :UM_FILNOM
                            :UM_CAMPO
                            :UM_TIPODAT
                            :UM_LUNDAT
                            :UM_MASNOM);
                 If (UM_CAMPO <> *blanks);
                    Dspf.CampoOk = *On;
                    p_UpdMask.UM_TipDat = UM_TIPODAT;
                    p_UpdMask.UM_LunDat = UM_LUNDAT;
                    p_UpdMask.Um_Campo  = UM_CAMPO;
                    p_UpdMask.Um_MasNom  = UM_MASNOM;
                    If (UM_MASNOM <> *Blanks);
                        Dspf.MasNomOK = *On;
                    EndIf;
                 EndIf;
                 Iter;
               EndIf;
               If (UM_CAMPO = *blanks);
                 MSGID = 'MSK0001';
                 Dspf.MessageInd = *On;
                 Iter;
               EndIf;

            Else;

               If (UM_MASCAM = 'N') And (Dspf.InsertInd = *On);
                 MSGID = 'MSK0002';
                 Dspf.MessageInd = *On;
                 Iter;
               EndIf;

               If (UM_MASNOM = *blanks) And (Dspf.MasNomOk = *On) ;
                 MSGID = 'MSK0003';
                 Dspf.MessageInd = *On;
                 Iter;
               Else;
                 If (Dspf.MasNomOk = *Off) And (UM_MASNOM <> *blanks);
                   Dspf.MasNomOk = *On;
                   p_UpdMask.UM_MasNom = UM_MASNOM;
                   Iter;
                 EndIf;
               EndIf;
                  If (UM_NOMUTE <> *blanks) And (UM_MASNOM <> *blanks) ;

                    pCheckObj(UM_NOMUTE
                             :'*USRPRF'
                             :p_Resp);
                    If (p_Resp = '1');
                       MSGID = 'MSK0004';
                       Dspf.MessageInd = *On;
                       Iter;
                    Else;
                       p_UpdMask.UM_Utente = UM_NOMUTE;
                       If (UM_MASCAM = 'S');
                         Exec Sql
                           SELECT * INTO :Ds_FilLst
                            FROM FILLST00F
                           WHERE FL_LIB = :UM_LIBNOM
                            AND FL_FILE = :UM_FILNOM
                            AND FL_CAMPO = :UM_CAMPO
                            AND FL_UTENTE = :UM_NOMUTE;
                         If (SqlStt = '00000');
                           MSGID = 'MSK0005';
                           Dspf.MessageInd = *On;
                           Dspf.UtenteInd = *Off;
                           Iter;
                         EndIf;
                       EndIf;
                    EndIf;
                  Else;
                        If (UM_MASNOM <> ' ');
                            MSGID = 'MSK0008';
                            Dspf.MessageInd = *On;
                        EndIf;
                        Iter;
                  EndIf;


            If (p_UpdMask.UM_InsertInd = *Off);
              RemoveAlter(p_UpdMask
                         :Dspf.MessageInd   );
            Else;
              InsertAlter(p_UpdMask
                         :Dspf.MessageInd   );
            EndIF;

            EndIf;

         EndDo;

          *Inlr = *ON;

        End-Proc;

        Dcl-Proc RemoveAlter;
        Dcl-Pi RemoveAlter;
          p_UpdMask  LikeDs(Ds_UpdMask);
          MsgInd      Ind;
        End-Pi;

                DsInput.In_Lib = UM_LIBNOM;
                DsInput.In_File = UM_FILNOM;
                DsInput.In_Campo  = UM_CAMPO ;
                DsInput.In_MasCam  = UM_MASCAM;
                DsInput.In_MasNom  = UM_MASNOM ;
                DsInput.In_Utente  = UM_NOMUTE;
                DsInput.In_TipDat  = p_UpdMask.UM_TipDat;
                DsInput.In_LunDat  = p_UpdMask.UM_LunDat;

                Exec Sql
                SELECT COUNT(*) INTO :Counter
                  FROM FILLST00F WHERE FL_LIB = :UM_LIBNOM
                                  AND FL_FILE = :UM_FILNOM;
                If (Counter > 0);

                UpdFprocMask(DsInput);

                If (DsInput.IN_ErrorMsg <> 'MSK0007');
                  UM_ERRMSG = DsInput.IN_ErrorMsg;
                  p_UpdMask.UM_MessageInd = *On;
                Else;
                  If (UM_MASCAM = 'S');
                    Exec Sql
                    UPDATE FILLST00F SET FL_MASCAM = :UM_MASCAM,
                                         FL_MASNOM = :UM_MASNOM,
                                         FL_UTENTE = :UM_NOMUTE
                                   WHERE FL_LIB = :UM_LIBNOM
                                     AND FL_FILE = :UM_FILNOM
                                     AND FL_CAMPO = :UM_CAMPO;
                  Else;
                    //Verifico se ultimo utente
                    Exec Sql
                        SELECT COUNT(*) INTO :Counter
                          FROM FILLST00F
                         WHERE FL_LIB = :UM_LIBNOM
                           AND FL_FILE = :UM_FILNOM
                           AND FL_CAMPO = :UM_CAMPO;
                    If (Counter > 1);
                        Exec Sql
                          DELETE FROM FILLST00F WHERE FL_LIB = :UM_LIBNOM
                                           AND FL_FILE  = :UM_FILNOM
                                           AND FL_CAMPO = :UM_CAMPO
                                           AND FL_UTENTE = :UM_NOMUTE;
                    Else;
                        Exec Sql
                          UPDATE FILLST00F SET FL_MASCAM = 'N',
                                               FL_MASNOM = ' ',
                                               FL_UTENTE = ' '
                                     WHERE FL_LIB = :UM_LIBNOM
                                           AND FL_FILE  = :UM_FILNOM
                                           AND FL_CAMPO = :UM_CAMPO
                                           AND FL_UTENTE = :UM_NOMUTE;

                    EndIf;
                  EndIf;
                  If (SqlStt = '00000');
                    p_UpdMask.UM_Message = 'MSK0007';
                    p_UpdMask.UM_MessageInd = *On;
                  Else;
                    p_UpdMask.UM_Message = 'MSK0006';
                    Dspf.MessageInd = *On;
                  EndIf;
                EndIf;

                Else;
                    InsertAll(p_UpdMask.UM_Message
                             :p_UpdMask.UM_MessageInd);

                EndIf;
        End-Proc;

        Dcl-Proc InsertAlter;
        Dcl-Pi InsertAlter;
             p_UpdMAsk  LikeDs(Ds_UpdMask);
             MsgInd      Ind;
        End-Pi;
          Dcl-s Counter Zoned(5:0);
          Dcl-s WRetVal char(256);

            DsInput.In_Lib  = UM_LIBNOM;
            DsInput.In_File = UM_FILNOM;
            DsInput.In_Campo  = UM_CAMPO ;
            DsInput.In_MasCam  = 'S'       ;
            DsInput.In_MasNom  = UM_MASNOM ;
            DsInput.In_Utente  = UM_NOMUTE;
            DsInput.In_TipDat = p_UpdMask.UM_TipDat;
            DsInput.In_LunDat = p_UpdMask.UM_LunDat;
            //Verifica se primo utente inserito
            Exec Sql
               SELECT COUNT(*) INTO :Counter FROM FILLST00F
                 WHERE FL_LIB = :UM_LIBNOM
                   AND FL_FILE = :UM_FILNOM
                   AND FL_CAMPO = :UM_CAMPO
                   AND FL_MASCAM = 'N';
            If (Counter > 0);

              UpdFprocMask(Dsinput);
              If (DsInput.In_ErrorMsg = 'MSK0007');
                Exec Sql
                    UPDATE FILLST00F SET FL_MASCAM = 'S',
                                       FL_MASNOM = :UM_MASNOM,
                                       FL_UTENTE = :UM_NOMUTE
                               WHERE  FL_LIB = :UM_LIBNOM
                                 AND FL_FILE = :UM_FILNOM
                                 AND FL_CAMPO = :UM_CAMPO
                                 AND FL_MASCAM = 'N';
                If (SqlStt = '00000');
                    p_UpdMask.UM_Message = 'MSK0007';
                    p_UpdMask.UM_MessageInd = *On;
                Else;
                    p_UpdMask.UM_Message = 'MSK0006';
                    p_UpdMask.UM_MessageInd = *On;
                EndIf;
              Else;
                p_UpdMask.UM_Message = 'MSK0006';
                p_UpdMask.UM_MessageInd = *On;
              EndIf;

            Else;
                    UpdFprocMask(Dsinput);
                    If (DsInput.In_ErrorMsg = 'MSK0007');
                        Exec Sql
                         INSERT INTO FILLST00F VALUES(
                           :UM_LIBNOM,
                           :UM_FILNOM,
                           :UM_CAMPO,
                           :P_UPDMASK.UM_TIPDAT,
                           :P_UPDMASK.UM_LUNDAT,
                                   (SELECT FL_CRITCAM FROM FILLST00F
                            WHERE FL_LIB = :UM_LIBNOM
                              AND FL_FILE= :UM_FILNOM
                              AND FL_CAMPO = :UM_CAMPO
                              GROUP BY FL_CRITCAM),
                            (SELECT FL_FPRLPGM FROM FILLST00F
                            WHERE FL_LIB = :UM_LIBNOM
                              AND FL_FILE= :UM_FILNOM
                              AND FL_CAMPO = :UM_CAMPO
                              GROUP BY FL_FPRLPGM),
                            (SELECT FL_FPRPGM FROM FILLST00F
                            WHERE FL_LIB = :UM_LIBNOM
                              AND FL_FILE= :UM_FILNOM
                              AND FL_CAMPO = :UM_CAMPO
                              GROUP BY FL_FPRPGM),
                           'S',
                           :UM_MASNOM,
                           :UM_NOMUTE,
                           ' '
                           );
                    EndIf;

                        If (SqlStt = '00000') And
                           (DsInput.In_ErrorMsg = 'MSK0007');
                           p_UpdMask.UM_MessageInd = *On;
                           p_UpdMask.UM_Message = 'MSK0007';
                        Else;
                           MSGID = DsInput.In_ErrorMsg;
                           Dspf.MessageInd = *On;
                        EndIf;


                    EndIf;
        End-Proc;

        Dcl-Proc pCheckObj;
        Dcl-Pi pCheckObj;
           p_NomObj char(10) const;
           p_TipObj char(10) const;
           p_Resp   char(1) ;
        End-Pi;
           Monitor;
             Cmd = 'CHKOBJ ' + %Trim(p_NomObj) + ' OBJTYPE(' + p_TipObj + ')';
             CmdExec(Cmd
                    :%Len(Cmd));
           On-Error;
             p_Resp = '1';
           EndMon;
        End-Proc;

        Dcl-Proc InsertAll;
        Dcl-Pi InsertAll;
           p_Message    char(7);
           p_MessageInd Ind;
        End-Pi;

                 Exec Sql
                        DECLARE INS_ALLREC CURSOR FOR
                           SELECT C.TABLE_SCHEMA, C.TABLE_NAME,
                           C.COLUMN_NAME, C.DATA_TYPE, C."LENGTH",
                           CASE
                             WHEN COALESCE(F.FIELD_PROC, ' ') <> ' '
                             THEN 'S'
                             ELSE 'N'
                           END AS CRITCAM,
                           CASE
                             WHEN COALESCE(F.FIELD_PROC, ' ') <> ' '
                             THEN LIBSST(F.FIELD_PROC)
                             ELSE ' '
                           END AS LIB_PGM_FIELDPROC,
                           CASE
                             WHEN COALESCE(F.FIELD_PROC, ' ') <> ' '
                             THEN OBJSST(F.FIELD_PROC)
                             ELSE ' '
                           END AS NOME_PGM_FIELDPROC,
                           CASE
                             WHEN C.COLUMN_NAME = :UM_CAMPO
                             THEN :UM_MASCAM
                             WHEN COALESCE(CT.RULETEXT, ' ') <> ' '
                             THEN 'S'
                             ELSE 'N'
                           END CAMPO_MSACHERATO,
                           CASE
                             WHEN C.COLUMN_NAME = :UM_CAMPO
                             THEN :UM_MASNOM
                             ELSE COALESCE(CT.RCAC_NAME, ' ')
                           END AS NOME_MASCHERA,
                           CASE
                             WHEN C.COLUMN_NAME = :UM_CAMPO
                             THEN :UM_NOMUTE
                             ELSE ' '
                           END AS NOME_UTENTE,
                           ' ' AS DESC_UTENTE,
                           COALESCE(CT.RULETEXT, ' ')
                    FROM QSYS2.SYSCOLUMNS C LEFT JOIN QSYS2.SYSFIELDS F ON
                                    C.TABLE_SCHEMA = F.TABLE_SCHEMA AND
                                    C.TABLE_NAME   = F.TABLE_NAME   AND
                                    C.COLUMN_NAME  = F.COLUMN_NAME
                                            LEFT JOIN QSYS2.SYSCONTROLS CT ON
                                    C.TABLE_SCHEMA = CT.TABLE_SCHEMA AND
                                    C.TABLE_NAME   = CT.TABLE_NAME   AND
                                    C.COLUMN_NAME  = CT.COLUMN_NAME

                    WHERE (C.TABLE_SCHEMA = :UM_LIBNOM)
                      AND (C.TABLE_NAME = :UM_FILNOM);
                    EXEC SQL
                        OPEN INS_ALLREC;
                    EXEC SQL
                        FETCH INS_ALLREC INTO :Ds_MSK_AllRec;
               DoW (SqlStt = '00000') And (Dspf.MessageInd = *Off);
                  Fine = *Off;
                  p_PosI = 1;
                  Clear CntUser;
                If (Ds_MSK_AllRec.AR_MasCam = 'S');

                     Dow (Fine = *Off) And (Dspf.MessageInd = *Off);
                        FindAutUser(Ds_MSK_AllRec.AR_Regola
                                   :p_NomeUtente
                                   :p_PosI
                                   :Fine);
                        If (Fine = *On);
                            If (CntUser = 0);
                                DsInput = Ds_MSK_ALLRec;
                                Clear DsInput.In_Error ;
                                Clear DsInput.In_ErrorMsg;
                            //Se inserisco dati in DB vuoto e rilevo che campo
                            //gi� critt non riesegue la set fieldproc
                                If (DsInput.IN_CritCam = 'S');
                                  DsInput.IN_CritCam = 'N';
                                  UpdFprocMask(DsInput);
                                //Ma la reimposto per la insert nel DB
                                  DsInput.IN_CritCam = 'S';
                                Else;
                                  UpdFprocMask(DsInput);
                                EndIf;
                                If (DsInput.IN_ErrorMsg <> 'MSK0007'); //term OK
                                  p_message = DsInput.IN_ErrorMsg;
                                  Dspf.MessageInd = *On;
                                  Leave;
                                EndIf;

                                Ds_FilLst = Ds_MSK_AllRec;
                                EXEC SQL
                                  INSERT INTO FILLST00F VALUES(:Ds_FilLst);
                                If (SqlStt <> '00000');
                                    p_message = 'MSK0006';
                                    Dspf.MessageInd = *ON;
                                EndIf;
                            EndIf;
                            Leave;
                        EndIf;
                        CntUser = CntUser +1;
                        Ds_MSK_AllRec.AR_Utente = p_NomeUtente;
                        Ds_FilLst = Ds_MSK_AllRec;
                        EXEC SQL
                            INSERT INTO FILLST00F VALUES(:Ds_FilLst);
                        If (SqlStt <> '00000');
                         p_message = 'MSK0006';
                         Dspf.MessageInd = *ON;
                        EndIf;
                     EndDo;

         //             Clear DsInput.In_Error ;
         //             Clear DsInput.In_ErrorMsg;
         //             If (Ds_MSK_ALLRec.AR_Utente = UM_NOMUTE) And
         //                (Ds_MSK_ALLRec.AR_MasNom = UM_MASNOM) And
         //                (Dspf.MessageInd = *Off);
         //                  DsInput = Ds_MSK_ALLRec;
         //                  UpdFprocMask(DsInput);
         //                  If (DsInput.In_ErrorMsg <> 'MSK0007');
         //                    MSGID = DsInput.In_ErrorMsg;
         //                    Dspf.MessageInd = *ON;
         //                  EndIf;
         //             EndIf;
         //             DS_FilLst = Ds_MSK_AllRec;
         //             If (Dspf.MessageInd = *Off) And (Fine = *Off);
         //              EXEC SQL
         //               INSERT INTO FILLST00F VALUES(:Ds_FilLst);
         //               If (SqlStt <> '00000');
         //                 MSGID = 'MSK0006';
         //                 Dspf.MessageInd = *ON;
         //                 Leave;
         //               EndIf;
         //             EndIf;
                Else;
                     Ds_FilLst = Ds_MSK_AllRec;
                     EXEC SQL
                      INSERT INTO FILLST00F VALUES(:Ds_FilLst);
                        If (SqlStt <> '00000');
                         p_message = 'MSK0006';
                         Dspf.MessageInd = *ON;
                         Leave;
                       EndIf;
                EndIf;
                  EXEC SQL
                      FETCH INS_ALLREC INTO :Ds_MSK_AllRec;
                EndDo;
                        If (Dspf.MessageInd = *ON);
                            p_Message = p_message;
                        Else;
                            p_Message = 'MSK0007';
                        EndIf;
                        p_MessageInd = *On;

        End-Proc;
