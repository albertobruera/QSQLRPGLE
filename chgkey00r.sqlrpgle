
           dcl-pr UpdFprMSk ExtPgm('UPDFPRMSK');
            p_Ds_ListFil LikeDs(Ds_ListFil);
           end-pr;
           dcl-ds Ds_ListaCampi qualified;
             NomeLibreria char(10);
             NomeFile     char(10);
             NomeCampo    char(10);
             TipoDato     char(10);
             LungDato     int(10);
           end-ds;
           dcl-ds Ds_UpdFpr qualified;
             NomeLibreria char(10);
             NomeFile     char(10);
             NomeCampo    char(10);
             TipoDato     char(10);
             LungDato     int(10);
             CampoCrit    char(1);
             LibPgmFldPrc char(10);
             PgmFldPrc    char(10)
             CampoMask    char(1);
             NomeMask     char(256);
             NomeUtente   car(10);
             IndErrore    Ind;
           end-ds;
           dcl-s Cmd Char(256);
         Exec Sql
         Declare ListFil scroll cursor for
            select fl_lib, fl_file, fl_campo,
                   fl_tipdat, fl_lundat
              from FILLST00F
              Where  fl_critcam = 'S'
            group by fl_lib , fl_file, fl_campo,
                     fl_tipdat, fl_lundat;
         Exec Sql
         Open ListFil;
         Exec Sql
         Fetch ListFil Into :Ds_ListaCampi;
         DoW (SqlStt = '00000') And (DS_UpdFprMSk.IndError = *Off);
                  Ds_UpdFprMsk = DS_ListaCampi;
                  Ds_UpdFprMsk.CampoCrit = 'N';
                  UpdFprMsk(Ds_UpdFprMsk);

           Exec Sql
             Fetch next ListFil Into :Ds_ListaCampi;
         EndDo;

            //Rimozione chiave da keystore
         Cmd = 'RMVCKMKSFE KEYSTORE(KEYSTORE01) RCDLBL(pippopluto)';

            //Generazione chiave in keystore
        Cmd ='GENCKMKSFE KEYSTORE(KEYSTORE01) RCDLBL(pippoplut) KEYTYPE(*AES) +
               KEYSIZE(128) DISALLOW(*NONE)';
           Exec Sql
             Fetch prior ListFil Into :Ds_ListaCampi;
         DoW (SqlStt = '00000') And (DS_UpdFprMSk.IndError = *Off);
                  Ds_UpdFprMsk = DS_ListaCampi;
                  Ds_UpdFprMsk.CampoCrit = 'S';
                  UpdFprMsk(Ds_UpdFprMsk);

           Exec Sql
             Fetch prior ListFil Into :Ds_ListaCampi;
         EndDo;
