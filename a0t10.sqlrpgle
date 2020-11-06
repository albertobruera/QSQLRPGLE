      *---------------------------------------------------------------------
      * Modifica effettuata da : Alberto Bruera
      * In data                : 05/03/2020
      * Desc. modifica         : Impostato calcolo totale insoluti e numero di insoluti
      *                          da inizio a fine anno precedente e inizio e fine anno corrente
      * Id modifica            : ab001
      *---------------------------------------------------------------------
     H DecEdit('0,') DatEdit(*Dmy/) AlWNULL(*INPUTONLY)
     h fixnbr(*zoned:*INPUTPACKED)  Option(*NoDebugIo)
      *---------------------------------------------------------------------
      *
     f�SCACLIF0 Uf a e           k disk
     fANAGRA    If   e           k disk

     dDs_DATA          Ds
     d   DATAD                        8  0
     d   ANNO                  1      4  0
     d   MESE                  5      6  0
     d   GIORNO                7      8  0

     D CONTO_J         s             10
     D $IMPOCM         s             13  2
     D $DTRGCM         s              8  0
     D lContCa         S             10                                         Codice Cliente
     d dToday          s               d   DatFmt(*Iso)
     d data_finemese   s               d   DatFmt(*Iso)
     d dtfinemese      s              8  0
     d Tot_annopr      s             13  2
     d dtinizio        s              8  0
     D DATAINI         s              8  0
     d DATAINP         s              8  0
     d DATAOUT         s              8  0
     d SUBTOT          s             12  0
     D COUNT           s              5  0
     D TOT             s             13  2
     d data_inizio     s              8  0
     d Data_scadenza   s              8  0
     d $CONTEC         s             10
     d $IMPREC         s              7P 2
     d $SCAREC         s              8P 0
     d AnnoCor         s              4a
     d AnnoPre         s              4a
     d InzAnnoPre      s              8  0
     d FinAnnoPre      s              8  0
     d InzAnnoCor      s              8  0
     d FinAnnoCor      s              8  0

     d Dt_finemese     Ds
     d  Dt_anno                       4s 0
     d  Dt_mese                       2s 0
     d  Dt_giorno                     2s 0
     d parm_nok        s              1
     d parm_cli        s              5s 0
     d parm_rif        s              5s 0
     d parm_doc        s              5s 0
     d parm_cau        s              3s 0
     d parm_sca        s              8s 0
      *
     d Dt_inizio       Ds
     d  Dt_ianno                      4s 0
     d  Dt_imese                      2s 0
     d  Dt_igiorno                    2s 0
     d DS_Tpagam       Ds             4
     d   dsCD4                        1
     d   dsCDsg                       3s 0
      *
      *�DS per lettura SQL
     d DSUD033       E DS                  ExtName(UD03300F)prefix(DS)

      *================== Main Program =====================================
      *
     c                   Exsr      Elabora
     c                   Exsr      Assegni
     c                   Exsr      Totali
     c                   Eval      *InLr    = *On
     c                   Return
      *
      *================== End Main Programm ================================
      *
      *=====================================================================
      * Routine principale
      *=====================================================================
     c     Elabora       Begsr
     c                   Do
     c                   Exsr      Rsql01
     c                   Enddo
     c                   Endsr
      *
      *
      *
     c*****************************************************************
     c* Rsql01 - Estrazione da file MOVCLI                            *
     c*****************************************************************
     c     Rsql01        Begsr
      *
     c/exec sql
     C+ DECLARE C1 CURSOR FOR SELECT CONTEC ,-IMPREC , SCADEC FROM
     C+ qtemp.ud03300f WHERE tiprec not in ('T' ) and (digits(AAOPEC) ||
     C+ digits(NPAREC) ) in (SELECT distinct(digits(AAOPEC) ||
     C+ digits(NPAREC) ) FROM qtemp.ud03300f WHERE TIPREC = 'T' and
     C+ (dareec - averec) <> 0 ) and SgnREc = 'A' UNION ALL SELECT CONTEC
     C+ ,IMPREC , SCADEC FROM qtemp.ud03300f WHERE tiprec not in ('T')
     C+ and (digits(AAOPEC) || digits(NPAREC) ) in (SELECT
     C+ distinct(digits(AAOPEC) || digits(NPAREC) ) FROM qtemp.ud03300f
     C+ WHERE TIPREC = 'T' and (dareec - averec) <> 0 ) and SgnREc = 'D'
     C+ UNION ALL SELECT CONTEC ,(dareec - averec) , scadec FROM
     C+ qtemp.ud03300f WHERE tiprec in ('P') and (digits(AAOPEC) ||
     C+ digits(NPAREC) ) in (SELECT distinct(digits(AAOPEC) ||
     C+ digits(NPAREC) ) FROM qtemp.ud03300f WHERE TIPREC = 'T' and
     C+ (dareec- averec) <> 0 ) and SgnREc = ' ' and imprec = 0
     c/end-exec
     c/exec sql open c1
     c/end-exec
     c                   Do        *hival
     c                   Eval      sqlcod = *zeros
     c/exec sql
     C+ FETCH NEXT FROM C1 INTO :$CONTEC, :$IMPREC, :$SCAREC
     c/end-exec
      *
     c                   If        sqlcod = 100 or
     c                             sqlcod < *zeros
     c/exec sql close c1
     c/end-exec
     c                   Leave
     c                   Endif

     c                   Select
     c                   When      $SCAREC  <    Data_inizio
     c                   Exsr      Write_scaduto
     c                   When      $SCAREC  >=   Data_inizio and
     c                             $SCAREC  <=   �DMSCAM
     c                   If        $IMPREC   <> *zeros
     c                   Exsr      Write_scadmese
     c                   Endif
     c                   When      $SCAREC  >=   �DMSCAM and
     c                             $SCAREC  <=   �DMSC30
     c                   If        $IMPREC   <> *zeros
     c                   Exsr      Write_scad30
     c                   Endif
     c                   When      $SCAREC  >=   �DMSC30 and
     c                             $SCAREC  <=   �DMSC60
     c                   If        $IMPREC   <> *zeros
     c                   Exsr      Write_scad60
     c                   Endif
     c                   When      $SCAREC  >=   �DMSC60 and
     c                             $SCAREC  <=   �DMSC90
     c                   If        $IMPREC   <> *zeros
     c                   Exsr      Write_scad90
     c                   Endif
     c                   When      $SCAREC  >=   �DMSC90 and
     c                             $SCAREC  <=   �DMSC120
     c                   If        $IMPREC   <> *zeros
     c                   Exsr      Write_scad120
     c                   Endif
     c                   When      $SCAREC  >=   �DMSC120 and
     c                             $SCAREC  <=   �DMSC150
     c                   If        $IMPREC   <> *zeros
     c                   Exsr      Write_scad150
     c                   Endif
     c                   When      $SCAREC  >=   �DMSC150 and
     c                             $SCAREC  <=   �DMSC180
     c                   If        $IMPREC   <> *zeros
     c                   Exsr      Write_scad180
     c                   Endif
     c                   Other
     c                   Endsl
     c                   If        $IMPREC   =  *zeros
     c                   Exsr      Write_vuoto
     c                   Endif
     c                   Enddo
     c                   Endsr
      *
     c*****************************************************************
     c* Aggiorna scaduto                                              *
     c*****************************************************************
     c     Write_scaduto Begsr
     c                   Clear                   �FATTPR
     c     Codcli        Chain     ANAGRA
     c     Codcli        Chain     �SCACLIF0
     c                   If        not(%found)
     c                   eval      �CODCLI = Codcli
     c                   eval      �RAGSOCF= ANRAG
     c                   eval      �ANPAG  = ANPAG
     c                   eval      �ZONA   = ANZO
     c                   eval      �IMSCLL = $IMPREC
     c                   write     SCACLI
     c                   else
     c                   add(H)    $IMPREC       �IMSCLL
     c                   update    SCACLI
     c                   endif
     c                   Endsr
     c*****************************************************************
     c* Aggiorna fine mese                                            *
     c*****************************************************************
     c     Write_scadmeseBegsr
     c     Codcli        Chain     ANAGRA
     c     Codcli        Chain     �SCACLIF0
     c                   If        not(%found)
     c                   eval      �CODCLI = Codcli
     c                   eval      �RAGSOCF= ANRAG
     c                   eval      �ZONA   = ANZO
     c                   eval      �IMSCAM = $IMPREC
     c                   write     SCACLI
     c                   else
     c                   add(H)    $IMPREC       �IMSCAM
     c                   update    SCACLI
     c                   endif
     c                   Endsr
     c*****************************************************************
     c* Aggiorna scadenza 30 gg                                       *
     c*****************************************************************
     c     Write_scad30  Begsr
     c     Codcli        Chain     ANAGRA
     c     Codcli        Chain     �SCACLIF0
     c                   If        not(%found)
     c                   eval      �CODCLI = Codcli
     c                   eval      �RAGSOCF= ANRAG
     c                   eval      �ZONA   = ANZO
     c                   eval      �IMSC30 = $IMPREC
     c                   write     SCACLI
     c                   else
     c                   add(H)    $IMPREC       �IMSC30
     c                   update    SCACLI
     c                   endif
     c                   Endsr
     c*****************************************************************
     c* Aggiorna scadenza 60 gg                                       *
     c*****************************************************************
     c     Write_scad60  Begsr
     c     Codcli        Chain     ANAGRA
     c     Codcli        Chain     �SCACLIF0
     c                   If        not(%found)
     c                   eval      �CODCLI = Codcli
     c                   eval      �RAGSOCF= ANRAG
     c                   eval      �ZONA   = ANZO
     c                   eval      �IMSC60 = $IMPREC
     c                   write     SCACLI
     c                   else
     c                   add(H)    $IMPREC       �IMSC60
     c                   update    SCACLI
     c                   endif
     c                   Endsr
     c*****************************************************************
     c* Aggiorna scadenza 90 gg                                       *
     c*****************************************************************
     c     Write_scad90  Begsr
     c     Codcli        Chain     ANAGRA
     c     Codcli        Chain     �SCACLIF0
     c                   If        not(%found)
     c                   eval      �CODCLI = Codcli
     c                   eval      �RAGSOCF= ANRAG
     c                   eval      �ZONA   = ANZO
     c                   eval      �IMSC90 = $IMPREC
     c                   write     SCACLI
     c                   else
     c                   add(H)    $IMPREC       �IMSC90
     c                   update    SCACLI
     c                   endif
     c                   Endsr
     c*****************************************************************
     c* Aggiorna scadenza 120 gg                                      *
     c*****************************************************************
     c     Write_scad120 Begsr
     c     Codcli        Chain     ANAGRA
     c     Codcli        Chain     �SCACLIF0
     c                   If        not(%found)
     c                   eval      �CODCLI = Codcli
     c                   eval      �RAGSOCF= ANRAG
     c                   eval      �ZONA   = ANZO
     c                   eval      �IMSC120= $IMPREC
     c                   write     SCACLI
     c                   else
     c                   add(H)    $IMPREC       �IMSC120
     c                   update    SCACLI
     c                   endif
     c                   Endsr
     c*****************************************************************
     c* Aggiorna scadenza 150 gg                                      *
     c*****************************************************************
     c     Write_scad150 Begsr
     c     Codcli        Chain     ANAGRA
     c     Codcli        Chain     �SCACLIF0
     c                   If        not(%found)
     c                   eval      �CODCLI = Codcli
     c                   eval      �RAGSOCF= ANRAG
     c                   eval      �ZONA   = ANZO
     c                   eval      �IMSC150= $IMPREC
     c                   write     SCACLI
     c                   else
     c                   add(H)    $IMPREC       �IMSC150
     c                   update    SCACLI
     c                   endif
     c                   Endsr
     c*****************************************************************
     c* Aggiorna scadenza 180 gg                                      *
     c*****************************************************************
     c     Write_scad180 Begsr
     c     Codcli        Chain     ANAGRA
     c     Codcli        Chain     �SCACLIF0
     c                   If        not(%found)
     c                   eval      �CODCLI = Codcli
     c                   eval      �RAGSOCF= ANRAG
     c                   eval      �ZONA   = ANZO
     c                   eval      �IMSC180= $IMPREC
     c                   write     SCACLI
     c                   else
     c                   add(H)    $IMPREC       �IMSC180
     c                   update    SCACLI
     c                   endif
     c                   Endsr
     c*****************************************************************
     c* Aggiorna scadenza oltre                                       *
     c*****************************************************************
     c     Write_scadFF  Begsr
     c     Codcli        Chain     ANAGRA
     c     Codcli        Chain     �SCACLIF0
     c                   If        not(%found)
     c                   eval      �CODCLI = Codcli
     c                   eval      �RAGSOCF= ANRAG
     c                   eval      �ZONA   = ANZO
     c                   eval      �IMSCFF = $IMPREC
     c                   write     SCACLI
     c                   else
     c                   add(H)    $IMPREC       �IMSCFF
     c                   update    SCACLI
     c                   endif
     c                   Endsr
     c*****************************************************************
     c* crea comunque vuoto                                           *
     c*****************************************************************
     c     Write_vuoto   Begsr
     c     Codcli        Chain     ANAGRA
     c     Codcli        Chain     �SCACLIF0
     c                   If        not(%found)
     c                   clear                   SCACLI
     c                   eval      �CODCLI = Codcli
     c                   eval      �RAGSOCF= ANRAG
     c                   eval      �ZONA   = ANZO
     c                   write     SCACLI
     c                   endif
     c                   Endsr
     c*****************************************************************
     c* Corregge data fine mese scadenza                              *
     c*****************************************************************
     c     Data_corretta Begsr
     c                   move      data_finemese dtfinemese
     c                   move      dtfinemese    Dt_finemese
     c                   select
     c                   when      Dt_mese   = 1
     c                   eval      Dt_giorno = 31
     c                   when      Dt_mese   = 2
     c                   eval      Dt_giorno = 28
     c                   when      Dt_mese   = 3
     c                   eval      Dt_giorno = 31
     c                   when      Dt_mese   = 4
     c                   eval      Dt_giorno = 30
     c                   when      Dt_mese   = 5
     c                   eval      Dt_giorno = 31
     c                   when      Dt_mese   = 6
     c                   eval      Dt_giorno = 30
     c                   when      Dt_mese   = 7
     c                   eval      Dt_giorno = 31
     c                   when      Dt_mese   = 8
     c                   eval      Dt_giorno = 31
     c                   when      Dt_mese   = 9
     c                   eval      Dt_giorno = 30
     c                   when      Dt_mese   = 10
     c                   eval      Dt_giorno = 31
     c                   when      Dt_mese   = 11
     c                   eval      Dt_giorno = 30
     c                   when      Dt_mese   = 12
     c                   eval      Dt_giorno = 31
     c                   endsl
     c                   move      Dt_finemese   dtfinemese
     c                   move      dtfinemese    data_finemese

     c                   Endsr
      *
      *=====================================================================
      * Routine principale
      *=====================================================================
     c     Totali        Begsr
      *
     c     Codcli        Chain     �SCACLIF0
     c                   If        (%found)
      *
     C                   EVAL      CONTO_J  = '10030' + %EDITC(CODCLI:'X')
