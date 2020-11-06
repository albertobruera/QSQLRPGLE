        dcl-f cfgdsp00v workstn IndDs(Dspf) ;

        dcl-pr UpdMask;
          p_UpdMask LikeDs(Ds_UpdMask);
        end-pr;

        Dcl-pr FindAutUser;
          SourceString varChar(256);
          NomeUtente   Char(10);
          p_Posi       Zoned(5:0);
          p_CheckRule	Ind;
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
        end-pr;

        Dcl-ds Dspf qualified ;
             EleCamInd    ind pos(04);
             InsertInd    ind pos(06);
             Annulla      ind pos(12);
             RemoveInd    ind pos(40);
             CampoOK      ind pos(50);
             MasNomOK     ind pos(60);
             MessageInd   ind pos(90);
        End-Ds;
        dcl-ds Ds_UpdMask ExtName('FILLST00F') qualified Prefix(UM_:3);
          //UM_Lib       char(10);
          //UM_File      char(10);
          //UM_Cam       char(10);
          //UM_TipDat    char(10);
          //UM_LunDat     Int(10);
          //UM_MasCam    char(1);
          //UM_MasNom    char(256)      ;
          //UM_NomUte    char(10)  ;
         //          UM_RuleText  varchar(256);
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
          //AR_LibNom       char(10);
          //AR_FilNom       char(10);
          //AR_Campo        char(10);
          //AR_TipoDato     char(10);
          //AR_LungDato     Int(10:0);
          //AR_NumScale     Int(10:0);
          //AR_CritCam      char(1);
          //AR_LibFldPr     char(10);
          //AR_NomPgmFP     char(10);
          //AR_MasCam       char(1);
          //AR_MasNom       char(256);
          //AR_NomUte       char(10);
          //AR_DesUte       char(10);
          AR_regola       varchar(256);
        end-ds;

        dcl-ds DsInput ExtName('FILLST00F') qualified Prefix(IN_:3);
          //p_LibNom       char(10);   //Nome Libreria
          //p_FilNom       char(10);   //Nome File
          //p_Campo        char(10);   //Nome campo del file
          //p_TipoDato     char(10);   //Tipo di dato
          //p_LungDato     Int(10:0);  //Lunghezza del dato
            //p_NumScale     Int(10:0);  //Numeric scale - nr decimali
          //p_CritCam      char(1);    //Campo crttografato: S=SI   N=No
          //p_LibPgmFP     char(10);   //Libreria del pgm della field proceure
          //p_PgmFP        char(10);   //nome programma della field procedure
          //p_MasCam       char(1);    //Campo mascherato: S=I  N=no
          //p_MasNom       char(256);  //Nome della maschera
          //p_NomUte       char(10);   //Nome utente autorizzato ai dati
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
        dcl-s p_CheckRule	Ind;	
        dcl-s p_Resp      Ind;

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
            Dspf.InsertInd = p_UpdMask.UM_InsertInd;
            Dspf.Annulla = *off;
          DoW (Dspf.Annulla = *Off And p_UpdMask.UM_MessageInd = *Off);
            If (p_UpdMask.UM_InsertInd = *Off);
                Dspf.CampoOK = *On;
                Dspf.RemoveInd = *On;
                Exec Sql
                 SELECT * Into :Ds_FilLst
                   FROM FILLST00F
                  WHERE FL_LIB   = :UM_LIBNOM
                    AND FL_FILE  = :UM_FILNOM
                    AND FL_CAMPO = :UM_CAMPO;
                If (SqlStt = '00000');
                  Dspf.CampoOK = *On;
                  If (Ds_FilLst.FL_MasNom <> *blanks);
                    UM_MASNOM = Ds_FilLst.FL_MasNom;
                    Dspf.MasNomOK = *on;
                  EndIf;
                EndIf;
            EndIf;
            Exfmt MSKUPD;
            Dspf.MessageInd = *Off;
            If (Dspf.Annulla = *On);
              leave;
            EndIf;
            If (UM_CAMPO <> *blanks);
              Dspf.CampoOk = *On;
            EndIf;
            If (p_UpdMask.UM_InsertInd = *On) And (Dspf.CampoOk = *Off);
               If (Dspf.EleCamInd = *On);
                 ElencoCampi(UM_LIBNOM
                            :UM_FILNOM
                            :UM_CAMPO);
                 If (UM_CAMPO <> *blanks);
                    Dspf.CampoOk = *On;
                    Exec Sql
                      SELECT SUBSTRING(FL_MASNOM, 1, 35) INTO :UM_MASNOM
                        FROM FILLST00F WHERE FL_LIB = :UM_LIBNOM
                                         AND FL_FILE = :UM_FILNOM
                                         AND FL_CAMPO = :UM_CAMPO;
                    If (SqlStt = '00000');
                      p_UpdMask.Um_MasNom = UM_MASNOM;
                      Dspf.MasNomOk = *On;
                    EndIf;
                 EndIf;
                 Iter;
               EndIf;
               If (UM_CAMPO = *blanks);
                 UM_ERRMSG = 'Nome cmapo oblbigatorio.';
                 Dspf.MessageInd = *On;
                 Iter;
               EndIf;

            Else;
               If (UM_MASCAM = 'N');
                 UM_ERRMSG = 'Per inserire gli altri campi, impostare lo stato +
                              a "S".';
                 Dspf.MessageInd = *On;
                 Iter;
               EndIf;

               If (UM_MASNOM = *blanks) And (Dspf.MasNomOk = *On);
                 UM_ERRMSG = 'Nome maschera obbligatorio.';
                 Dspf.MessageInd = *On;
                 Iter;
               Else;
                 If (Dspf.MasNomOk = *Off);
                   Dspf.MasNomOk = *On;
                   p_UpdMask.UM_MasNom = UM_MASNOM;
                   Iter;
                 EndIf;
               EndIf;
                  If (UM_NOMUTE <> *blanks);

                    pCheckObj(UM_NOMUTE
                             :'*USRPRF'
                             :p_Resp);
                    If (p_Resp = '1');
                       UM_ERRMSG = 'Nome utente non trovato.';
                       Dspf.MessageInd = *On;
                       Iter;
                    Else;
                       p_UpdMask.UM_Utente = UM_NOMUTE;
                       Exec Sql
                         SELECT * INTO :Ds_FilLst
                           FROM FILLST00F
                          WHERE FL_LIB = :UM_LIBNOM
                            AND FL_FILE = :UM_FILNOM
                            AND FL_CAMPO = :UM_CAMPO
                            AND FL_UTENTE = :UM_NOMUTE;
                        If (SqlStt = '00000');
                          UM_ERRMSG = 'Nome utente gi� inserito.';
                          Dspf.MessageInd = *On;
                          Iter;
                        EndIf;
                    EndIf;
                  Else;
                    UM_ERRMSG = 'Nome utente obbligatorio.';
                    Dspf.MessageInd = *On;
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

                UpdFprocMask(DsInput);

                If (DsInput.In_Error = *On);
                  UM_ERRMSG = 'CREATE OR REPLACE MASK o ADD CONSTRAINT' +
                  ' terminato in errore.ta. Verificare.';
                  p_UpdMask.UM_MessageInd = *On;
                Else;
                  If (p_UpdMask.UM_MasCam <> UM_MASCAM) And (UM_MASCAM = 'S');
                    Exec Sql
                    UPDATE FILLST00F SET FL_MASCAM = :UM_MASCAM,
                                         FL_MASNOM = :UM_MASNOM,
                                         FL_UTENTE = :UM_NOMUTE
                                   WHERE FL_LIB = :UM_LIBNOM
                                     AND FL_FILE = :UM_FILNOM
                                     AND FL_CAMPO = :UM_CAMPO;
                  Else;
                    Exec Sql
                     DELETE FROM FILLST00F WHERE FL_LIB = :UM_LIBNOM
                                           AND FL_FILE = :UM_FILNOM
                                          AND FL_CAMPO = :UM_CAMPO
                                         AND FL_UTENTE = :UM_NOMUTE;
                  EndIf;

                    p_UpdMask.UM_Message = 'CREATE OR REPLACE MASK e +
                             aggiornamento DB termianti correttamente.';
                    p_UpdMask.UM_MessageInd = *On;
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
                Exec Sql
                  UPDATE FILLST00F SET FL_MASCAM = 'S',
                                       FL_MASNOM = :UM_MASNOM,
                                       FL_UTENTE = :UM_NOMUTE
                               WHERE  FL_LIB = :UM_LIBNOM
                                 AND FL_FILE = :UM_FILNOM
                                 AND FL_CAMPO = :UM_CAMPO
                                 AND FL_MASCAM = 'N';
            Else;
               //Verifica se CAMPO gi� inserito
               Exec Sql
               		SELECT COUNT(*) INTO :Counter FROM FILLST00F
                 		WHERE FL_LIB = :UM_LIBNOM
                   		AND FL_FILE = :UM_FILNOM
                   		AND FL_CAMPO = :UM_CAMPO;
                If (SqlStt = '00000');
	                UpdFprocMask(Dsinput);
                 Exec Sql
                		INSERT INTO FILLST00F VALUES(
                									  :UM_LIBNOM,
                									  :UM_FILNOM,
                									  :UM_CAMPO,
                									  :p_UpdMask.UM_TipDat,
                									  :p_UpdMask.UM_LunDat,
        							                   0,
                          							  (SELECT FL_CRITCAM FROM FILLST00F
                									  	WHERE FL_LIB = :UM_LIBNOM
                									  	  AND FL_FILE= :UM_FILNOM
                									  	  AND FL_CAMPO = :UM_CAMPO),
                									   (SELECT FL_FPRLPGM FROM FILLST00F
                									  	WHERE FL_LIB = :UM_LIBNOM
                									  	  AND FL_FILE= :UM_FILNOM
                									  	  AND FL_CAMPO = :UM_CAMPO),
                									   (SELECT FL_FPRPGM FROM FILLST00F
                									  	WHERE FL_LIB = :UM_LIBNOM
                									  	  AND FL_FILE= :UM_FILNOM
                									  	  AND FL_CAMPO = :UM_CAMPO),
                									  'S',
                									  :UM_MASNOM,
                									  :UM_NOMUTE,
               								          ' '
                									 );
                Else;
                 Exec Sql
                	DECLARE INS_ALLREC CURSOR FOR
             		   SELECT C.TABLE_SCHEMA, C.TABLE_NAME,
                           C.COLUMN_NAME, C.DATA_TYPE, C."LENGTH",
                           COALESCE(C.NUMERIC_SCALE, 0),
                           'N' AS CRITCAM,
                           ' ' AS LIB_PGM_FIELDPROC,
                           ' ' AS NOME_PGM_FIELDPROC,
                           CASE
                             WHEN C.COLUMN_NAME = :UM_CAMPO THEN :UM_MASCAM
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
                     	FETCH INS_ALLREC INTO :Ds_MSK_AllRec;

                DoW (SqlStt <> '00000') And (Dspf.MessageInd = *Off);
                  Fine = *Off;
                  DoW (DS_MSK_AllRec.AR_Regola <> *blank);
                     FindAutUser(Ds_MSK_AllRec.AR_Regola
                               :p_NomeUtente
                               :p_PosI
                               :p_CheckRule
                               :Fine);
                     If (Fine = *On);
                       Leave;
                     EndIf;
                     If (p_CheckRule = *On);
                      Ds_MSK_ALLRec.AR_Utente = p_NomeUtente;

                      DsInput.In_Lib = Ds_MSK_ALLRec.AR_Lib;
                      DsInput.In_File = Ds_MSK_ALLRec.AR_File;
                      DsInput.In_Campo  = Ds_MSK_ALLRec.AR_Campo;
                      DsInput.In_TipDat = Ds_MSK_ALLRec.AR_TipDat;
   		                 DsInput.In_LunDat = Ds_MSK_ALLRec.AR_LunDat;
              //p_NumScale     Int(10:0);  //Numeric scale - n�?? decimali
                      DsInput.In_CritCam = Ds_MSK_ALLRec.AR_CritCam;
                      DsInput.In_FprLPgm = Ds_MSK_ALLRec.AR_FprLPgm;
                      DsInput.In_FprPgm = Ds_MSK_ALLRec.AR_FprPgm;
                      DsInput.In_MasCam = Ds_MSK_ALLRec.AR_MasCam;
                      DsInput.In_MasNom = Ds_MSK_ALLRec.AR_MasNom;
                      DsInput.In_Utente = Ds_MSK_ALLRec.AR_Utente;
                      Clear DsInput.In_Error ;
                      Clear DsInput.In_ErrorMsg;
                      UpdFprocMask(DsInput);
                     EndIf;
                     If (DsInput.In_Error = *On);
                       Ds_FilLst = Ds_MSK_AllRec;
                       EXEC SQL
  	 			  		INSERT INTO FILLST00F VALUES(:DS_FilLst);
                        If (SqlStt <> '00000');
                         UM_ERRMSG = 'Insert DB terminato con errori, +
                                 		CREATE MASK non eseguito.';
                         Dspf.MessageInd = *ON;
                         Leave;
                       EndIf;
                     EndIf;
	
                  EndDo;
                  EXEC SQL
                			FETCH INS_ALLREC INTO :Ds_MSK_AllRec;
                EndDo;
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
