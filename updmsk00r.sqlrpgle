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

        Dcl-ds Dspf qualified ;
             InsertInd    ind pos(06);
             Annulla      ind pos(12);
             RemoveInd    ind pos(40);
             Um_CampoOK   ind pos(50);
             Um_MasNomOK  ind pos(60);
             MessageInd   ind pos(90);
        End-Ds;
        dcl-ds Ds_UpdMask Qualified;
          UM_Lib       char(10);
          UM_File      char(10);
          UM_Cam       char(10);
          UM_TipDat    char(10);
          UM_LunDat     Int(10);
          UM_MasCam    char(1);
          UM_MasNom    char(256)      ;
          UM_NomUte    char(10)  ;
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
        dcl-ds Ds_MSK_AllRec Qualified;
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

        dcl-ds DsInput Qualified;
          p_LibNom       char(10);   //Nome Libreria
          p_FilNom       char(10);   //Nome File
          p_Campo        char(10);   //Nome campo del file
          p_TipoDato     char(10);   //Tipo di dato
          p_LungDato     Int(10:0);  //Lunghezza del dato
          //p_NumScale     Int(10:0);  //Numeric scale - n� decimali
          p_CritCam      char(1);    //Campo crttografato: S=S� N=No
          p_LibPgmFP     char(10);   //Libreria del pgm della field proceure
          p_PgmFP        char(10);   //nome programma della field procedure
          p_MasCam       char(1);    //Campo mascherato: S=s� N=no
          p_MasNom       char(256);  //Nome della maschera
          p_NomUte       char(10);   //Nome utente autorizzato ai dati
          p_Error        Ind ;       //Indicatore di errore esecuzione
          p_ErrorMsg     char(256);   //Messaggio di errore
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

        Dcl-Proc UpdMask export;
        Dcl-pi UpdMask;
          p_UpdMask LikeDs(Ds_UpdMask);
        end-pi;
            UM_LIBNOM = p_UpdMask.UM_Lib;
            UM_FILNOM = p_UpdMask.UM_File;
            UM_CAMPO  = p_UpdMask.UM_Cam;
            UM_MASCAM = p_UpdMask.UM_MasCam;
            UM_MASNOM = p_UpdMask.UM_MasNom;
            UM_NOMUTE = p_UpdMask.UM_NomUte;
            Dspf.InsertInd = p_UpdMask.UM_InsertInd;
            Dspf.Annulla = *off;
          DoW (Dspf.Annulla = *Off And p_UpdMask.UM_MessageInd = *Off);
            If (Dspf.InsertInd = *Off);
                Dspf.Um_CampoOK = *On;
                Dspf.Um_MasNomOK = *On;
                Dspf.RemoveInd = *On;
            EndIf;
               Exfmt MSKUPD;
               Dspf.MessageInd = *Off;
            If (Dspf.Annulla = *On);
              leave;
            EndIf;
            If (Dspf.InsertInd = *On) And (Dspf.Um_CampoOk = *Off);

               If (UM_CAMPO = *blanks);
                 UM_ERRMSG = 'Nome cmapo oblbigatorio.';
                 Dspf.MessagInd = *On;
                 Iter;
               EndIf;
               Exec Sql
                 SELECT FL.* Into :Ds_FilLst
                   FROM FILLST00F
                  WHERE FL_LIB   = :UM_LIBNOM
                    AND FL_FILE  = :UMFILNOM
                    AND FL_CAMPO = :UM_CAMPO;
               If (SqlStt = '00000')
                 Dspf.Um_CampoOK = *On;
                 If (Ds_FilLst.FL_MasNom <> *blanks):
                   UM_MASNOM = Ds_FilLst.FL_MasNom;
                   Dspf.Um_MasNomOK = *on;
                 EndIf;
                 Iter
               Else;
                 UM_ERRMSG = 'Campo non presente in DB.';
                 Dspf.MessageInd = *On;
                 Iter;
               EndIf;
            Else;
               If (UM_MASNOM <> *blanks);
                  If (UM_NOMUTE <> *blanks);
                    pCheckObj(UM_NOMUTE
                             :TipoObj
                             :pResp);
                    If (pResp = '1');
                       UM_ERRMSG = 'Nome utente non trovato.';
                       Dspf.MessageInd = *On;
                       Iter;
                    Else;
                       Exec Sql
                         SELECT * INTO :Ds_FilLst
                           FROM FILLST00F
                          WHERE FL_LIB = :UM_LIBNOM
                            AND FL_FILE = :UM_FILNOM
                            AND FL_CAMPO = :UM_CAMPO
                            AND FL_UTENTE = :UM_NOMUTE;
                        If (SqlStt <> '00000')
                          UM_ERRMSG = 'Nome utente gi� inserito.';
                          Dspf.MessageInd = *On;
                          Iter;
                        EndIf;
                    EndIf;
                  Else;
                    UM_ERRMSG = 'Nome maschera obbligatorio.';
                    Dspf.MessageInd = *On;
                    Iter;
                  EndIf;
               Else;
                 UM_ERRMSG = 'Nome maschera obbligatorio.';
                 Dspf.MessageInd = *On;
                 Iter;
               EndIf;

            EndIf;

            If (Dspf.InsertInd = *Off);
              RemoveAlter(p_UpdMask
                         :Dspf.MessageInd   );
            Else;
              InsertAlter(p_UpdMask
                         :Dspf.MessageInd   );
            EndIF;

          EndDo;
          *Inlr = *ON;
        End-Proc;

        Dcl-Proc RemoveAlter;
        Dcl-Pi RemoveAlter;
          p_UpdMask  LikeDs(Ds_UpdMask);
          MsgInd      Ind;
        End-Pi;

                DsInput.p_LibNom = UM_LIBNOM;
                DsInput.p_FilNom = UM_FILNOM;
                DsInput.p_Campo  = UM_CAMPO ;
                DsInput.p_MasCam  = 'N';
                DsInput.p_MasNom  = UM_MASNOM ;
                DsInput.p_NomUte  = UM_NOMUTE;

                UpdFprocMask(DsInput);

                If (DsInput.p_Error = *On);
                  UM_ERRMSG = 'CREATE OR REPLACE MASK terminato in errore.' +
                  ' Maschera non impostata, verificare.';
                  p_UpdMask.UM_MessageInd = *On;
                Else;
                  Exec Sql
                    DELETE FROM FILLST00F WHERE FL_LIB = :UM_LIBNOM
                                           AND FL_FILE = :UM_FILNOM
                                          AND FL_CAMPO = :UM_CAMPO
                                         AND FL_UTENTE = :UM_NOMUTE;

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

            DsInput.p_LibNom = UM_LIBNOM;
            DsInput.p_FilNom = UM_FILNOM;
            DsInput.p_Campo  = UM_CAMPO ;
            DsInput.p_MasCam  = 'S'       ;
            DsInput.p_MasNom  = UM_MASNOM ;
            DsInput.p_NomUte  = UM_NOMUTE;
            DsInput.p_TipoDato = p_UpdMask.TipDat;
            DsInput.p_LungDato = p_UpdMask.LunDat;

		  //Verifica se primo utente inserito	
            Exec Sql
               SELECT COUNT(*) INTO :Counter FROM FILLST00F
                 WHERE FL_LIB = :UM_LIB
                   AND FL_FILE = :UM_FILE
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
         //Verifica se CAMPO già inserito   
            	Exec Sql
               		SELECT COUNT(*) INTO :Counter FROM FILLST00F
                 		WHERE FL_LIB = :UM_LIB
                   		AND FL_FILE = :UM_FILE
                   		AND FL_CAMPO = :UM_CAMPO;
                If (SqlStt = '00000');
	                UpdFprocMask(Dsinput);
                	Exec Sql
                		INSERT INTO FILLST00F VALUES(
                									  :UM_LIBNOM,
                									  :UM_FILNOM,
                									  :UM_CAMPO,
                									  :p_UpdMask.TipDat
                									  :p_UpdMask.LunDat
                									  :(SELECT FL_CRITCAM FROM FILLST00F
                									  	WHERE FL_LIB = :UMLIBNOM 
                									  	  AND FL_FILE= :UM_FILNOM
                									  	  AND FL_CAMPO = :UM_CAMPO)
                									  :(SELECT FL_FLDPRLPGM FROM FILLST00F
                									  	WHERE FL_LIB = :UMLIBNOM 
                									  	  AND FL_FILE= :UM_FILNOM
                									  	  AND FL_CAMPO = :UM_CAMPO)
                									  :(SELECT FL_FLDPRCPGM FROM FILLST00F
                									  	WHERE FL_LIB = :UMLIBNOM 
                									  	  AND FL_FILE= :UM_FILNOM
                									  	  AND FL_CAMPO = :UM_CAMPO)
                									  :'S'
                									  :UM_MASNOM
                									  :UM_NOMUTE
                									 )
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
                  				Ds_MSK_ALLRec.AR_NomUte = p_NomeUtente;

        				   		DsInput.p_LibNom = Ds_MSK_ALLRec.AR_LibNom;
        				    	DsInput.p_FilNom = Ds_MSK_ALLRec.AR_FilNom;
      	 				    	DsInput.p_Campo  = Ds_MSK_ALLRec.AR_Campo;
          						DsInput.p_TipoDato = Ds_MSK_ALLRec.AR_TipoDato;
   					        	DsInput.p_LungDato = Ds_MSK_ALLRec.AR_LungDato;
        				  //p_NumScale     Int(10:0);  //Numeric scale - n� decimali
       					    	DsInput.p_CritCam = Ds_MSK_ALLRec.AR_CritCam;
      					    	DsInput.p_LibPgmFP = Ds_MSK_ALLRec.AR_LibFldPr;
    					    	DsInput.p_PgmFP = Ds_MSK_ALLRec.AR_NomPgmFP;
          						DsInput.p_MasCam = Ds_MSK_ALLRec.AR_MasCam;
          						DsInput.p_MasNom = Ds_MSK_ALLRec.AR_MasNom;
          						DsInput.p_NomUte = Ds_MSK_ALLRec.AR_NomUte;
          						Clear DsInput.p_Error ;
          						Clear DsInput.p_ErrorMsg; =  
								UpdFprMsk(DsInput);
                  			EndIf;
								If (DsInput.p_Error = *On)
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

        End-Proc;
