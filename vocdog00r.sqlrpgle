           //dcl-f œMasterf0 disk(*ext) usage(*update);
           dcl-ds Ds_VocDog  ExtName('VOCDOG00F') qualified;
           end-ds;
           dcl-ds Ds_Art     ExtName('ART00') qualified;
           end-ds;
           dcl-s w_codice   Char(10);
           dcl-s w2_codice  Char(10);
           dcl-s w_codice2  Zoned(8:0);
           dcl-s Pos        Zoned(2:0);
           dcl-s LenCodice  Zoned(2:0);
           dcl-s UpScore    Ind       ;
           dcl-s VD         Zoned(10:0);
         Exec Sql
           Declare VDOG cursor for
           Select * from vocdog00f;
         Exec Sql
           Open VDOG;
           Exec Sql
             Fetch VDOG Into :Ds_VocDog;

         Dow SqlStt = '00000';

              Select;
                When (%Scan('-':Ds_VocDog.Codice) <> 0);
                  Pos = %Scan('-':%Trim(Ds_VocDog.Codice));
                  LenCodice = %Len(%Trim(Ds_VocDog.Codice));
                  w_Codice = %Subst(%Trim(Ds_VocDog.Codice):1:Pos-1);
                  w_Codice = %Trim(w_Codice) +
                  %Subst(%Trim(Ds_VocDog.Codice):Pos+1:LenCodice - Pos);

                  If (%Scan('/':w_codice) <> 0);
                    Pos = %Scan('/':w_Codice);
                    LenCodice = %Len(%Trim(w_Codice));
                    w2_Codice = %Subst(w_Codice:1:Pos-1);
                    w_Codice = %Trim(w2_Codice) +
                    %Subst(w_Codice:Pos+1:LenCodice - Pos);
                  EndIf;

                When (%Scan('/':Ds_VocDog.Codice) <> 0);
                  Pos = %Scan('/':%Trim(Ds_VocDog.Codice));
                  LenCodice = %Len(%Trim(Ds_VocDog.Codice));
                  w_Codice = %Subst(%Trim(Ds_VocDog.Codice):1:Pos-1);
                  w_Codice = %Trim(w_Codice) +
                  %Subst(%Trim(Ds_VocDog.Codice):Pos+1:LenCodice - Pos);
              EndSl;

              If (Pos = 0);
                w_Codice = Ds_VocDog.Codice;
              Else;
                Pos = 0;
              EndIf;

            w_codice2 = %Dec(w_codice:10:0);

            Exec Sql
             Select * into :ds_Art from art00 where arcod = :w_codice2;
            If SqlStt <> '00000';
              Exec Sql
              Insert Into ERROR00F values(:ds_VocDog.codice,
                                          :w_codice,
                                          :Ds_VocDog.DESCR00001,
                                          :Ds_VocDog.DESCR00002,
                                          :Ds_VocDog.DESCR00003,
                                          'Codice non in anagrafica');
            Else;
              Exec Sql
               update œMASTERF0
                set Tar_Doga = cast(:DS_VocDog.VD as dec(10, 0))
                where codice = :w_codice2 ;
              If (SqlStt <> '00000');
                If (DS_VocDog.VD <> *blanks);
                  VD = %Dec(DS_VocDog.VD:10:0);
                  Exec Sql
                    Insert Into œMASTERF0 (Codice, Tar_Doga)
                                   values (:w_codice2,
                                           :VD);
                Else;
                  Exec Sql
                    Insert Into ERROR00F values(:ds_VocDog.codice,
                                                :w_codice,
                                                :Ds_VocDog.DESCR00001,
                                                :Ds_VocDog.DESCR00002,
                                                :Ds_VocDog.DESCR00003,
                                                'Voce doganale a *blank');
                EndIf;
              EndIf;
            EndIf;

            Exec Sql
              Fetch VDOG Into :Ds_VocDog;
         EndDo;
         Exec Sql
           Close VDOG;
         Return;
