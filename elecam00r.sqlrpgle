        dcl-f cfgdsp00v workstn IndDs(Dspf) sfile(ELECAMSFL:EC1);

        Dcl-pr ElencoCampi;
          p_NomeLibreria char(10);	
          p_NomeFile 	 char(10);
          p_NomeCampo	 char(10);
          p_TipoDato     char(10);
          p_LunDat       packed(10:0);
          p_MasNom       char(35);
        end-pr;

		      dcl-ds Ds_ElencoCampi qualified;
			      EC_NomeLibreria	char(10);
			      EC_Nomefile		char(10);
			      EC_NomeCampo	char(10);
			      EC_TipoDato		char(10);
			      EC_Lunghezza	Int(10);
			      EC_StatoMasc	char(1);
			      EC_NomeMask   char(35);
		      end-ds;
        dcl-ds Dspf qualified ;
             Exit ind pos(03) ;
             Refresh ind pos(05) ;
             InsertInd ind pos(06);
             SflMask ind pos(08);
             SflFProc ind pos(07);
             Annulla  ind pos(12);
             SflDrop ind pos(09);
             SflDsp ind pos(31) ;
             SflDspCtl ind pos(32) ;
             SflClr ind pos(33);
             SflEnd ind pos(34);
             EnableDrop ind pos(75);
             DatiNonInDB ind pos(80);
             MessageInd ind pos(90) inz('0');
        end-ds ;

        Dcl-Proc ElencoCampi export;
        Dcl-pi ElencoCampi;
          p_NomeLibreria char(10);	
          p_NomeFile 	 char(10);
          p_NomeCampo	 char(10);	
          p_TipoDato     char(10);
          p_LunDat       packed(10:0);
          P_MasNom       char(35);
        end-pi;

		      Dspf.Annulla = '0';
		      EC_SCELTA = ' ';
		      Dow (Dspf.Annulla = *Off) And (EC_SCELTA = ' ');
			      LoadSfl( p_NomeLibreria 	
 		      	        :p_NomeFile
					            );
				     Write PIEDEELEC;
			      Exfmt ELECAMCTL;
		
			      If (Dspf.Annulla = *On);
				      leave;
			      EndIf;
			      ReadC ELECAMSFL;
			      If Not %EoF;
				      p_NomeCampo = EC_CAMPO;
				      p_TipoDato = EC_TIPDAT;
				      p_LunDat   = EC_LUNG;
				      p_MasNom   = EC_MASNOM;
			      EndIf;
		      EndDo;	
		      *InLr = *On ;
		      End-Proc;
		
		       Dcl-Proc LoadSfl;
			       dcl-pi LoadSfl;
          		LS_NomeLibreria char(10);	
          		LS_NomeFile 	 char(10);
			       end-pi;

    	     Dspf.SflDspCtl = *off ;
        	 Dspf.SflDsp = *off ;
        	 Dspf.SflClr = *On;
        	 write ELECAMCTL;
        	 Dspf.SflClr = *Off;
        	 Dspf.SflDspCtl = *on ;

        	 EC_SCELTA = ' ' ;
         	Clear ec1;

			       Exec Sql
				       Declare ElencoCampi Cursor for
				       SELECT SC.SYSTEM_TABLE_SCHEMA,
				              SC.SYSTEM_TABLE_NAME,
				              SC.SYSTEM_COLUMN_NAME,
				              SC.DATA_TYPE,
				              SC.LENGTH,
				              COALESCE(FL.FL_MASCAM, 'N'),
				              SUBSTRING(COALESCE(FL.FL_MASNOM, ' '), 1, 35)
				         FROM FILLST00F FL RIGHT JOIN QSYS2/SYSCOLUMNS SC
				           ON FL.FL_LIB   = SC.SYSTEM_TABLE_SCHEMA
				          AND FL.FL_FILE  = SC.SYSTEM_TABLE_NAME
				          AND FL.FL_CAMPO = SC.SYSTEM_COLUMN_NAME
              WHERE SC.SYSTEM_TABLE_SCHEMA = :LS_NomeLibreria
                AND SC.SYSTEM_TABLE_NAME = :LS_NomeFile
               AND (SC.SYSTEM_COLUMN_NAME = :R_CAMPO or :R_CAMPO = ' ')
               GROUP BY SC.SYSTEM_TABLE_SCHEMA,
                              SC.SYSTEM_TABLE_NAME,
                              SC.SYSTEM_COLUMN_NAME,
                              SC.DATA_TYPE,
                              SC.LENGTH,
                              COALESCE(FL.FL_MASCAM, 'N'),
                              SUBSTRING(COALESCE(FL.FL_MASNOM, ' '), 1, 35);
			       Exec Sql
				       Open ElencoCampi;
			         Exec Sql
				         Fetch ElencoCampi Into :Ds_ElencoCampi;
			
			       Dow (SqlStt = '00000');
				       EC_LIBNOM = Ds_ElencoCampi.EC_Nomelibreria;
				       EC_FILNOM = Ds_ElencoCampi.EC_NomeFile;
				       EC_CAMPO = Ds_ElencoCampi.EC_NomeCampo;
				       EC_TIPDAT = Ds_ElencoCampi.EC_TipoDato;
				       EC_LUNG  = Ds_ElencoCampi.EC_Lunghezza;
				       EC_STATO = Ds_ElencoCampi.EC_StatoMasc;
				       EC_MASNOM = Ds_ElencoCampi.EC_NomeMask;
				
				       EC1 = EC1 +1;
				       Write ELECAMSFL;
				       Exec Sql
				       	Fetch ElencoCampi Into :Ds_ElencoCampi;
			       EndDo;
          If (EC1 > 0);
            Dspf.SflDsp = *on ;
          EndIf;
			
		        End-Proc;	
