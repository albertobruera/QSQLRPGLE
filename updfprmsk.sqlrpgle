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

        dcl-ds DsInput ExtName('FILLST00F') qualified Prefix(IN_:3);
          OUT_Error        Ind ;        //Indicatore presenza messaggio di rit.
          OUT_ErrorMsg     char(256);   //Messaggio di errore
        end-ds;
        Dcl-s Set_Cmd      char(256);
        Dcl-s Drop_Cmd      char(256);


        Dcl-Proc UpdFprocMask export;
        Dcl-pi UpdFprocMask;
          p_DsInput LikeDs(DsInput);
        end-pi;
         p_DsInput.OUT_Error = *Off;
         If (p_DsInput.IN_Campo = *blanks) or (p_DsInput.IN_Lib = *blanks) or
           (p_DsInput.IN_File = *blanks) or
           ((p_DsInput.IN_CritCam = *blank) and (p_DsInput.IN_MasCam = *blank));
          DsInput.OUT_Error = *On;
         EndIf;
         If (p_DsInput.IN_CritCam = 'S') and ((p_DsInput.IN_FprLPgm = *blanks)
           or (p_DsInput.IN_FprPgm = *blanks));
          DsInput.OUT_Error= *On;
         EndIf;
         If (p_DsInput.IN_MasCam = 'S') and ((p_DsInput.IN_MasNom = *blanks) or
           (p_DsInput.IN_Utente = *blanks));
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
             p_DsInput.OUT_ErrorMsg = 'ENC0024';
             SendPgmMsg( 'CPF9897'
                     :'ENCMSKSMGF ALBERTODTA'
                     :'ENC0024'
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
           Set_Cmd = 'ALTER TABLE  ' + %Trim(Crypt_DsInput.IN_Lib) + '/' +
                                     %Trim(Crypt_DsInput.IN_File ) +
                  ' ALTER COLUMN ' + %Trim(Crypt_DsInput.IN_Campo) +
                  ' SET FIELDPROC ' + %Trim(Crypt_DsInput.IN_FprLPgm) + '/' +
                                      %Trim(Crypt_DsInput.IN_FprPgm);
            Exec Sql
              PREPARE SETFLDPRC FROM :Set_CMD;
            Exec Sql
              EXECUTE SETFLDPRC;
            If (SqlStt <> '00000');
              Crypt_DsInput.OUT_Error= *On;
              Crypt_DsInput.OUT_ErrorMsg = 'ENC0006';
              SendPgmMsg( 'ENC0006'
                         :'ENCMSKMSGF *LIBL'
                         :Crypt_DsInput.OUT_ErrorMsg
                         : %len( %trimr(Crypt_DsInput.OUT_ErrorMsg) )
                         : '*INFO': '*': 0
                         :MsgKey: ErrorCode );
            Else;
              Crypt_DsInput.OUT_ErrorMsg = 'ENC0008';
              Crypt_DsInput.OUT_Error = *Off;

            EndIf;
          ElseIf (Crypt_DsInput.IN_CritCam = 'N');
            Drop_Cmd = 'ALTER TABLE  ' + %Trim(Crypt_DsInput.IN_Lib) + '/' +
                                     %Trim(Crypt_DsInput.IN_File ) +
                  ' ALTER COLUMN ' + %Trim(Crypt_DsInput.IN_Campo) +
                  ' DROP FIELDPROC ';

            Exec Sql
              PREPARE DROPFLDPRC FROM :Drop_CMD;
            Exec Sql
              EXECUTE DROPFLDPRC;
            If (SqlStt <> '00000');
              Crypt_DsInput.OUT_ErrorMsg = 'ENC0005';
              Crypt_DsInput.OUT_Error = *On;
              SendPgmMsg( 'ENC0005'
                         :'ENCMSKMSGF *LIBL'
                         :Crypt_DsInput.OUT_ErrorMsg
                         : %len( %trimr(Crypt_DsInput.OUT_ErrorMsg) )
                         : '*INFO': '*': 0
                         : MsgKey: ErrorCode );
            Else;
              Crypt_DsInput.OUT_ErrorMsg = 'ENC0008';
              Crypt_DsInput.OUT_Error = *Off;
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
                WHERE TABLE_SCHEMA = :Msk_DsInput.IN_Lib
                  AND TABLE_NAME   = :Msk_DsInput.IN_File;
             If (Counter = 0);
                CmdMsk = 'ALTER TABLE ' + %Trim(Msk_DsInput.IN_Lib) + '/' +
                                 %Trim(Msk_DsInput.IN_File) +
                      ' ACTIVATE COLUMN ACCESS CONTROL';
                Exec Sql
                  PREPARE ACTRCAC FROM :CmdMsk;
                Exec Sql
                  EXECUTE ACTRCAC;
                If (SqlStt <> '00000');
                  Msk_DsInput.OUT_ErrorMsg ='MSK0006';
                  Msk_DsInput.OUT_Error = *On;
                  SendPgmMsg( 'MSK0006'
                         :'ENCMSKMSGF *LIBL'
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
                WHERE TABLE_SCHEMA = :Msk_DsInput.IN_Lib
                  AND TABLE_NAME   = :Msk_DsInput.IN_File
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
                               ' ON ' + %Trim(Msk_DsInput.IN_Lib) +
                                  '/' + %Trim(Msk_DsInput.IN_File) +
                               ' FOR COLUMN ' + %Trim(Msk_DsInput.IN_Campo) +
                               ' RETURN CASE WHEN (SESSION_USER IN (' +
                              '''' + %Trim(Msk_DsInput.IN_Utente) + '''' + ')) +
                     THEN ' +  %Trim(Msk_DsInput.IN_Campo) + ' ELSE';

                If (Msk_DsInput.IN_TipDat = 'INTEGER') Or
                   (Msk_DsInput.IN_TipDat = 'DECIMAL') Or
                   (Msk_DsInput.IN_TipDat = 'SMALLINT') Or
                   (Msk_DsInput.IN_TipDat = 'NUMERIC');
                     WRetVal = '0';
                  CmdMsk = %Trim(CmdMsk) + ' ' +
                           %Trim(WRetVal) + ' END ENABLE';
                Else;
                  For i = 1 To Msk_DsInput.IN_LunDat ;
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
                  Msk_DsInput.OUT_ErrorMsg ='MSK0006';
                  Msk_DsInput.OUT_Error = *On;
                  SendPgmMsg( 'MSK0006'
                             :'ENCMSKMSGF *LIBL'
                             :Msk_DsInput.OUT_ErrorMsg
                             : %len( %trimr(Msk_DsInput.OUT_ErrorMsg) )
                             : '*INFO': '*'
                             : 0: MsgKey
                             : ErrorCode );
                Else;
                   //Applico constraint a campo per evitare scrittura dati
                   // anomala
                   CmdMsk = 'ALTER TABLE ' + %Trim(Msk_DsInput.IN_Lib) +
                                    '/' + %Trim(Msk_DsInput.IN_File) +
                      ' ADD CONSTRAINT CST_MSK_' + %Trim(Msk_DsInput.IN_File)+
                         '_' + %Trim(Msk_DsInput.IN_Campo) + ' CHECK (' +
                      %Trim(Msk_DsInput.IN_Campo) + ' <> ';
                   If (Msk_DsInput.IN_TipDat = 'INTEGER') Or
                      (Msk_DsInput.IN_TipDat = 'DECIMAL') Or
                      (Msk_DsInput.IN_TipDat = 'SMALLINT') Or
                      (Msk_DsInput.IN_TipDat = 'NUMERIC');
                        WRetVal = '0';
                   Else;
                     For i = 1 To Msk_DsInput.IN_LunDat ;
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
                     Msk_DsInput.OUT_ErrorMsg ='MSK0006';
                     Msk_DsInput.OUT_Error = *On;
                     SendPgmMsg( 'MSK0006'
                                :'ENCMSKMSGF *LIBL'
                                :Msk_DsInput.OUT_ErrorMsg
                                : %len( %trimr(Msk_DsInput.OUT_ErrorMsg) )
                                : '*INFO': '*'
                                : 0: MsgKey
                                : ErrorCode );
                   EndIf;
                EndIf;
             EndIf;
                If (SqlStt = '00000');
                    Msk_DsInput.Out_Error = *Off;
                    Msk_DsInput.Out_ErrorMsg = 'MSK0007'; // Term OK
                Else;
                    Msk_DsInput.Out_Error = *On;
                    Msk_DsInput.Out_ErrorMsg = 'MSK0006'; // Term NO OK
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
        Dcl-s CmdMsk1 char(2048);
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
                               ' ON ' + %Trim(p_DsInput.IN_Lib) +
                                  '/' + %Trim(p_DsInput.IN_File) +
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
                     (p_DsInput.IN_Utente = NomeUtente);
                     Pos1 = %Scan('''':p_Ds_SysControls.RuleText:Pos2+1);
                     Iter;
                   EndIf;

                   CmdMsk1 = %Trim(CmdMsk1) + %Trim(Nomeutente) +
                            '''' + ', ' + '''';
                   NbrUser = NbrUser +1;
                 EndIf;
                 Pos1 = %Scan('''':p_Ds_SysControls.RuleText:Pos2+1);
                Enddo;
                If (p_DsInput.IN_MasCam = 'S');
                  CmdMsk1 = %Trim(CmdMSk1) + %Trim(p_DsInput.IN_Utente) + '''';
                Else;
                  CmdMsk1 = %Subst(CmdMSk1:1:(%Len(%Trim(CmdMsk1)) -3));
                EndIf;
                // Se elimino ultimo utente autorizzato al campo (NbrUser = 0 )
                // rimuovo maschera
                If (NbrUser > 0);
                     CmdMsk1 = %Trim(CmdMsk1) + ')) THEN ' +
                     %Trim(p_DsInput.IN_Campo) +
                   ' ELSE ';
                   If (p_DsInput.IN_TipDat = 'INTEGER') Or
                      (p_DsInput.IN_TipDat = 'DECIMAL') Or
                      (p_DsInput.IN_TipDat = 'SMALLINT') Or
                      (p_DsInput.IN_TipDat = 'NUMERIC');
                        WRetVal = '0';
                   Else;
                     For i = 1 To p_DsInput.IN_LunDat ;
                       WRetVal = %Trim(WRetVal) + '*';
                     EndFor;
                    EndIf;

                    CmdMsk1 = %Trim(CmdMsk1) + '''' + %Trim(WRetVal) +
                                     '''' + ' END ENABLE';

                   Exec Sql
                     PREPARE ADDUSRMASK FROM :CmdMsk1;
                   Exec Sql
                     EXECUTE ADDUSRMASK;
                   If (SqlStt = '00000');
                       p_DsInput.OUT_ErrorMsg ='MSK0007' ;
                       //p_DsInput.OUT_Error = *On;
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
                    CmdMsk1 = 'ALTER TABLE ' + (p_DsInput.IN_Lib) +
                                  '/' + %Trim(p_DsInput.IN_File) +
                                  ' DROP CHECK CST_MSK_' +
                                  %Trim(P_DsInput.IN_File)+
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
