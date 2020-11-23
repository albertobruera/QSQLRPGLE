       ctl-opt main(encdec10r);
       ctl-opt option(*srcstmt);
       ctl-opt stgmdl(*inherit);
       ctl-opt thread(*concurrent);
       /if defined(*crtbndrpg)
          ctl-opt actgrp(*caller);
       /endif

       /copy QSYSINC/QRPGLESRC,QC3CCI
       /copy QSYSINC/QRPGLESRC,QUSEC
       /copy QSYSINC/QRPGLESRC,SQL
       /copy QSYSINC/QRPGLESRC,SQLFP

       // QSYSINC/H QC3DTAEN
       dcl-pr Qc3EncryptData extproc(*dclcase);
          clearData pointer value;
          clearDataLen int(10) const;
          clearDataFormat char(8) const;
          algorithmDesc likeds(QC3D0200);   // Qc3_Format_ALGD0200
          algorithmDescFormat char(8) const;
          keyDesc likeds(T_key_descriptor0200) const;
          keyDescFormat char(8) const;
          cryptoServiceProvider char(1) const;
          cryptoDeviceName char(10) const;
          encryptedData pointer value;
          lengthOfAreaForEncryptedData int(10) const;
          lengthOfEncryptedDataReturned int(10);
          errorCode likeds(QUSEC);
       end-pr;

       // QSYSINC/H QC3DTADE
       dcl-pr Qc3DecryptData extproc(*dclcase);
          encryptedData pointer value;
          encryptedDataLen int(10) const;
          algorithmDesc likeds(QC3D0200);   // Qc3_Format_ALGD0200
          algorithmDescFormat char(8) const;
          keyDesc likeds(T_key_descriptor0200) const;
          keyDescFormat char(8) const;
          cryptoServiceProvider char(1) const;
          cryptoDeviceName char(10) const;
          clearData pointer value;
          lengthOfAreaForClearData int(10) const;
          lengthOfClearDataReturned int(10);
          errorCode likeds(QUSEC);
       end-pr;

       dcl-pr ExportKeyProc ;
         QualNKeyStore  char(20);
         RecLabel       char(32);
         RetKey         char(256);
       end-pr;

       // Constants from QSYSINC/H QC3CCI
       dcl-c Qc3_AES                      22;
       dcl-c Qc3_ECB                      '0';
       dcl-c Qc3_Pad_Char                 '1';
       dcl-c Qc3_Bin_String               '0';
       dcl-c Qc3_Key_Parms                'KEYD0200';
       dcl-c Qc3_Alg_Block_Cipher         'ALGD0200';
       dcl-c Qc3_Data                     'DATA0100';
       dcl-c Qc3_Any_CSP                  '0';

       // Constants from QSYSINC/H SQL
       dcl-c SQL_TYP_CLOB           408; // CLOB - varying length string
       dcl-c SQL_TYP_NCLOB          409; // (SQL_TYP_CLOB + 1 for NULL)

       dcl-c SQL_TYP_VARCHAR        448; // VARCHAR(i) - varying length string
                                         // (2 byte length)
       dcl-c SQL_TYP_NVARCHAR       449; // (SQL_TYP_VARCHAR + 1 for NULL)
       dcl-c SQL_TYP_CHAR           452; // CHAR(i) - fixed length string
       dcl-c SQL_TYP_NCHAR          453; // (SQL_TYP_CHAR + 1 for NULL)
       dcl-c SQL_TYP_BLOB           404; // BLOB - varying length string
       dcl-c SQL_TYP_NBLOB          405; // (SQL_TYP_BLOB + 1 for NULL)

       dcl-c SQL_TYP_DECIMAL        484; // DECIMAL (m,n)
       dcl-c SQL_TYP_NDECIMAL       485;

       dcl-c SQL_TYP_ZONED          488; // DECIMAL (m,n)
       dcl-c SQL_TYP_NZONED         489;

       dcl-c SQL_TYP_INTEGER        496;
       dcl-c SQL_TYP_NINTEGER       497;

       // Other constants
       dcl-c KEY_MGMT_SIZE 16;
       dcl-c MAX_VARCHAR_SIZE 32739;
       dcl-c MAX_CHAR_SIZE 32765;
       dcl-c MAX_CLOB_SIZE 1000000;
       dcl-c MAX_BLOB_SIZE 1000000;
       dcl-c MAX_DECIMAL_SIZE 63   ;
       dcl-c MAX_ZONED_SIZE 63   ;
       dcl-c MAX_INTEGER_SIZE 32767   ;

       dcl-ds T_key_descriptor0200 template qualified;
           desc likeds(QC3D020000);
           key char(KEY_MGMT_SIZE);
       end-ds;

       // T_DECODED_VARCHAR is the same as a VARCHAR field in RPG
       // but it is convenient to define it as a structure
       // for this purpose
       dcl-ds T_DECODED_VARCHAR qualified template;
          data char(MAX_VARCHAR_SIZE);
          len int(5);
       end-ds;

       dcl-ds T_DECODED_CHAR qualified template;
          data char(MAX_CHAR_SIZE);
          len int(5);
       end-ds;

       dcl-ds T_DECODED_DECIMAL qualified template;
          data int(10);
          len int(5);
       end-ds;

       dcl-ds T_DECODED_INTEGER qualified template;
          data char(MAX_INTEGER_SIZE);
          len int(5);
       end-ds;

       dcl-ds T_DECODED_CLOB qualified template;
          data char(MAX_CLOB_SIZE);
          len int(10);
       end-ds;

       dcl-ds T_DECODED_BLOB qualified template;
          data char(MAX_BLOB_SIZE);
          len int(10);
       end-ds;

       dcl-ds T_DECODED_ZONED qualified template;
          data Zoned(MAX_ZONED_SIZE);
          len int(10);
       end-ds;

       dcl-ds T_ENCODED_VARCHAR qualified template;
          len int(5);
          keyManagementData char(KEY_MGMT_SIZE);
          data varchar(MAX_VARCHAR_SIZE) ;
       end-ds;

       dcl-ds T_ENCODED_DECIMAL qualified template;
          len int(5);
          keyManagementData char(KEY_MGMT_SIZE);
          data int(10);
       end-ds;

       dcl-ds T_ENCODED_CLOB qualified template;
          len int(10);
          keyManagementData char(KEY_MGMT_SIZE);
          data char(MAX_CLOB_SIZE);
       end-ds;

       dcl-ds T_ENCODED_BLOB qualified template;
          len int(10);
          keyManagementData char(KEY_MGMT_SIZE);
          data char(MAX_BLOB_SIZE);
       end-ds;

       dcl-ds T_DECODED_DATA qualified template;
          varchar likeds(T_DECODED_VARCHAR) pos(1);
          char likeds(T_DECODED_CHAR) pos(1);
          clob likeds(T_DECODED_CLOB) pos(1);
          blob likeds(T_DECODED_BLOB) pos(1);
          Decimal likeds(T_DECODED_DECIMAL) pos(1);
          Integer likeds(T_DECODED_INTEGER) pos(1);
          Zoned   likeds(T_DECODED_ZONED) pos(1);
       end-ds;

       dcl-ds T_ENCODED_DATA qualified template;
          varchar likeds(T_ENCODED_VARCHAR) pos(1);
          clob likeds(T_ENCODED_CLOB) pos(1);
          blob likeds(T_ENCODED_BLOB) pos(1);
       end-ds;

       dcl-ds T_optional qualified template;
          bytes uns(10);
          type_indicator char(1);
       end-ds;

		     dcl-ds PgmStat PSDS ;
		      	User char(10) Pos(254);
		     end-ds;

          dcl-s QualNKStore    char(20);
          dcl-s RecLabel       char(32);
          dcl-s RetKey         char(256);

       // Main procedure
       dcl-proc encdec10r             ;

          dcl-pi *n EXTPGM('ENCDEC10R');
             FuncCode uns(5) const;
             OptionalParms likeds(T_optional);
             DecodedDataType likeds(SQLFPD); // sqlfpParameterDescription_T
             DecodedData likeds(T_DECODED_DATA);
             EncodedDataType likeds(SQLFPD); // sqlfpParameterDescription_T
             EncodedData likeds(T_ENCODED_DATA);
             SqlState char(5);
             Msgtext varchar(1000); // SQLFMT DS in QSYSINC/SQLFP is an RPG VARC
          end-pi;

          dcl-ds ErrCode likeds(QUSEC) inz;

          dcl-ds ALGD0200 likeds(QC3D0200) inz;
          dcl-ds T_key_descriptor0200 qualified inz;
             desc LIKEDS(QC3D020000);
             key char(KEY_MGMT_SIZE);
          end-ds;
          dcl-ds KeyDesc0200 likeds(T_key_descriptor0200) inz;

          dcl-s DecryptedDataLen int(10);
          dcl-s DecryptedData char(MAX_CLOB_SIZE) based(Decrypted_Datap);
          dcl-s Decrypted_Datap pointer;

          dcl-s EncryptedDataLen int(10);
          dcl-s EncryptedData char(MAX_CLOB_SIZE) based(Encrypted_Datap);
          dcl-s Encrypted_Datap pointer;

          dcl-s RtnLen int(10);
          dcl-s KeyManagement char(KEY_MGMT_SIZE) based(KeyMgmtp);
          dcl-s KeyMgmtp pointer;

          ErrCode = *allx'00';
          ErrCode.QUSBPRV = %size(QUSEC); // Bytes_provided

          if FuncCode = 8; // create or alter time
             FieldCreatedOrAltered (%addr(OptionalParms)
                                  : DecodedDataType
                                  : EncodedDataType
                                  : SqlState
                                  : Msgtext);
             return;
          endif;

          // Initialize the Algorithm Description Format
          ALGD0200 = *allx'00';
          ALGD0200.QC3BCA = Qc3_AES;        // set block cipher algorithm
          ALGD0200.QC3BL = 16;              // set block length
          ALGD0200.QC3MODE = Qc3_ECB;       // set mode
          ALGD0200.QC3PO = Qc3_Pad_Char;    // set pad option

          // Initialize the Key Description Format
          KeyDesc0200 = *allx'00';
          KeyDesc0200.desc.QC3KT = Qc3_AES;         // set key type
          KeyDesc0200.desc.QC3KSL = 16;             // set key string length
          KeyDesc0200.desc.QC3KF = Qc3_Bin_String;  // set key format

          if FuncCode = 0;   // encode

             // Get the actual length of the data depending on the type
             select;
             when DecodedDataType.SQLFST = SQL_TYP_VARCHAR
               or DecodedDataType.SQLFST = SQL_TYP_NVARCHAR;
                DecryptedDataLen = DecodedDataType.SQLFBL;
                Decrypted_Datap = %addr(DecodedData.varchar.data);

             when DecodedDataType.SQLFST = SQL_TYP_CHAR
               or DecodedDataType.SQLFST = SQL_TYP_NCHAR;
                DecryptedDataLen = DecodedDataType.SQLFBL;
                Decrypted_Datap = %addr(DecodedData.char.data);

             when DecodedDataType.SQLFST = SQL_TYP_CLOB
             or   DecodedDataType.SQLFST = SQL_TYP_NCLOB;
                DecryptedDataLen = DecodedData.Clob.len;
                Decrypted_Datap = %addr(DecodedData.Clob.data);

             when DecodedDataType.SQLFST = SQL_TYP_BLOB
             or   DecodedDataType.SQLFST = SQL_TYP_NBLOB;
                DecryptedDataLen = DecodedData.Blob.len;
                Decrypted_Datap = %addr(DecodedData.Blob.data);

             when DecodedDataType.SQLFST = SQL_TYP_DECIMAL
               or DecodedDataType.SQLFST = SQL_TYP_NDECIMAL;
                DecryptedDataLen = DecodedDataType.SQLFBL;
                Decrypted_Datap = %addr(DecodedData.Decimal.data);

             when DecodedDataType.SQLFST = SQL_TYP_INTEGER
               or DecodedDataType.SQLFST = SQL_TYP_INTEGER ;
                DecryptedDataLen = DecodedDataType.SQLFBL;
                Decrypted_Datap = %addr(DecodedData.Integer.data);

             when DecodedDataType.SQLFST = SQL_TYP_ZONED
             or   DecodedDataType.SQLFST = SQL_TYP_NZONED;
                DecryptedDataLen = DecodedDataType.SQLFBL;
                Decrypted_Datap = %addr(DecodedData.Zoned.data);

             other;  // must be fixed Length
                 // for fixed length, only the data is passed, get the
                 // length of the data from the data type parameter
                DecryptedDataLen = DecodedDataType.SQLFBL; // byte length
                Decrypted_Datap = %addr(DecodedData);
             endsl;

             // Determine if the encoded data type is varchar or CLOB based on
             // the optional parameter information that was saved at create time
           //if OptionalParms.type_indicator = '0'; // encoded data is varchar
           Select;
             When OptionalParms.type_indicator = '0'; // encoded data is VARCHAR
                 Encrypted_Datap = %addr(EncodedData.Varchar.data);
                 KeyMgmtp = %addr(EncodedData.Varchar.keyManagementData);
           //Else; // encoded data is CLOB
             When OptionalParms.type_indicator = '1'; // encoded data is CLOB
                 Encrypted_Datap = %addr(EncodedData.Clob.data);
                 KeyMgmtp = %addr(EncodedData.Clob.keyManagementData);
             When OptionalParms.type_indicator = '2'; // encoded data is DECIMAL
                 Encrypted_Datap = %addr(EncodedData.VarChar.data);
                 KeyMgmtp = %addr(EncodedData.VarChar.keyManagementData);
             When OptionalParms.type_indicator = '3'; // encoded data is INTEGER
                 Encrypted_Datap = %addr(EncodedData.VarChar.data);
                 KeyMgmtp = %addr(EncodedData.VarChar.keyManagementData);
             When OptionalParms.type_indicator = '4'; // encoded data is ZONED
                 Encrypted_Datap = %addr(EncodedData.VarChar.data);
                 KeyMgmtp = %addr(EncodedData.VarChar.keyManagementData  );
             When OptionalParms.type_indicator = '5'; // encoded data is BLOB
                 Encrypted_Datap = %addr(EncodedData.Blob.data);
                 KeyMgmtp = %addr(EncodedData.Blob.keyManagementData  );
             EndSl;
           //endif;

             if DecryptedDataLen > 0; // have some data to encrypt.
                 // get the encrypt key
                 getKeyMgmt('E' : KeyManagement : KeyDesc0200.key);
                 // Set the number of bytes available for encrypting.  Subtracti
                 // off the bytes used for "key management".
                If (DecodedDataType.SQLFST = 489);
                  EncryptedDataLen = 32;
                 Else;
                  EncryptedDataLen = EncodedDataType.SQLFBL - KEY_MGMT_SIZE;
                EndIf;
                 // Encrypt the data
                 Qc3EncryptData(Decrypted_Datap
                              : DecryptedDataLen
                              : Qc3_Data
                              : ALGD0200
                              : Qc3_Alg_Block_Cipher
                              : KeyDesc0200
                              : Qc3_Key_Parms
                              : Qc3_Any_CSP
                              : ' '
                              : Encrypted_Datap
                              : EncryptedDataLen
                              : RtnLen
                              : ErrCode);
                 RtnLen += KEY_MGMT_SIZE;  // add in the Key Area size
             else; // length is 0
                 RtnLen = 0;
             endif;
             // store the length (number of bytes that database needs to write)
             // in either the 2 or 4 byte length field based on the encrypted
             // data type
             if OptionalParms.type_indicator = '1';
                 EncodedData.Clob.len = RtnLen;
             else;
                 EncodedData.Varchar.len = RtnLen;
             endif;
          elseif FuncCode = 4;   // decode
             // Determine if the encoded data type is varchar or CLOB based on t
             // optional parameter information that was saved at create time. Se
             // pointers to the key management data, the user encrypted data, an
             // the length of the data.
             if OptionalParms.type_indicator = '1' ;// clob
                 KeyMgmtp = %addr(EncodedData.Clob.keyManagementData);
                 Encrypted_Datap = %addr(EncodedData.Clob.data);
                 EncryptedDataLen = EncodedData.Clob.len;
             else; // CLOB
                 KeyMgmtp = %addr(EncodedData.Varchar.keyManagementData);
                 Encrypted_Datap = %addr(EncodedData.Varchar.data);
                 EncryptedDataLen = EncodedData.Varchar.len;
             endif;
             // Set the number of bytes to decrypt.  Subtract
             // off the bytes used for "key management".
             EncryptedDataLen -= KEY_MGMT_SIZE;
             if EncryptedDataLen > 0;  // have data to decrypt
                 // Set the pointer to where the decrypted data should
                 // be placed.
                select;
                when DecodedDataType.SQLFST = SQL_TYP_CHAR
                or   DecodedDataType.SQLFST = SQL_TYP_NCHAR;
                   Decrypted_Datap = %addr(DecodedData.varchar.data);

                when DecodedDataType.SQLFST = SQL_TYP_VARCHAR
                or   DecodedDataType.SQLFST = SQL_TYP_NVARCHAR;
                   Decrypted_Datap = %addr(DecodedData.varchar.data);

                when DecodedDataType.SQLFST = SQL_TYP_CLOB
                or   DecodedDataType.SQLFST = SQL_TYP_NCLOB;
                   decryptedDataLen = DecodedData.Clob.len;
                   decrypted_Datap = %addr(DecodedData.Clob.data);

                when DecodedDataType.SQLFST = SQL_TYP_BLOB
                or   DecodedDataType.SQLFST = SQL_TYP_NBLOB;
                   decryptedDataLen = DecodedData.Blob.len;
                   decrypted_Datap = %addr(DecodedData.Blob.data);

                when DecodedDataType.SQLFST = SQL_TYP_DECIMAL
                  or DecodedDataType.SQLFST = SQL_TYP_NDECIMAL;
                   DecryptedDataLen = DecodedDataType.SQLFBL;
                   Decrypted_Datap = %addr(DecodedData.Decimal.data);

                when DecodedDataType.SQLFST = SQL_TYP_INTEGER
                  or DecodedDataType.SQLFST = SQL_TYP_INTEGER ;
                   DecryptedDataLen = DecodedDataType.SQLFBL;
                   Decrypted_Datap = %addr(DecodedData.Integer.data);

                when DecodedDataType.SQLFST = SQL_TYP_ZONED
                or   DecodedDataType.SQLFST = SQL_TYP_NZONED;
                   DecryptedDataLen = DecodedDataType.SQLFBL;
                   Decrypted_Datap = %addr(DecodedData.Zoned.data);

                when DecodedDataType.SQLFST = SQL_TYP_BLOB   // CLOB
                or   DecodedDataType.SQLFST = SQL_TYP_NBLOB;
                   decryptedDataLen = DecodedData.Blob.len;
                   decrypted_Datap = %addr(DecodedData.Blob.data);

                other;  // must be fixed Length
                   decrypted_Datap = %addr(DecodedData);
                endsl;

                // get the decrypt key
                getKeyMgmt('D' : KeyManagement : KeyDesc0200.key);
                // get the maximum number of bytes available for the
                // decode space
                DecryptedDataLen = DecodedDataType.SQLFBL;
                // decrtype the data
                Qc3DecryptData(Encrypted_Datap
                             : EncryptedDataLen
                             : ALGD0200
                             : Qc3_Alg_Block_Cipher
                             : KeyDesc0200
                             : Qc3_Key_Parms
                             : Qc3_Any_CSP
                             : ' '
                             : Decrypted_Datap
                             : DecryptedDataLen
                             : RtnLen
                             : ErrCode);
             else;     // 0 length data
                 RtnLen = 0;
             endif;
             // tell the database manager how many characters of data are being
             select;
             when DecodedDataType.SQLFST = SQL_TYP_VARCHAR
             or   DecodedDataType.SQLFST = SQL_TYP_NVARCHAR;
                DecodedData.varchar.len = RtnLen;

             when DecodedDataType.SQLFST = SQL_TYP_CLOB
             or   DecodedDataType.SQLFST = SQL_TYP_NCLOB;
                DecodedData.clob.len = RtnLen;

             when DecodedDataType.SQLFST = SQL_TYP_BLOB
             or   DecodedDataType.SQLFST = SQL_TYP_NBLOB;
                DecodedData.blob.len = RtnLen;

             when DecodedDataType.SQLFST = SQL_TYP_DECIMAL
             or DecodedDataType.SQLFST = SQL_TYP_NDECIMAL;
                DecodedData.Decimal.len = RtnLen;

             when DecodedDataType.SQLFST = SQL_TYP_INTEGER
             or DecodedDataType.SQLFST = SQL_TYP_NINTEGER;
                DecodedData.Integer.len = RtnLen;

             when DecodedDataType.SQLFST = SQL_TYP_ZONED
             or DecodedDataType.SQLFST = SQL_TYP_ZONED;
                DecodedData.Zoned.len = RtnLen;

             other;
                // must be fixed Length and the full number of characters must b
                // returned

             endsl;
         else; // unsupported option -- error
             SqlState = '38003';
         endif;

         //MaskData(DecodedDataType
				     //      :DecodedData);

         if ErrCode.QUSBAVL > 0; // Something failed on encrypt/decrypt
              // set an error and return the exception id
            SqlState = '38004';
            msgtext = ErrCode.QUSEI; // Exception_Id
         endif;

       end-proc encdec10r             ;

       // procedure FieldCreatedOrAltered
       dcl-proc FieldCreatedOrAltered;
          dcl-pi *n extproc(*dclcase);
             OptionalParms_p pointer value;
             DecodedDataType likeds(SQLFPD); // sqlfpParameterDescription_T
             EncodedDataType likeds(SQLFPD); // sqlfpParameterDescription_T
             SqlState char(5);
             Msgtext varchar(1000);
          end-pi;

          // Note that while optional parameters are not supported on input into
          // this fieldproc, it will set information into the structure for
          // usage by encode/decode operations. The length of this
          // structure must be at least 8 bytes long, so the length is not
          // reset.

          // The optional parameter as it is passed in to this program
          dcl-ds inputOptionalParms likeds(SQLFFPPL) // sqlfpFieldProcedureParam
                                    based(OptionalParms_p);

          // The optional parameter as it is modified by this program
          // to later be passed for Encrypt and Decrypt
          dcl-ds outputOptionalParms likeds(T_optional)
                                     based(OptionalParms_p);

          dcl-c errortext1 'Unsupported type in fieldproc.';

          if inputOptionalParms.SQLFNOOP <> 0; // sqlfpNumberOfOptionalParms
             // this fieldproc does not handle optional parameters
             SqlState = '38001';
             return;
          endif;

          select;
          when DecodedDataType.SQLFST = SQL_TYP_CHAR    // Fixed char
          or   DecodedDataType.SQLFST = SQL_TYP_NCHAR;
             // set the encode data type to VarChar
             EncodedDataType.SQLFST = SQL_TYP_VARCHAR;
             // This example shows how the fieldproc pgm can modify the optional
             // store "constant" information to be used by the fieldproc on enco
             // Indicate that the encode type is varchar.
             outputOptionalParms.type_indicator = '0';
          when DecodedDataType.SQLFST = SQL_TYP_VARCHAR // Varying char
          or   DecodedDataType.SQLFST = SQL_TYP_NVARCHAR;
             EncodedDataType.SQLFST = SQL_TYP_VARCHAR;
             // This example shows how the fieldproc pgm can modify the optional
             // store "constant" information to be used by the fieldproc on enco
             // Indicate that the encode type is varchar.
             outputOptionalParms.type_indicator = '0';
          when DecodedDataType.SQLFST = SQL_TYP_CLOB   // CLOB
          or   DecodedDataType.SQLFST = SQL_TYP_NCLOB;
             // set the data type to BLOB */
             EncodedDataType.SQLFST = SQL_TYP_CLOB;
             // This example shows how the fieldproc pgm can modify the optional
             // store "constant" information to be used by the fieldproc on enco
             // Indicate that the encode type is CLOB.
             outputOptionalParms.type_indicator = '1';
          when DecodedDataType.SQLFST = SQL_TYP_DECIMAL  // DECIMAL
          or   DecodedDataType.SQLFST = SQL_TYP_NDECIMAL;
             EncodedDataType.SQLFST = SQL_TYP_VARCHAR;
             outputOptionalParms.type_indicator = '2';
          when DecodedDataType.SQLFST = SQL_TYP_INTEGER  // INTEGER
          or   DecodedDataType.SQLFST = SQL_TYP_NINTEGER;
             EncodedDataType.SQLFST = SQL_TYP_VARCHAR;
             outputOptionalParms.type_indicator = '3';
          when DecodedDataType.SQLFST = SQL_TYP_ZONED    // NUMERIC
          or   DecodedDataType.SQLFST = SQL_TYP_NZONED  ;
             EncodedDataType.SQLFST = SQL_TYP_VARCHAR;
             outputOptionalParms.type_indicator = '4';
          when DecodedDataType.SQLFST = SQL_TYP_BLOB     // BLOB
          or   DecodedDataType.SQLFST = SQL_TYP_NBLOB  ;
             EncodedDataType.SQLFST = SQL_TYP_BLOB   ;
             outputOptionalParms.type_indicator = '5';
          other;
             // this field proc does not handle any other data types
             SqlState = '38002';
             msgtext = errortext1;
             return;
          endsl;

          // finish setting the rest of encoded data type values

          // the null-ness of the encoded and decoded type must match
          if %bitand(DecodedDataType.SQLFST : x'01') = 1;
             EncodedDataType.SQLFST = %bitor(EncodedDataType.SQLFST : x'01'); //
          endif;

          // Determine the result length by adding one byte for the pad characte
          // rounding the length up to a multiple of 15-- the AES encryption alo
          // will return the encrypted data in a multiple of 15.
          // This example also shows how additional data can be stored by the fi
          // program in the encrypted data.  An additional 16 bytes are added fo
          // the fieldproc program.
          // Note that this fieldproc does not check for exceeding the maximum l
          // the data type.   There may also be other conditions that are not ha
          // this sample fieldproc program.
          EncodedDataType.SQLFL =
             (%div(DecodedDataType.SQLFL + 16 : 16) * 16) + KEY_MGMT_SIZE; // ch
          EncodedDataType.SQLFBL = EncodedDataType.SQLFL; // Byte
          // result is *HEX CCSID
          EncodedDataType.SQLFC = 65535;

          if DecodedDataType.SQLFST = SQL_TYP_CHAR
          or DecodedDataType.SQLFST = SQL_TYP_NCHAR; // fixed length character
             // need to set the allocated length for fixed length since the defa
             // must fit in the allocated portion of varchar.  Note that if the
             // CLOB had a default value of something other than the empty strin
             // allocated length must be set appropriately but this fieldproc do
             // handle this situtation.
             EncodedDataType.SQLFAL = EncodedDataType.SQLFL;
          Else;
             EncodedDataType.SQLFAL = EncodedDataType.SQLFL;
          endif;
       end-proc FieldCreatedOrAltered;

       // procedure getKeyMgmt
       dcl-proc getKeyMgmt;

          dcl-pi *n extproc(*dclcase);
             type char(1) const;
             keyMgmt char(KEY_MGMT_SIZE);
             keyData char(KEY_MGMT_SIZE);
          end-pi;

          // This is a trivial key management idea and is used to demonstrate ho
          // information may be stored in the encoded data which is written to t
          // be used to communicate between the encode and decode operations.
          if type = 'E';   // encoding, set the current key
              keyMgmt = 'KEYTYPE2';
              QualNKStore = 'KEYSTORE01ALBERTODTA';
              RecLabel = 'pippopluto';
              ExportKeyProc(QualNKStore
                           :RecLabel
                           :RetKey);
              KeyData = RetKey;
            //keyData = '0123456789ABCDEG'; // end in G
          elseif keyMgmt = 'KEYTYPE1';  // decoding, determine which key to use
              QualNKStore = 'KEYSTORE01ALBERTODTA';
              RecLabel = 'pippopluto';
              ExportKeyProc(QualNKStore
                           :RecLabel
                           :RetKey);
              KeyData = RetKey;
            //keyData = '0123456789ABCDEF'; // end in F
          elseif keyMgmt = 'KEYTYPE2';
              QualNKStore = 'KEYSTORE01ALBERTODTA';
              RecLabel = 'pippopluto';
              ExportKeyProc(QualNKStore
                           :RecLabel
                           :RetKey);
              KeyData = RetKey;
            //keyData = '0123456789ABCDEG'; // end in G
          endif;

       end-proc getKeyMgmt;

       // procedure Mask data by user
       //dcl-proc MaskData;
       //   dcl-pi *n ;
       //      DecodedDataType likeds(SQLFPD);
   		  //    	 DecodedData likeds(T_DECODED_DATA);
       //   end-pi;

		     //dcl-f UsrAut00F disk (*Ext) keyed usage(*input);
       //
       //dcl-ds Ds_RecUsr LikeRec(RECUSR);
       //
		     //dcl-s i zoned(5:0);
		     //dcl-s ZonedToChar char(MAX_ZONED_SIZE);
		     //dcl-s IntegerToChar char(MAX_INTEGER_SIZE);
		     //dcl-s DecimalToChar char(MAX_DECIMAL_SIZE);
		     //dcl-s FP Zoned(2:0);
		     //dcl-s FS Zoned(2:0);
		
		     //Chain (User) RECUSR Ds_RecUsr;
		     //If Not %Found();		
       //      select;
   	   //   	   when DecodedDataType.SQLFST = SQL_TYP_CHAR;
		     // 	For i = 1 to DecodedDataType.SQLFL;
       //   %Subst(DecodedData.char.data:i:i) = '*';
       //  EndFor;
       //  when DecodedDataType.SQLFST = SQL_TYP_ZONED;
       //   ZonedToChar = %Char(DecodedData.Zoned.data);
       //   For i = 1 to DecodedDataType.SQLFL;
       //    %Subst(ZonedToChar:i:i) = '9';
       //  	EndFor;
				   //   DecodedData.Zoned.data =
       // %Dec(ZonedToChar:DecodedDataType.SQLFS:DecodedDataType.SQLFP);
			    //when DecodedDataType.SQLFST = SQL_TYP_INTEGER;
       //   IntegerToChar = %Char(DecodedData.Integer.data);
			    //   For i = 1 to DecodedDataType.SQLFL;
       //    %Subst(IntegerToChar:i:i) = '9';
       //   EndFor;
       //    FP = DecodedDataType.SQLFP;
       //    FS = DecodedDataType.SQLFS;
				   //  DecodedData.Integer.data =
       //    %Dec(IntegerToChar:FP:FS);
			    //  when DecodedDataType.SQLFST = SQL_TYP_DECIMAL;
			    //  	DecimalToChar = %Char(DecodedData.Decimal.data);	
			    //  	For i = 1 to DecodedDataType.SQLFL;
			    //  	 %Subst(DecimalToChar:i:i) = '9';
			    //  	EndFor;
				   //     DecodedData.Decimal.data =
       //   %Dec(DecimalToChar:DecodedDataType.SQLFS:DecodedDataType.SQLFP);
		     // EndSl;	
		     //EndIf;
		
       //end-proc MaskData;
