        //ctl-opt dftactgrp(*no);
        dcl-pr UpdFprocMask;
          p_DsInput LikeDs(DsInput);
        end-pr;
        dcl-pr CryptField;
          Crypt_DsInput LikeDs(DsInput);
        end-pr;
        dcl-pr MaskField;
          Mask_DsInput LikeDs(DsInput);
        end-pr;
        dcl-pr SendPgmMsg EXTPGM('QMHSNDPM');
             MsgID      char(7)        const;
             MsgFile    char(20)       const ;
             MsgData    varchar(32767) const ;
             MsgDtaLen  Int(10)        const ;
             MsgType    char(10)       const ;
             StackEntry char(10)       const ;
             StackCount Int(10)       const ;
             MsgKey     char(4)             ;
             ErrorCode varchar(32767)       ;
        end-pr;
        dcl-ds Ds_SndPgmMSg;
             MsgID      char(7)        ;
             MsgFile    char(20)        ;
             MsgData    varchar(32767)  ;
             MsgDtaLen  Int (10)         ;
             MsgType    char(10)        ;
             StackEntry char(10)        ;
             StackCount Int (10)        ;
             MsgKey     char(4)             ;
             ErrorCode varchar(32767)       ;
        end-ds;

        dcl-ds DsInput Qualified;
          IN_LibNom       char(10);   //Nome Libreria
          IN_FilNom       char(10);   //Nome File
          IN_Campo        char(10);   //Nome campo del file
          IN_TipoDato     char(10);   //Tipo di dato
          IN_LungDato     Int(10:0);  //Lunghezza del dato
          //IN_NumScale     Int(10:0);  //Numeric scale - n° decimali
          IN_CritCam      char(1);    //Campo crttografato: S=Sì N=No
          IN_LibPgmFP     char(10);   //Libreria del pgm della field proceure
          IN_PgmFP        char(10);   //nome programma della field procedure
          IN_MasCam       char(1);    //Campo mascherato: S=sì N=no
          IN_MasNom       char(256);  //Nome della maschera
          IN_NomUte       char(10);   //Nome utente autorizzato ai dati
          OUT_Error        Ind ;       //Indicatore di errore esecuzione
          OUT_ErrorMsg     char(256);   //Messaggio di errore
        end-ds;
        Dcl-s Set_Cmd      char(256);
        Dcl-s Drop_Cmd      char(256);


        Dcl-Proc UpdFprocMask export;
        Dcl-pi UpdFprocMask;
          p_DsInput LikeDs(DsInput);
        end-pi;
         p_DsInput.OUT_Error = *Off;
         If (p_DsInput.IN_Campo = *blanks) or (p_DsInput.IN_LibNom = *blanks) or
           (p_DsInput.IN_FilNom = *blanks) or
           ((p_DsInput.IN_CritCam = *blank) and (p_DsInput.IN_MasCam = *blank));
          DsInput.OUT_Error = *On;
         EndIf;
         If (p_DsInput.IN_CritCam = 'S') and ((p_DsInput.IN_LibPgmFP = *blanks)
           or (p_DsInput.IN_PgmFP = *blanks));
          DsInput.OUT_Error= *On;
         EndIf;
         If (p_DsInput.IN_MasCam = 'S') and ((p_DsInput.IN_MasNom = *blanks) or
           (p_DsInput.IN_NomUte = *blanks));
          p_DsInput.OUT_Error= *On;
         EndIf;
         If (p_DsInput.OUT_Error= *Off);
			       If (p_DsInput.IN_CritCam <> ' ');
                     CryptField(p_DsInput);
			       EndIf;
			       If (p_DsInput.IN_MasCam <> ' ');
                     MaskField(p_DsInput);
			       EndIf;
       	 Else;
             p_DsInput.OUT_ErrorMsg = 'Parametro obbligatorio mancante. +
                                      Verificare.';
             SendPgmMsg( 'CPF9897'
                     :'QCPFMSG *LIBL'
                     :p_DsInput.OUT_ErrorMsg
                     : %len( %trimr(p_DsInput.OUT_ErrorMsg) )
                     : '*INFO': '*'
                     : 0: MsgKey: ErrorCode );
         EndIf;
			
            *Inlr = *On;

        End-Proc;

        Dcl-Proc CryptField;
        Dcl-pi CryptField;
            Crypt_DsInput likeDs(DsInput);
        End-pi;

          If (Crypt_DsInput.IN_CritCam = 'S');
           Set_Cmd = 'ALTER TABLE  ' + %Trim(Crypt_DsInput.IN_LibNom) + '/' +
                                     %Trim(Crypt_DsInput.IN_FilNom ) +
                  ' ALTER COLUMN ' + %Trim(Crypt_DsInput.IN_Campo) +
                  ' SET FIELDPROC ' + %Trim(Crypt_DsInput.IN_LibPgmFP) + '/' +
                                      %Trim(Crypt_DsInput.IN_PgmFP);
            Exec Sql
              PREPARE SETFLDPRC FROM :Set_CMD;
            Exec Sql
              EXECUTE SETFLDPRC;
            If (SqlStt <> '00000');
              Crypt_DsInput.OUT_Error= *On;
              Crypt_DsInput.OUT_ErrorMsg = 'ALTER TABLE per SET FIELDPROC +
                                        terminato con errori. Verificare.';
              SendPgmMsg( 'CPF9897'
                         :'QCPFMSG *LIBL'
                         :Crypt_DsInput.OUT_ErrorMsg
                         : %len( %trimr(Crypt_DsInput.OUT_ErrorMsg) )
                         : '*INFO': '*': 0
                         :MsgKey: ErrorCode );
            EndIf;
          ElseIf (Crypt_DsInput.IN_CritCam = 'N');
            Drop_Cmd = 'ALTER TABLE  ' + %Trim(Crypt_DsInput.IN_LibNom) + '/' +
                                     %Trim(Crypt_DsInput.IN_FilNom ) +
                  ' ALTER COLUMN ' + %Trim(Crypt_DsInput.IN_Campo) +
                  ' DROP FIELDPROC ';

            Exec Sql
              PREPARE DROPFLDPRC FROM :Drop_CMD;
            Exec Sql
              EXECUTE DROPFLDPRC;
            If (SqlStt <> '00000');
              Crypt_DsInput.OUT_ErrorMsg = 'ALTER TABLE per DROP +
                                         FIELDPROC terminato +
                                         con errori. Verificare.';
              Crypt_DsInput.OUT_Error = *On;
              SendPgmMsg( 'CPF9897'
                         :'QCPFMSG *LIBL'
                         :Crypt_DsInput.OUT_ErrorMsg
                         : %len( %trimr(Crypt_DsInput.OUT_ErrorMsg) )
                         : '*INFO': '*': 0
                         : MsgKey: ErrorCode );
            EndIf;
          EndIf;
        End-Proc;

        Dcl-Proc MaskField;
        Dcl-pi MaskField;
            Msk_DsInput likeDs(DsInput);
        End-pi;
        Dcl-ds Ds_SysControls qualified;
            RuleText char(256);
            RuleOk Ind;
        End-Ds;

        Dcl-s CmdMsk     char(1024);
        Dcl-s ErrorMsg   char(80);
        Dcl-s Counter    Zoned(5:0);
        Dcl-s WRetVal    char(256);
        Dcl-s i          Zoned(5:0);

             //Verifica se sulla tabella é attivato il RCAC
             Exec Sql
               SELECT COUNT(*) INTO :Counter FROM QSYS2.SYSCONTROLS
                WHERE TABLE_SCHEMA = :Msk_DsInput.IN_LibNom
                  AND TABLE_NAME   = :Msk_DsInput.IN_FilNom;
             If (Counter = 0);
                CmdMsk = 'ALTER TABLE ' + %Trim(Msk_DsInput.IN_LibNom) + '/' +
                                 %Trim(Msk_DsInput.IN_FilNom) +
                      ' ACTIVATE COLUMN ACCESS CONTROL';
                Exec Sql
                  PREPARE ACTRCAC FROM :CmdMsk;
                Exec Sql
                  EXECUTE ACTRCAC;
                If (SqlStt <> '00000');
                  Msk_DsInput.OUT_ErrorMsg ='Attivazione RECORD COLUMN +
                             ACCESS CONTROL +
                             terminato con errori. SQLSTT = ' + SqlStt +
                             ' verificare';
                  Msk_DsInput.OUT_Error = *On;
                  SendPgmMsg( 'CPF9897'
                         :'QCPFMSG *LIBL'
                         :Msk_DsInput.OUT_ErrorMsg
                         : %len( %trimr(Msk_DsInput.OUT_ErrorMsg) )
                         : '*INFO': '*': 0
                         : MsgKey: ErrorCode );
                EndIf;
             EndIf;

             //Verifica che maschera su campo sia quella predefinita per autoriz
             //e che esistano già utenti autorizzati al campo
             Exec Sql
                SELECT
                  SC.RULETEXT,
                  CASE
                   WHEN REGEXP_LIKE(SC.RULETEXT,'[CASE][WHEN][SESSION_USER IN]',
                   'i')
                   THEN '1'
                   ELSE '0'
                  END AS RULE_OK
                  INTO :Ds_SysControls FROM QSYS2.SYSCONTROLS SC
                WHERE TABLE_SCHEMA = :Msk_DsInput.IN_LibNom
                  AND TABLE_NAME   = :Msk_DsInput.IN_FilNom
                  AND COLUMN_NAME  = :Msk_DsInput.IN_Campo;
             //Se record trovato, quindi campo già inserito con utenti abilitati
             //e regola OK
             //aggiungo (p_DsInput.IN_MasCam = 'S')
             // o rimuovo (p_DsInput.IN_MasCam = 'N')
             // utente alla regola
             If (sqlStt = '00000') And (Ds_SysControls.RuleOk = *On);

                 CrtRplMask(Msk_DsInput
                           :Ds_SysControls);

                //Se CAMPO del file non presente in SYSCONTROLS ma tabella ha
                //già campi con maschera impostata
                //aggiungo maschera su campo e utente autorizzato con la regola
                //predefinita
             ElseIf (SqlStt <> '00000') ; //And (Counter <> 0);
             CmdMsk = 'CREATE OR REPLACE MASK ' + %Trim(Msk_DsInput.IN_MasNom) +
                               ' ON ' + %Trim(Msk_DsInput.IN_LibNom) +
                                  '/' + %Trim(Msk_DsInput.IN_FilNom) +
                               ' FOR COLUMN ' + %Trim(Msk_DsInput.IN_Campo) +
                               ' RETURN CASE WHEN (SESSION_USER IN (' +
                              '''' + %Trim(Msk_DsInput.IN_NomUte) + '''' + ')) +
                     THEN ' +  %Trim(Msk_DsInput.IN_Campo) + ' ELSE';

                If (Msk_DsInput.IN_TipoDato = 'INTEGER') Or
                   (Msk_DsInput.IN_TipoDato = 'DECIMAL') Or
                   (Msk_DsInput.IN_TipoDato = 'SMALLINT') Or
                   (Msk_DsInput.IN_TipoDato = 'NUMERIC');
                     WRetVal = '0';
                  CmdMsk = %Trim(CmdMsk) + ' ' +
                           %Trim(WRetVal) + ' END ENABLE';
                Else;
                  For i = 1 To Msk_DsInput.IN_LungDato ;
                    WRetVal = %Trim(WRetVal) + '*';
                  EndFor;
                  CmdMsk = %Trim(CmdMsk) + '''' + %Trim(WRetVal) +
                                     '''' + ' END ENABLE';
                EndIf;
                Exec Sql
                  PREPARE ADDUSRMASK FROM :CmdMsk;
                Exec Sql
                  EXECUTE ADDUSRMASK;
                If (SqlStt <> '00000');
                  ErrorMsg ='CREATE OR REPLACE MASK per aggiunta utente +
                             terminato con errori. SQLSTT = ' + SqlStt +
                             ' verificare.';
                  Msk_DsInput.OUT_Error = *On;
                  SendPgmMsg( 'CPF9897'
                             :'QCPFMSG *LIBL'
                             :Msk_DsInput.OUT_ErrorMsg
                             : %len( %trimr(Msk_DsInput.OUT_ErrorMsg) )
                             : '*INFO': '*'
                             : 0: MsgKey
                             : ErrorCode );
                Else;
                   //Applico constraint a campo per evitare scrittura dati
                   // anomala
                   CmdMsk = 'ALTER TABLE ' + %Trim(Msk_DsInput.IN_LibNom) +
                                    '/' + %Trim(Msk_DsInput.IN_FilNom) +
                      ' ADD CONSTRAINT CST_MSK_' + %Trim(Msk_DsInput.IN_FilNom)+
                         '_' + %Trim(Msk_DsInput.IN_Campo) + ' CHECK (' +
                      %Trim(Msk_DsInput.IN_Campo) + ' <> ';
                   If (Msk_DsInput.IN_TipoDato = 'INTEGER') Or
                      (Msk_DsInput.IN_TipoDato = 'DECIMAL') Or
                      (Msk_DsInput.IN_TipoDato = 'SMALLINT') Or
                      (Msk_DsInput.IN_TipoDato = 'NUMERIC');
                        WRetVal = '0';
                   Else;
                     For i = 1 To Msk_DsInput.IN_LungDato ;
                       WRetVal = %Trim(WRetVal) + '*';
                     EndFor;
                     CmdMsk = %Trim(CmdMsk) + '''' + %Trim(WRetVal) + '''';
                   EndIf;
                   CmdMsk = %Trim(CmdMsk) + ') ON UPDATE VIOLATION PRESERVE ' +
                         %Trim(Msk_DsInput.IN_Campo);
                   Exec Sql
                     PREPARE ADDCST FROM :CmdMsk;
                   Exec SQl
                     EXECUTE ADDCST;
                   If (SqlStt <> '00000');
                     Msk_DsInput.OUT_ErrorMsg ='ADD CONSTRAINT +
                             terminato con errori. SQLSTT = ' + SqlStt +
                             ' verificare.';
                     Msk_DsInput.OUT_Error = *On;
                     SendPgmMsg( 'CPF9897'
                                :'QCPFMSG *LIBL'
                                :Msk_DsInput.OUT_ErrorMsg
                                : %len( %trimr(Msk_DsInput.OUT_ErrorMsg) )
                                : '*INFO': '*'
                                : 0: MsgKey
                                : ErrorCode );
                   EndIf;
                EndIf;
             EndIf;
        End-Proc;

        Dcl-Proc CrtRplMask;
        dcl-pi CrtRplMask;
          p_DsInput  likeds(DsInput);
          P_Ds_SysControls likeds(Ds_SysControls);
        end-pi;

        Dcl-ds Ds_SysControls qualified;
            RuleText char(256);
            RuleOk Ind;
        End-Ds;
        Dcl-s CmdMsk1 char(256);
        Dcl-s NomeUtente char(10);
        Dcl-s WRetVal    char(256);
        Dcl-s PosI       Zoned(5:0);
        Dcl-s Pos1       Zoned(5:0);
        Dcl-s Pos2       Zoned(5:0);
        Dcl-s EndStringUser  Zoned(5:0);
        Dcl-s i          Zoned(5:0);
        Dcl-s ErrorMsg   char(80);
        Dcl-s Nbruser    Zoned(5:0);

                Clear NbrUser;
                PosI = 1;
              CmdMsk1 = 'CREATE OR REPLACE MASK ' + %Trim(p_DsInput.IN_MasNom) +
                               ' ON ' + %Trim(p_DsInput.IN_LibNom) +
                                  '/' + %Trim(p_DsInput.IN_FilNom) +
                               ' FOR COLUMN ' + %Trim(p_DsInput.IN_Campo) +
                               ' RETURN CASE WHEN (SESSION_USER IN (' +
                               '''' ;
                EndStringUser = %Scan('THEN':p_Ds_SysControls.RuleText);

                Pos1 = %Scan('''':p_Ds_SysControls.RuleText:PosI);
                Dow (Pos1 < EndStringUser);
                 If (Pos1 = 0);
                   Leave;
                 EndIf;
                 PosI = Pos1 +1;
                 Pos2 = %Scan('''':p_Ds_SysControls.RuleText:PosI);
                 If (Pos2 < EndStringUser);
                   NomeUtente =
                     %Subst(p_Ds_SysControls.RuleText:Pos1+1:Pos2-(Pos1+1));
        //Se p_DsInput.IN_MasCam = 'N' "salto" l'utente da rimuovere
                   If (p_DsInput.IN_MasCam = 'N') And
                     (p_DsInput.IN_NomUte = NomeUtente);
                     Iter;
                   EndIf;

                   CmdMsk1 = %Trim(CmdMsk1) + %Trim(Nomeutente) +
                            '''' + ', ' + '''';
                   NbrUser = NbrUser +1;
                 EndIf;
                 Pos1  = Pos2   ;
                Enddo;
                If (p_DsInput.IN_MasCam = 'S');
                  CmdMsk1 = %Trim(CmdMSk1) + %Trim(p_DsInput.IN_NomUte) + '''';
                EndIf;
                // Se elimino ultimo utente autorizzato al campo (NbrUser = 0 )
                // rimuovo maschera
                If (NbrUser > 0);
                     CmdMsk1 = %Trim(CmdMsk1) + ')) THEN ' +
                     %Trim(p_DsInput.IN_Campo) +
                   ' ELSE ';
                   If (p_DsInput.IN_TipoDato = 'INTEGER') Or
                      (p_DsInput.IN_TipoDato = 'DECIMAL') Or
                      (p_DsInput.IN_TipoDato = 'SMALLINT') Or
                      (p_DsInput.IN_TipoDato = 'NUMERIC');
                        WRetVal = '0';
                   Else;
                     For i = 1 To p_DsInput.IN_LungDato ;
                       WRetVal = %Trim(WRetVal) + '*';
                     EndFor;
                     CmdMsk1 = %Trim(CmdMsk1) + '''' + %Trim(WRetVal) +
                                     '''' + ' END ENABLE';
                   EndIf;
                   Exec Sql
                     PREPARE ADDUSRMASK FROM :CmdMsk1;
                   Exec Sql
                     EXECUTE ADDUSRMASK;
                   If (SqlStt = '00000');
                       p_DsInput.OUT_ErrorMsg ='CREATE OR REPLACE MASK per +
                             aggiunta/rimozione utente +
                             terminato correttamente SQLSTT = ' + SqlStt ;
                       p_DsInput.OUT_Error = *On;
                       SendPgmMsg( 'CPF9897'
                             :'QCPFMSG *LIBL'
                             :p_DsInput.OUT_ErrorMsg
                             : %len( %trimr(p_DsInput.OUT_ErrorMsg) )
                             : '*INFO': '*': 0
                             : MsgKey: ErrorCode );
                   EndIf;
                Else;
                   CmdMsk1 = 'DROP MASK ' + %Trim(p_DsInput.IN_MasNom) ;
                   Exec Sql
                     PREPARE DROPMASK FROM :CmdMsk1;
                   EXEC sQL
                     EXECUTE DROPMASK;
                   If (SqlStt = '00000');
                       p_DsInput.OUT_ErrorMsg ='DROP MASK per maschera ' +
                             %Trim(p_DsInput.IN_MasNom) +
                             ' terminato con errori. SQLSTT = ' + SqlStt +
                             ' verificare';
                       p_DsInput.OUT_Error = *On;
                       SendPgmMsg( 'CPF9897'
                             :'QCPFMSG *LIBL'
                             :p_DsInput.OUT_ErrorMsg
                             : %len( %trimr(p_DsInput.OUT_ErrorMsg) )
                             : '*INFO': '*': 0
                             : MsgKey: ErrorCode );
                  Else;
                    CmdMsk1 = 'ALTER TABLE ' + (p_DsInput.IN_LibNom) +
                                  '/' + %Trim(p_DsInput.IN_FilNom) +
                                  ' DROP CHECK CST_MSK_' +
                                  %Trim(P_DsInput.IN_FilNom)+
                                '_' + %Trim(P_DsInput.IN_Campo) ;
                    Exec Sql
                     PREPARE DROPCST FROM :CmdMsk1;
                    Exec Sql
                     EXECUTE DROPCST;
                    If (SqlStt <> '00000');
                       p_DsInput.OUT_ErrorMsg ='ALTER TABLE PER DROP CHECK +
                             terminato con errori. SQLSTT = ' + SqlStt +
                             ' verificare';
                       p_DsInput.OUT_Error = *On;
                       SendPgmMsg( 'CPF9897'
                             :'QCPFMSG *LIBL'
                             :p_DsInput.OUT_ErrorMsg
                             : %len( %trimr(p_DsInput.OUT_ErrorMsg) )
                             : '*INFO': '*': 0
                             : MsgKey: ErrorCode );
                    EndIf;

                   EndIf;

                  EndIf;

        End-Proc;