ab001      AnnoCor = %Char(%SubDt(%Date():*YEARS));
ab001      AnnoPre = %Char(%SubDt(%Date()-%years(1):*YEARS));
ab001      InzAnnoPre = %Dec(AnnoPre + '0101':8:0);
ab001      FinAnnoPre = %Dec(AnnoPre + '1231':8:0);
ab001      InzAnnoCor = %Dec(AnnoCor + '0101':8:0);
ab001      FinAnnoCor = %Dec(%Char(%Date():*Iso0):8:0);

      *--> anno in corso
ab001c*/exec sql
ab001C*+ SELECT COUNT(*), SUM(IMPOCM) INTO :COUNT, :TOT FROM
ab001C*+ VIG90DAT/CGMOV00F WHERE CONTCM = :CONTO_J AND CAUSCM = '17' AND
ab001C*+ DTOPCM > :DATAINI
ab001c*/end-exec
ab001    exec sql
ab001    Select count(*), Sum(M.IMPOCM) into :COUNT, :TOT
ab001    from CGMOV00F m join ANAGRA A On M.CONTCM = '10030' || digits(A.ANCOD)
ab001    where M.CONTCM like '1003%'
ab001    and M.CAUSCM in (Select M1.CAUSCM
ab001                       from CGMOV00F M1 join SMTABCA00L T
ab001                                          on M1.CAUSCM = T.K_COD
ab001                       where T.TECFIT = 'S' and M1.CONTCM = M.CONTCM
ab001                                            and M1.NPARCM = M.NPARCM
ab001                                            and M1.AAOPCM = M.AAOPCM  )
ab001    and M.DTOPCM BETWEEN :InzAnnoCor and :FinAnnoCor
ab001    And m.contcm = :CONTO_J
ab001    HAVING SUM(M.IMPOCM) <> 0;

