     devas02cot        pr                  Extpgm('EVAS02COT')

     dOraInz           s               t
     dOraFin           s               t
     dw_orai           s              6s 0
     dw_orai0          s              6s 0
     dw_oraf           s              6s 0
     dMinLav           s              6s 0
     dw_data           s              6s 0
     dw_data8          s              8s 0
     dw_user           s              4a
     dCalcMattino      s               n
     dOraFine0         s               n
     dSud              s               n

     dDs_Evas        e ds                  ExtName('EVAS00F')
     d                                     Qualified
     dW_Ds_Evas      e ds                  ExtName('EVAS00F')
     d                                     Qualified
     dDs_Tot           ds                  Qualified
     d Evasore                        6a
     d TotOre                         4s 0

              Exec Sql
                Declare Evas cursor for
                  Select * from evas00f
                  order by evuser, evdata;
              Exec Sql
                Open Evas;
              Exec Sql
                Fetch Evas Into :Ds_Evas;
              w_orai = Ds_Evas.evtiminz *100;
              w_data = Ds_Evas.EvData;
              w_user = Ds_Evas.EvUser;
              Clear W_Ds_Evas;

              DoW SqlStt = '00000';
                If (Ds_Evas.EvTimFin = 0);
                  Exec Sql
                    Fetch Evas Into :Ds_Evas;
                  Iter;
                EndIf;
                If Ds_Evas.EvData <> W_data;
                  ExSr TotPerdata;
                EndIf;
                If (Ds_Evas.evpgs = 'S');
                  Sud = *On;
                EndIf;

                //Verifica ore lavorate mattino fino alle 12:00
                If (Ds_Evas.Evtiminz > 1200) And (CalcMattino = *Off);
                  OraInz = %Time(w_orai);
                  Orafin = %Time(w_oraf);
                  MinLav = MinLav + %Diff(OraFin:OraInz:*minutes);
                  If MinLav > 210;
                     MinLav = 240;
                  EndIf;
                  w_orai = Ds_Evas.evtiminz * 100;
                  OraInz = %Time(w_orai);
                  CalcMattino = *On;
                Else;
                If (W_Ds_Evas.EvTimFin <> 0) ;
                  If (%Diff(%Time(Ds_Evas.EvTimInz * 100):
                            %Time(W_Ds_Evas.EvTimFin * 100):*minutes) > 40);
                    OraFin = %Time(W_Ds_Evas.EvTimFin * 100);
                    MinLav = MinLav + %Diff(OraFin:OraInz:*minutes);
                    w_orai = Ds_Evas.EvTimInz * 100;
                    OraInz = %Time(w_orai);
                    OraFine0 = *On;
                  EndIf;
                EndIf;

                EndIf;

                w_oraf = DS_Evas.EvTimFin *100;
                OraFin = %Time(w_oraf);
                  W_Ds_Evas = Ds_Evas;
                  Exec Sql
                    Fetch Evas Into :Ds_Evas;

              EndDo;
              Exec Sql
                Close Evas;
              ExSr TotPerdata;

              Exec Sql
                Declare TOT cursor for
                SELECT evevasore, ceiling(sum(round((evtotore/60), 0))) as
                ore FROM EVTOT00F
                group by evevasore;
              Exec Sql
                Open TOT;
              Exec Sql
                Fetch TOT Into :Ds_Tot;
              Dow SqlStt = '00000';
                Exec Sql
                Update evaritt set ETIMPG = :Ds_Tot.TotOre
                   Where ETNOM6 = :DS_Tot.Evasore;
                Exec Sql
                  Fetch TOT Into :Ds_Tot;
              EndDo;
              Evas02cot();
          Return;

          BegSr TotPerdata;
                  OraInz = %Time(w_orai);
                  MinLav = MinLav + %Diff(OraFin:OraInz:*minutes);
                  If (Sud = *On);
                    MinLav = MInLav +30;
                  EndIf;
                  If MinLav > 450;
                     MinLav = 480;
                  EndIf;
                  w_data8 = %Dec(%Char(%Date(w_data:*ymd):*iso0):8:0);
                  Exec Sql
                    Insert into EVTOT00F values(:w_user, :w_data8, :MinLav);
                  clear MinLav;

                  CalcMattino = *Off;

                  w_user = Ds_Evas.EvUser;
                  w_data = Ds_Evas.EvData;
                  w_orai = Ds_Evas.evtiminz * 100;
                  OraInz = %Time(w_orai);
                  Sud = *Off;
                  OraFine0 = *Off;
          EndSr;
