      **************************************************************************
      * Modifica effettuata da: Alberto Bruera
      * In data               : 11/06/2019
      * Id modifica           : ab001
      * Desc. modifica        : Da UTAN8PR aggiunta scrittura file $$MOVINS
      *                         con reperimento valori da CGSPA01L e ANAGRA
      **************************************************************************
      * Modifica effettuata da: Alberto Bruera
      * In data               : 24/07/2019
      * Id modifica           : ab002
      * Desc. modifica        : Modifica reperimento insoluti su CGSPA00F
      *                         per avere corrispondenza con dati JGalileo
      *                         eliminato ciclo rpg su ANAGRA
      **************************************************************************
      * Modifica effettuata da: Alberto Bruera
      * In data               : 29/08/2019
      * Id modifica           : ab003
      * Desc. modifica        : Aggiunta valorizzazione campo MDARIF su $$MOVINS
      **************************************************************************
      * Modifica effettuata da: Alberto Bruera
      * In data               : 06/03/2019
      * Id modifica           : ab004
      * Desc. modifica        : Modificato SQL per reperimento insoluti
      **************************************************************************
      * Modifica effettuata da: Alberto Bruera
      * In data               : 12/03/2019
      * Id modifica           : ab005
      * Desc. modifica        : Modificato SQL per reperimento insoluti
      **************************************************************************
	  * Modifica effettuata da: Alberto Bruera                                  
	  * In data               : 13/03/2019                                      
	  * Id modifica           : ab005                                           
   	  * Desc. modifica        : Aggiunto array per gestione valori null         
	  **************************************************************************

     H DecEdit('0,') DatEdit(*Dmy/) AlWNULL(*INPUTONLY)
     h fixnbr(*zoned:*INPUTPACKED)  Option(*NoDebugIo)
     F$$MOVINS  O  a E             DISK
     d Ds_Insoluti     ds                  Qualified
     d   CodCli                       5s 0
     d   Zona                         5s 0
     d   NrPart                       6s 0
     d   DtReg                        8s 0
     d   DtDoc                        8s 0
     d   DtSca                        8s 0
     d   Imp                         13p 2
     
ab005d NullArray       s              5i 0 Dim(7)     
      *Clear flag insoluti
       Exec Sql
         Update anagra set anv4 = ' ';
      *

ab004  Exec Sql
ab004    Declare INS cursor for
ab005    With partap00f as (select contcm, aaopcm, nparcm, sum(impocm)      
ab005							from cgmov00f join 
ab005							     smtabca00l on causcm = k_cod
ab005							where contcm like '1003%' AND TECFIT = 'S'                    
ab005							group by contcm, aaopcm, nparcm                            
ab005							having sum(impocm) <> 0 )                                  
ab005	  Select a.ancod, a.anzo, m.nparcm, 
ab005	  		 (select m1.dtdocm from cgmov00f m1 where m1.nparcm = m.nparcm
ab005                                                 and m1.aaopcm = m.aaopcm
ab005                                                 and m1.contcm = m.contcm
ab005                                                 and m1.causcm = '17'
ab005                                                 order by m1.dtrgcm desc
ab005                                                 fetch first row only),
ab005                 (select m1.dtrgcm from cgmov00f m1 where m1.nparcm = m.nparcm
ab005                                                 and m1.aaopcm = m.aaopcm
ab005                                                 and m1.contcm = m.contcm
ab005                                                 and m1.causcm = '17' 
ab005                                                 order by m1.dtrgcm desc
ab005                                                 fetch first row only),
ab005                 (select m1.dt1scm from cgmov00f m1 where m1.nparcm = m.nparcm
ab005                                                 and m1.aaopcm = m.aaopcm
ab005                                                 and m1.contcm = m.contcm
ab005                                                 and m1.causcm = '17' 
ab005                                                 order by m1.dtrgcm desc
ab005                                                 fetch first row only),
ab005                SUM(m.impocm)
ab005 				from cgmov00f m join partap00f pa on pa.contcm = m.contcm
ab005                					                 and pa.aaopcm = m.aaopcm
ab005                                    			     and pa.nparcm = m.nparcm
ab005				join anagra a on '10030' || digits(a.ancod) = m.contcm                           
ab005				GROUP BY ANCOD, ANZO, M.NPARCM, 
ab005				(select m1.dtdocm from cgmov00f m1 where m1.nparcm = m.nparcm
ab005                                                    and m1.aaopcm = m.aaopcm
ab005                                                    and m1.contcm = m.contcm
ab005                                                    and m1.causcm = '17' 
ab005                                                    order by m1.dtrgcm desc
ab005                                                    fetch first row only), 
ab005                (select m1.dtrgcm from cgmov00f m1 where m1.nparcm = m.nparcm
ab005                                                    and m1.aaopcm = m.aaopcm
ab005                                                    and m1.contcm = m.contcm
ab005													 and m1.causcm = '17'
ab005                                                    order by m1.dtrgcm desc
ab005        											 fetch first row only),
ab005                (select m1.dt1scm from cgmov00f m1 where m1.nparcm = m.nparcm
ab005                                                     and m1.aaopcm = m.aaopcm
ab005                                                     and m1.contcm = m.contcm
ab005                                                     and m1.causcm = '17' 
ab005                                                     order by m1.dtrgcm desc
ab005                                                     fetch first row only)
ab005				HAVING SUM(IMPOCM) > 0
ab005				order by a.ancod, m.nparcm; 
       Exec sql
ab002    Open INS;

ab002   Exec Sql
ab002    Fetch INS Into :Ds_Insoluti :NullArray;
ab002   DoW SqlStt = '00000';
      ** //Scrive record per insoluti
ab002      MZONA = Ds_Insoluti.Zona;
ab002      MCLIX = Ds_Insoluti.CodCli;
ab002      TOT   = Ds_Insoluti.Imp      ;
ab002      MDAREX = Ds_Insoluti.DtReg ;
ab002      MNURIX = Ds_Insoluti.NrPart ;
ab002      MDASCX = Ds_Insoluti.DtSca ;
ab002      MDADOC = Ds_Insoluti.DtDoc ;
ab002      Write RMOVI;

ab002      Exec Sql
ab002        Update ANAGRA set ANV4 = 'I' where ANCOD = :Ds_Insoluti.CodCli;

ab002    Exec Sql
ab002    Fetch INS Into :Ds_Insoluti :NullArray;;
         EndDo;

ab002   Exec Sql
ab002    Close INS;

        *Inlr = *On;