ab001    //aggiornamento file INSOLUTI per FAGANT
ab001    Exec Sql
ab001      update INSOLUTI set isnins = :COUNT, isimp = :TOT
ab001       where iscli = :CODCLI;

     C                   Z-ADD     COUNT         �INSOLN
     C                   Z-ADD     TOT           �INSOLI
     C                   Clear                   COUNT
     C                   Clear                   TOT
      *--> anno precedente
ab001c*/exec sql
ab001C*+ SELECT COUNT(*), SUM(IMPOCM) INTO :COUNT, :TOT FROM
ab001C*+ VIG90DAT/CGMOV00F WHERE CONTCM = :CONTO_J AND CAUSCM = '17' AND
ab001C*+ DTOPCM < :DATAINI
ab001c*/end-exec
ab001    exec sql
ab001    Select count(*), Sum(M.IMPOCM) into :COUNT, :TOT
ab001    from CGMOV00F m join ANAGRA A On M.CONTCM = '10030' || digits(A.ANCOD)
ab001    where M.CONTCM like '1003%'
ab001    and M.CAUSCM in (Select M1.CAUSCM
ab001                       from CGMOV00F M1 join SMTABCA00L T
ab001                                          on M1.CAUSCM = T.K_COD
ab001                       where T.TECFIT = 'S' and M1.CONTCM = M.CONTCM
ab001                                            and M1.NPARCM = M.NPARCM
ab001                                            and M1.AAOPCM = M.AAOPCM  )
ab001    and M.DTOPCM BETWEEN :InzAnnoPre and :FinAnnoPre
ab001    And m.contcm = :CONTO_J
ab001    HAVING SUM(M.IMPOCM) <> 0;

