        //ctl-opt dftactgrp(*no) ; //Option(*nodebugio:*srcstmt:*nounref)       
        dcl-f cfgdsp00v workstn IndDs(Dspf) sfile(FPRCSFL:FPRC1)                
                                            sfile(MSKSFL:MSK1)  ;               
                                                                                
        dcl-pr UpdFproc;                                                        
          p_Ds_UpdFProc Like(DS_UpdFProc);                                      
        end-pr;                                                                 
                                                                                
        dcl-pr UpdMask;                                                         
          p_Ds_UpdMask Like(DS_UpdMask);                                        
        end-pr;                                                                 
        Dcl-pr FindAutUsr;                                                      
          SourceString varChar(256);                                            
          NomeUtente   Char(10);                                                
          PosI         zoned(5:0);                                              
          CheckRule    Ind; 	                                                   
          EndProc      Ind;                                                     
        End-pr;                                                                 
                                                                                
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
        dcl-ds DS_FProc ExtName('FILLST00F') qualified Prefix(UF_:3);                                             
        end-ds;          
        
        dcl-ds DS_UpdFProc ExtName('FILLST00F') qualified Prefix(UF_:3);  
        	UF_Message 		char(125);
        	UF_MessageInd 	Ind;
        end-ds;       
        
        dcl-ds DS_FProc2 ExtName('FILLST00F') qualified Prefix(UF_:3);                                             
        end-ds;         
        
        dcl-ds Ds_Mask ExtName('FILLST00F') qualified Prefix(UM_:3);                                               
           //M_Lib       char(10);                                                
           //M_File      char(10);                                                
           //M_Cam       char(10);                                                
           //M_TipDat    char(10);                                                
           //M_LunDat     int(10);                                                
           //M_MasCam    char(1);                                                 
           //M_MasNom    char(256)      ;                                         
           //M_NomUte    char(10)  ;                                              
           UM_RuleText  varchar(256);                                            
        end-ds;                                                                 
                                                                                
        dcl-ds Ds_CrtMask qualified;                                            
           M_NomUte    char(10)  ;                                              
           M_TipDat    char(10);                                                
           M_Lunghezza Int(10);                                                 
           M_NumSca    Int(10);                                                 
        end-ds;                                                                 
                                                                                
        dcl-ds Ds_UpdMask ExtName('FILLST00F') qualified Prefix(UM_:3);                                            
          //UM_Lib       char(10);                                                
          //UM_File      char(10);                                                
          //UM_Cam       char(10);                                                
          //UM_TipDat    char(10);                                                
          //UM_LunDat     int(10);                                                
          //UM_MasCam    char(1);                                                 
          //UM_MasNom    char(256);                                               
          //UM_NomUte    char(10)  ;                                              
        //      UM_RuleText  varchar(256);                                      
          UM_Message   char(125);                                               
          UM_InsertInd    ind  inz('0');                                        
          UM_MessageInd   ind  inz('0');                                        
        end-ds;                                                                 
                                                                                
        dcl-ds Ds_FilLst ExtName('FILLST00F') qualified;                        
        end-ds;                                                                 
                                                                                
        dcl-s p_PosI Zoned(5:0);                                                
                                                                                
        dcl-s Counter 		Zoned(4:0);                                             
        dcl-s Cmd 			char(256);                                                 
        dcl-s Resp 			char(1) inz('0');                                         
        dcl-s w_LibFile 	char(21) ;                                             
        dcl-s Error 		Ind;                                                      
        dcl-s Fine 			Ind;                                                      
        dcl-s p_NomeUtente 	char(10);                                           
        dcl-s p_CheckRule		Ind;                                                 
                                                                                
        Dow Dspf.Exit = *Off;                                                   
         LoadSflFpr();                                                          
         Write PIEDEFPRC;                                                       
         ExFmt FPRCCTL;                                                         
         Dspf.MessageInd = *Off;                                                
         Error = *Off;                                                          
         Dspf.DatiNonInDB = *Off;                                               
                                                                                
         If (R_LIB = *Blanks);                                                  
           PRCERRMSG = 'Nome libreria obbligatorio.';                           
           Dspf.MessageInd = *On;                                               
           Iter;                                                                
         EndIF;                                                                 
                                                                                
         If (R_LIB = *Blanks);                                                  
           PRCERRMSG = 'Nome file obbligatorio.';                               
           Dspf.MessageInd = *On;                                               
           Iter;                                                                
         EndIF;                                                                 
         If (FPRC1 > 0);                                                        
           Readc FPRCSFL;                                                       
           Dow Not(%EoF) And (Dspf.Annulla = *Off);                             
             If (F_SCELTA = 'M');                                               
               Ds_UpdFProc.UF_Lib  = F_LIBNOM;                                  
               Ds_UpdFProc.UF_File = F_FILNOM;                                  
               Ds_UpdFProc.UF_Campo   = F_CAMPO;                                  
               Ds_UpdFProc.UF_CritCam  = F_CRITCAM;                             
               Ds_UpdFProc.UF_FprLPgm = F_LIBFLDPR;                            
               Ds_UpdFProc.UF_FprPgm = F_NOMPGMFP;                           
               Ds_UpdFProc.UF_MessageInd = Dspf.MessageInd;                     
               UpdFProc(Ds_UpdFProc);                                           
               Dspf.MessageInd = Ds_UpdFProc.UF_MessageInd;                     
               PRCERRMSG = Ds_UpdFProc.UF_Message;                              
             EndIF;                                                             
             If (Dspf.MessageInd = *Off);                                       
               ReadC FPRCSFL;                                                   
             Else;                                                              
               Leave;                                                           
             EndIf;                                                             
           EndDo;                                                               
          EndIF;                                                                
                                                                                
         M_MODE = '0';                                                          
         If (Dspf.SflMask = *On);                                               
                                                                                
           Dow (Dspf.exit = *Off) And (Dspf.SflFproc = *Off);                   
             Dspf.EnableDrop =*On;                                              
             LoadSflMsk();                                                      
             Write PIEDEMSK;                                                    
             ExFmt MSKCTL;                                                      
             Dspf.MessageInd = *Off;                                            
             Dspf.DatiNonInDB = *Off;                                           
                                                                                
             If (Dspf.SflFProc = *On);                                          
               Dspf.SflMask = *Off;                                             
             EndIf;                                                             
             If (Dspf.SflDrop = *On) and (M_MODE = '0');                        
               M_MODE = '1';                                                    
               Dspf.EnableDrop = *On;                                           
             Else ;                                                             
               If (Dspf.SflDrop = *On) and (M_MODE = '1');                      
               M_MODE = '0';                                                    
               Dspf.EnableDrop =*Off;                                           
               EndIf;                                                           
             EndIf;                                                             
             If (M_LIBNOM = *Blanks);                                           
               PRCERRMSG = 'Nome libreria obbligatorio.';                       
               Dspf.MessageInd = *On;                                           
               Iter;                                                            
             EndIF;                                                             
             If (Dspf.InsertInd = *On);                                         
                   Ds_UpdMask.UM_Lib  = M_LIBNOM;                               
                   Ds_UpdMask.UM_File = M_FILNOM;                               
                   Ds_UpdMask.UM_TipDat = M_TIPODAT;                            
                   Ds_UpdMask.UM_LunDat = M_LUNG;                               
                   DS_UpdMask.UM_MasCam = 'S';                                  
                   Ds_UPdMask.UM_InsertInd = Dspf.InsertInd;                    
                   UpdMask(Ds_UpdMask);                                         
                   Dspf.MessageInd = Ds_UpdMask.UM_MessageInd;                  
                   ERRMSGMSK = Ds_UpdMask.UM_Message;                           
             EndIf;                                                             
             If (MSK1 > 0);                                                     
               ReadC MSKSFL;                                                    
               Dow Not(%EoF) And (Dspf.Annulla = *Off);                         
                 If (M_SCELTA = 'M');                                           
                   Ds_UpdMask.UM_Lib  = M_LIBNOM;                               
                   Ds_UpdMask.UM_File = M_FILNOM;                               
                   Ds_UpdMask.UM_Campo   = M_CAMPO;                               
                   Ds_UpdMask.UM_MasCam  = M_MASCAM;                            
                   Ds_UpdMask.UM_MasNom = M_MASNOM;                             
                   Ds_UpdMask.UM_TipDat = M_TIPODAT;                            
                   Ds_UpdMask.UM_LunDat = M_LUNG;                               
                   Ds_UpdMask.UM_Utente = M_NOMUTE;                             
                                                                                
               //    Ds_UpdMask.UM_RuleText = M_RULETEXT;                       
                   Ds_UpdMask.UM_MessageInd = Dspf.MessageInd;                  
                   UpdMask(Ds_UpdMask);                                         
                   Dspf.MessageInd = Ds_UpdMask.UM_MessageInd;                  
                   ERRMSGMSK = Ds_UpdMask.UM_Message;                           
                 EndIf;                                                         
                 If (Dspf.MessageInd = *Off);                                   
                   Readc MSKSFL;                                                
                 Else;                                                          
                   Leave;                                                       
                 EndIf;                                                         
               EndDo;                                                           
             EndIF;                                                             
           Enddo;                                                               
                                                                                
         EndIf;                                                                 
                                                                                
        EndDo;                                                                  
        *InLr = *On;                                                            
       //*********************************************************************  
                                                                                
                                                                                
       dcl-Proc LoadSflMsk ;                                                    
                                                                                
         Dspf.SflDspCtl = *off ;                                                
         Dspf.SflDsp = *off ;                                                   
         Dspf.SflClr = *On;                                                     
         write MSKCTL ;                                                         
         Dspf.SflClr = *Off;                                                    
         Dspf.SflDspCtl = *on ;                                                 
                                                                                
         M_SCELTA = ' ' ;                                                       
         Clear FPRC1;                                                           
         Clear MSK1;                                                            
                                                                                
         If (R_MLIB <> *blanks) Or (R_LIB <> *blanks);                          
            If (R_MLIB = *blanks) And (R_LIB <> *blanks);                       
               R_MLIB = R_LIB;                                                  
               R_MFILE = R_FILE;                                                
            EndIf;                                                              
                                                                                
           Exec Sql                                                             
            declare MaskCsr cursor for                                          
             select  fl.*, sc.coalesce(ruletext, ' ')                                    
               from fillst00f fl left join qsys2.syscontrols sc                       
                 on fl.fl_lib = sc.table_schema and                                   
                    fl.fl_file = sc.table_name  and                                   
                    fl.fl_campo = sc.column_name                                      
                    where                                                       
                    (fl_lib = :R_MLIB Or :R_MLIB = ' ') and                     
                    (fl_file = :R_MFILE Or :R_MFILE  = ' ')                     
                order by fl_file, fl_campo;                                     
                                                                                
           Exec Sql                                                             
            Open MaskCsr;                                                       
                                                                                
           Exec Sql                                                             
            Fetch MaskCsr Into :DS_Mask;                                        
           DoW (SqlStt = '00000');                                              
             ValDatiSflMsk() ;                                                  
             Write MSKSFL;                                                      
             Exec Sql                                                           
               Fetch MaskCsr Into :DS_Mask;                                     
           EndDo;                                                               
           Exec Sql                                                             
             Close MaskCsr;                                                     
         if (MSK1 > 1) ;                                                        
           Dspf.SflDsp = *on ;                                                  
         else;                                                                  
           Dspf.DatiNonInDb = *ON;                                              
           LoadLibFileMsk();                                                    
           If (MSK1 > 1);                                                       
             Dspf.SflDsp = *On;                                                 
           EndIF;                                                               
         endif ;                                                                
        EndIf;                                                                  
        End-Proc ;                                                              
                                                                                
        Dcl-Proc LoadLibfileMsk ;                                               
                                                                                
        Exec SQL                                                                
        DECLARE LibFilMsk  CURSOR FOR                                           
                    SELECT C.SYSTEM_TABLE_SCHEMA, C.SYSTEM_TABLE_NAME,          
                           C.SYSTEM_COLUMN_NAME,                                
                           CASE                                                 
                            WHEN COALESCE(CT.RULETEXT, ' ') <> ' '              
                            THEN 'S'                                            
                            ELSE 'N'                                            
                           END AS MASC_CAMPO,                                   
                           COALESCE(CT.RCAC_NAME, ' ') AS NOME_MASCHERA,        
                           CASE                                                 
                            WHEN COALESCE(CT.RULETEXT, ' ') <> ' '              
                            THEN 'UNDEFINED'                                    
                            ELSE ' '                                            
                           END as NOME_UTENTE,                                  
                           CASE                                                 
                            WHEN COALESCE(CT.RULETEXT, ' ') <> ' '              
                            THEN CT.RULETEXT                                    
                            ELSE ' '                                            
                           END as REGOLA                                        
                    FROM QSYS2.SYSCOLUMNS C LEFT JOIN QSYS2.SYSCONTROLS CT ON   
                                    C.TABLE_SCHEMA = CT.TABLE_SCHEMA AND        
                                    C.TABLE_NAME   = CT.TABLE_NAME   AND        
                                    C.COLUMN_NAME  = CT.COLUMN_NAME             
                    WHERE (C.TABLE_SCHEMA = :R_MLIB  OR :R_MLIB = ' ')          
                      AND (C.TABLE_NAME = :R_MFILE  OR :R_MFILE = ' ')          
                      ORDER BY c.ORDINAL_POSITION;                              
        Exec Sql                                                                
        OPEN LibFilMsk;                                                         
        Exec Sql                                                                
        FETCH LibFilMsk Into :Ds_Mask;                                          
                                                                                
        Dow ((SqlStt = '00000') And (MSK1 < 9999) Or                            
             (SqlStt = '01004') And (MSK1 < 9999));                             
            Fine = *Off;                                                        
            p_PosI = 1;                                                         
            If (Ds_Mask.UM_RuleText <> ' ');                                     
              DoW (Fine = *Off);                                                
                FindAutUser(Ds_Mask.UM_RuleText                                  
                           :p_NomeUtente                                        
                           :p_PosI                                              
                           :p_CheckRule                                         
                           :Fine);                                              
                If (Fine = *Off);                                               
                  Ds_Mask.UM_Utente = p_NomeUtente;                              
                  ValDatiSflMsk() ;                                             
                  Write MSKSFL;                                                 
                EndIf;                                                          
              EndDo;                                                            
            Else;                                                               
              ValDatiSflMsk() ;                                                 
              Write MSKSFL;                                                     
            EndIf;                                                              
            Exec Sql                                                            
              Fetch LibFilMsk Into :DS_Mask ;                                   
        EndDo;                                                                  
        Exec SQl                                                                
          Close LibFilMsk;                                                      
        End-Proc ;                                                              
                                                                                
        dcl-Proc LoadSflFpr ;                                                   
                                                                                
         Dspf.SflFProc = *On;                                                   
                                                                                
         Dspf.SflDspCtl = *off ;                                                
         Dspf.SflDsp = *off ;                                                   
         Dspf.SflClr = *On;                                                     
         write FPRCCTL ;                                                        
         Dspf.SflClr = *Off;                                                    
         Dspf.SflDspCtl = *on ;                                                 
                                                                                
         F_SCELTA = ' ' ;                                                       
         Clear FPRC1;                                                           
         Clear MSK1;                                                            
                                                                                
         If (R_LIB <> *blanks);                                                 
           Exec Sql                                                             
            declare FProc cursor for                                            
             select  f.fl_lib, fl_file, fl_campo, f.fl_tipdat, f.fl_lundat,    
                     case                                                       
                       when coalesce(f.fl_critcam, ' ') <> ' '                  
                       then f.fl_critcam                                        
                       else 'N'                                                 
                     end,                                                       
                     case                                                       
                       when coalesce(f.fl_FprLPgm, ' ') <> ' '                   
                       then f.fl_FprLPgm                                         
                       else ' '                                                 
                     end,                                                       
                     case                                                       
                       when coalesce(f.fl_FprPgm, ' ') <> ' '                   
                       then f.fl_FprPgm                                         
                       else ' '                                                 
                     end                                                        
               from fillst00f f right join qsys2.syscolumns c on                
                    f.fl_lib = c.table_schema and                               
                    f.fl_file = c.table_name                                    
               where (f.fl_lib = :R_LIB Or :R_LIB = ' ') and                    
                     (f.fl_file = :R_FILE Or :R_FILE = ' ')                     
            group by f.fl_lib, f.fl_file, f.fl_campo, f.fl_tipdat, f.fl_lundat, 
            		 f.fl_critcam, f.fl_FprLPgm, f.fl_FprPgm                     
            order by f.fl_file, f.fl_campo         ;                            
                                                                                
           Exec Sql                                                             
            Open FProc;                                                         
                                                                                
           Exec Sql                                                             
            Fetch FProc Into :DS_FProc;                                         
           DoW (SqlStt = '00000');                                              
             ValDatiSfl() ;                                                     
             Write FPRCSFL;                                                     
             Exec Sql                                                           
               Fetch FProc Into :DS_FProc;                                      
           EndDo;                                                               
           Exec Sql                                                             
             Close FProc;                                                       
         Dspf.DatinonInDb = *Off;                                               
         if (FPRC1 > 1) ;                                                       
           Dspf.SflDsp = *on ;                                                  
         else;                                                                  
           Dspf.DatiNonInDb = *ON;                                              
           LoadLibFile();                                                       
           If (FPRC1 > 1);                                                      
             Dspf.SflDsp = *On;                                                 
           Else;                                                                
             PRCERRMSG = 'File non trovato.';                                   
             Dspf.MessageInd = *On;                                             
           EndIF;                                                               
         endif ;                                                                
        EndIf;                                                                  
        End-Proc ;                                                              
                                                                                
        Dcl-proc FindAutUser Export;                                            
        Dcl-pi FindAutUser;                                                     
          SourceString varChar(256);                                            
          NomeUtente   Char(10);                                                
          PosI         zoned(5:0);                                              
          CheckRule    Ind;                                                     
          EndProc Ind;                                                          
        End-pi;                                                                 
                                                                                
        dcl-s EndStringUser Zoned(4:0);                                         
        dcl-s Pos1 zoned(5:0);                                                  
        dcl-s Pos2 zoned(5:0);                                                  
		                                                                              
                                                                                
 		      Exec Sql                                                                     
              SELECT CASE                                                          
              WHEN                                                                 
              REGEXP_LIKE(:SourceString,'[CASE][WHEN][SESSION_USER IN]','i')       
              THEN '1'                                                             
              ELSE '0'                                                             
              END INTO :CheckRule                                                  
              FROM SYSIBM.SYSDUMMY1;                                               
          //CheckRule = %Scan('CASE WHEN ( SESSION_USER IN':SourceString);      
             If (CheckRule = *On);                                                 
               EndStringUser = %Scan('THEN':SourceString);                         
               Pos1 = %Scan('''':SourceString:PosI);                               
               If (Pos1 < EndStringUser);                                          
                 If (Pos1 = 0);                                                    
                   EndProc = *On;                                                  
                 Else;                                                             
                   PosI = Pos1 +1;                                                 
                   Pos2 = %Scan('''':SourceString:PosI);                           
                   NomeUtente =                                                    
                     %Subst(SourceString:Pos1+1:Pos2-(Pos1+1));                 
                   PosI  = Pos2 +1;                                                
                 EndIf;                                                            
               Else;                                                               
                 EndProc = *On;                                                    
               EndIf;                                                              
             Else;                                                                 
               EndProc = *On;                                                      
             EndIf;                                                                
        End-proc;                                                               
                                                                                
        Dcl-Proc LoadLibfile ;                                                  
                                                                                
        Exec SQL                                                                
        DECLARE LibFil  CURSOR FOR                                              
                    SELECT C.SYSTEM_TABLE_SCHEMA, C.SYSTEM_TABLE_NAME,          
                           C.SYSTEM_COLUMN_NAME, C.DATA_TYPE, C."LENGTH",       
                           CASE                                                 
                            WHEN C.HAS_FLDPROC = 'Y'                            
                            THEN 'S'                                            
                            ELSE 'N'                                            
                           END AS CRITCAM,                                                
                           ' ' AS FPRLPGM,
                           ' ' AS FPRPGM,
                           ' ' AS MASCAM,
                           ' ' AS MASNOM,
                           ' ' AS UTENTE,
                           COALESCE(F.FIELD_PROC, ' ')                          
                    FROM QSYS2.SYSCOLUMNS C LEFT JOIN QSYS2.SYSFIELDS F ON      
                          C.SYSTEM_TABLE_SCHEMA = F.SYSTEM_TABLE_SCHEMA AND     
                          C.SYSTEM_TABLE_NAME   = F.SYSTEM_TABLE_NAME   AND     
                          C.SYSTEM_COLUMN_NAME  = F.SYSTEM_COLUMN_NAME          
                    WHERE (C.SYSTEM_TABLE_SCHEMA = :R_LIB  OR :R_LIB = ' ')     
                      AND (C.SYSTEM_TABLE_NAME = :R_FILE  OR :R_FILE = ' ')     
                      ORDER BY C.ORDINAL_POSITION;                              
        Exec Sql                                                                
        OPEN LibFil;                                                            
        Exec Sql                                                                
        FETCH LibFil Into :Ds_FProc2;                                           
                                                                                
        Dow ((SqlStt = '00000') OR (SqlStt = '01004'))                          
            And (FPRC1 < 9999);                                                 
            ValDsFproc2();                                                      
            ValDatiSfl() ;                                                      
            Write FPRCSFL;                                                      
            Exec Sql                                                            
              Fetch LibFil Into :DS_FProc2;                                     
        EndDo;                                                                  
        Exec SQl                                                                
          Close LibFil;                                                         
        End-Proc ;                                                              
                                                                                
        Dcl-Proc ValDatiSfl ;                                                   
          FPRC1 = FPRC1 +1;                                                     
          F_LIBNOM = DS_FProc.UF_Lib;                                            
          F_FILNOM = DS_FProc.UF_File;                                           
          F_CAMPO  = DS_FProc.UF_Campo;                                            
          F_TIPODAT = DS_FProc.UF_TipDat;                                        
          F_LUNG    = DS_FProc.UF_LunDat;                                     
          F_CRITCAM  = DS_FProc.UF_CritCam;                                      
          Select;                                                               
            When (DS_FProc.UF_CritCam = 'S');                                    
             F_STATO = 'CAMPO CRITT.';                                          
            When (DS_FProc.UF_CritCam = 'N');                                    
             F_STATO = 'NON CRITT.';                                            
            When (DS_FProc.UF_CritCam = 'W');                                    
             F_STATO = 'WAIT CRITT.';                                           
         EndSl;                                                                 
          F_LIBFLDPR = DS_FProc.UF_FprLPgm;                                     
          F_NOMPGMFP = DS_FProc.UF_FprPgm;                                    
        End-Proc;                                                               
                                                                                
        Dcl-Proc ValDsFproc2;                                                   
        Ds_FProc.UF_Lib       = Ds_FProc2.UF_Lib;                                 
        Ds_FProc.UF_File      = Ds_FProc2.UF_File;                                
        Ds_FProc.UF_Campo       = Ds_FProc2.UF_Campo;                                 
        Ds_FProc.UF_TipDat    = Ds_FProc2.UF_TipDat;                              
        Ds_FProc.UF_LunDat = Ds_FProc2.UF_LunDat;                           
        Ds_FProc.UF_CritCam   = Ds_FProc2.UF_CritCam;                             
                                                                                
        If (Ds_Fproc2.UF_FprLPgm <> *BLANKS);                                
          p_PosI = %Scan('/':Ds_Fproc2.UF_FprLPgm);                          
          Ds_FProc.UF_FprLPgm  = %Subst(Ds_Fproc2.UF_FprLPgm:1:p_Posi -1);   
          Ds_FProc.UF_FprPgm = %Subst(Ds_Fproc2.UF_FprPgm:p_Posi +1:      
                                  %Len(%Trim(Ds_Fproc2.UF_FprLPgm)) - p_Posi 
                                        ) ;                                     
        Else;                                                                   
          Ds_FProc.UF_FprLPgm  = *blank;                                        
          Ds_FProc.UF_FprPgm = *blank;                                        
        EndIf;                                                                  
                                                                                
        End-Proc;                                                               
        Dcl-Proc ValDatiSflMsk ;                                                
          MSK1 = MSK1 +1;                                                       
          M_LIBNOM = DS_Mask.UM_Lib;                                             
          M_FILNOM = DS_Mask.UM_File;                                            
          M_CAMPO  = DS_Mask.UM_Campo  ;                                           
          M_MASCAM  = DS_Mask.UM_MasCam;                                         
          M_MASNOM = %Subst(DS_Mask.UM_MasNom:1:35);                             
          M_TIPODAT = Ds_Mask.UM_TipDat;                                         
          M_LUNG    = Ds_Mask.UM_LunDat;                                         
          M_NOMUTE = DS_Mask.UM_Utente;                                          
          M_RULETEXT = Ds_Mask.UM_RuleText       ;                               
        End-Proc;                                                               
                                                                                
                                                                                