ab001    //aggiornamento file INSOLUTI per FAGANT
ab001    Exec Sql
ab001      update INS80 set isnins = :COUNT, isimp = :TOT
ab001       where iscli = :CODCLI;

     C                   Z-ADD     COUNT         �INS80N
     C                   Z-ADD     TOT           �INS80I

     c                   Eval      SUBTOT = �IMSCAM+�IMSC30+�IMSC60+�IMSC90+
     c                                      �IMSC120+�IMSC150+�IMSC180
     c                   z-add     SUBTOT        �INSTOT

     c                   Eval      �ESPOSZ  =    (�INSTOT+�IMSCLL)
     c     �CODCLI       Chain     ANAGRA                             50
     c                   if        %found
     c                   z-add     ANPAG         �ANPAG
     c                   Endif

     c                   update    SCACLI
     c                   Else
ab001    //aggiornamento file INSOLUTI per FAGANT
ab001    Exec Sql
ab001      update insoluti set isnins = :COUNT, isimp = :TOT
ab001     where iscli = :CODCLI;
ab001    //aggiornamento file INSOLUTI per FAGANT
ab001    Exec Sql
ab001      update ins80 set isnins = :COUNT, isimp = :TOT
ab001     where iscli = :CODCLI;
     c                   endif

     c                   Endsr
      *---------------------------------------------------------------------------------------------
      *
      *---------------------------------------------------------------------------------------------
     c     ASSEGNI       Begsr
      *
      *
     C                   EVAL      CONTO_J  = '10030' + %EDITC(CODCLI:'X')
     c/exec sql
     C+ DECLARE C9 CURSOR FOR SELECT IMPOCM, DTRGCM FROM
     C+ VIG90DAT/CGMOV05L WHERE CONTCM = :CONTO_J AND AT01CM = 'Z'
     c/end-exec
     c/exec sql open c9
     c/end-exec
     c                   Do        *hival
     c                   Eval      sqlcod = *zeros
     c/exec sql
     c+ fetch next from c9 into
     c+ :$IMPOCM,
     c+ :$DTRGCM
     c/end-exec
      *
     c                   If        sqlcod = 100 or
     c                             sqlcod < *zeros
     c/exec sql close c9
     c/end-exec
     c                   Leave
     c                   Endif
     C                   EXSR      ROUT_ASSEGNI
     c                   ENDDO
     c                   Endsr
     c*****************************************************************
     c* Trattamento ASSEGNI                                           *
     c*****************************************************************
     c     ROUT_ASSEGNI  Begsr
     c     Codcli        Chain     �SCACLIF0
     c                   If        (%found)
     c                   Eval      $IMPOCM   = $IMPOCM * -1
     c                   Select
     c                   When      $DTRGCM   <   Data_inizio
     c                   Exsr      UPD_scaduto
     c                   update    SCACLI
     c                   When      $DTRGCM  >=   Data_inizio and
     c                             $DTRGCM  <=   �DMSCAM
     c                   Exsr      UPD_scadmese
     c                   update    SCACLI
     c                   When      $DTRGCM  >=   �DMSCAM and
     c                             $DTRGCM  <=   �DMSC30
     c                   Exsr      UPD_scad30
     c                   update    SCACLI
     c                   When      $DTRGCM  >=   �DMSC30 and
     c                             $DTRGCM  <=   �DMSC60
     c                   Exsr      UPD_scad60
     c                   update    SCACLI
     c                   When      $DTRGCM  >=   �DMSC60 and
     c                             $DTRGCM  <=   �DMSC90
     c                   Exsr      UPD_scad90
     c                   update    SCACLI
     c                   When      $DTRGCM  >=   �DMSC90 and
     c                             $DTRGCM  <=   �DMSC120
     c                   Exsr      UPD_scad120
     c                   update    SCACLI
     c                   When      $DTRGCM  >=   �DMSC120 and
     c                             $DTRGCM  <=   �DMSC150
     c                   Exsr      UPD_scad150
     c                   update    SCACLI
     c                   When      $DTRGCM  >=   �DMSC150 and
     c                             $DTRGCM  <=   �DMSC180
     c                   Exsr      UPD_scad180
     c                   update    SCACLI
     c                   Other
     c                   Endsl

     c                   ENDIF
     c                   ENDSR
     c*****************************************************************
     c* Aggiorna scaduto                                              *
     c*****************************************************************
     c     UPD_scaduto   Begsr
     c                   add(H)    $IMPOCM       �AASCLL
     c                   Endsr
     c*****************************************************************
     c* Aggiorna fine mese                                            *
     c*****************************************************************
     c     UPD_scadmese  Begsr
     c                   add(H)    $IMPOCM       �AASCAM
     c                   Endsr
     c*****************************************************************
     c* Aggiorna scadenza 30 gg                                       *
     c*****************************************************************
     c     UPD_scad30    Begsr
     c                   add(H)    $IMPOCM       �AASC30
     c                   Endsr
     c*****************************************************************
     c* Aggiorna scadenza 60 gg                                       *
     c*****************************************************************
     c     UPD_scad60    Begsr
     c                   add(H)    $IMPOCM       �AASC60
     c                   Endsr
     c*****************************************************************
     c* Aggiorna scadenza 90 gg                                       *
     c*****************************************************************
     c     UPD_scad90    Begsr
     c                   add(H)    $IMPOCM       �AASC90
     c                   Endsr
     c*****************************************************************
     c* Aggiorna scadenza 120 gg                                      *
     c*****************************************************************
     c     UPD_scad120   Begsr
     c                   add(H)    $IMPOCM       �AASC120
     c                   Endsr
     c*****************************************************************
     c* Aggiorna scadenza 150 gg                                      *
     c*****************************************************************
     c     UPD_scad150   Begsr
     c                   add(H)    $IMPOCM       �AASC150
     c                   Endsr
     c*****************************************************************
     c* Aggiorna scadenza 180 gg                                      *
     c*****************************************************************
     c     UPD_scad180   Begsr
     c                   add(H)    $IMPOCM       �AASC180
     c                   Endsr
     c*****************************************************************
     c* *INZSR - Routine Iniziale                                     *
     c*****************************************************************
     c     *INZSR        Begsr
     c     *Entry        Plist
     c                   Parm                    lContCa
     c                   Move      lContCa       Codcli            5 0


     c     *eur          Move      *date         dToday
      *----
     c                   Move      dToday        dtfinemese
     c                   Move      dtfinemese    Dt_finemese
     c                   Move      dToday        dtinizio
     c                   Move      dtinizio      Dt_inizio
     c                   Move      Dt_inizio     Data_inizio
     c                   Move      Dt_inizio     Data_inizio
     c                   select
     c                   when      Dt_mese   =   1
     c                   eval      Dt_giorno =   31
     c                   when      Dt_mese   =   2
     c                   eval      Dt_giorno =   28
     c                   when      Dt_mese   =   3
     c                   eval      Dt_giorno =   31
     c                   when      Dt_mese   =   4
     c                   eval      Dt_giorno =   30
     c                   when      Dt_mese   =   5
     c                   eval      Dt_giorno =   31
     c                   when      Dt_mese   =   6
     c                   eval      Dt_giorno =   30
     c                   when      Dt_mese   =   7
     c                   eval      Dt_giorno =   31
     c                   when      Dt_mese   =   8
     c                   eval      Dt_giorno =   31
     c                   when      Dt_mese   =   9
     c                   eval      Dt_giorno =   30
     c                   when      Dt_mese   =   10
     c                   eval      Dt_giorno =   31
     c                   when      Dt_mese   =   11
     c                   eval      Dt_giorno =   30
     c                   when      Dt_mese   =   12
     c                   eval      Dt_giorno =   31
     c                   endsl

     c                   move      Dt_finemese   dtfinemese
     c                   move      dtfinemese    data_finemese
     c                   Move      data_finemese �DMSCAM

     c                   Adddur    1:*M          data_finemese
     c                   exsr      Data_corretta
     c                   Move      data_finemese �DMSC30
     c                   Adddur    1:*M          data_finemese
     c                   exsr      Data_corretta
     c                   Move      data_finemese �DMSC60
     c                   Adddur    1:*M          data_finemese
     c                   exsr      Data_corretta
     c                   Move      data_finemese �DMSC90
     c                   Adddur    1:*M          data_finemese
     c                   exsr      Data_corretta
     c                   Move      data_finemese �DMSC120
     c                   Adddur    1:*M          data_finemese
     c                   exsr      Data_corretta
     c                   Move      data_finemese �DMSC150
     c                   Adddur    1:*M          data_finemese
     c                   exsr      Data_corretta
     c                   Move      data_finemese �DMSC180
     c                   Adddur    1:*M          data_finemese
     c                   exsr      Data_corretta
     c                   Move      data_finemese �DMSCFF
     C                   MOVE      *YEAR         ANNO
     C                   MOVE      '01'          MESE
     C                   MOVE      '01'          GIORNO
     C                   MOVE      DATAD         DATAINI
     c                   Endsr
