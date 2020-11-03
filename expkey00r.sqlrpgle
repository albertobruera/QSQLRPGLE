     H*dftactgrp(*no) bnddir('QC2LE')
      * System includes
     D/Copy QSYSINC/QRPGLESRC,QUSEC
     D/Copy QSYSINC/QRPGLESRC,QC3CCI
      *
     DCrtAlgCtx        pr                  extproc('Qc3CreateAlgorithmContext')
     D algD                           1    const
     D algFormat                      8    const
     D AESctx                         8
     D errCod                         1
      *
     DCrtKeyCtx        pr                  extproc('Qc3CreateKeyContext')
     D key                            1    const
     D keySize                       10i 0 const
     D keyFormat                      1    const
     D keyType                       10i 0 const
     D keyForm                        1    const
     D keyEncKey                      8    const options(*omit)
     D keyEncAlg                      8    const options(*omit)
     D keyTkn                         8
     D errCod                         1

     dExportKey        pr                  extproc('Qc3ExportKey')
     d Keystring                      1    const
     d LenKeyString                  10i 0
     d KeyStrFormat                   1a   const
     d KEKCtxToken                    8a
     d KEncAlgCtxTkn                  8a
     d ExportedKey                  256
     d LenExpKeyPrv                  10i 0 const
     d LenExpKeyRet                  10i 0
     d Error                               LikeDs(QUSEC)

     D AESctx          s              8
     D AESkctx         s              8
     D KEKctx          s              8
     D FKctx           s              8
     D keySize         s             10i 0
     D keyType         s             10i 0
     D keyLen          s             10i 0
     D keyFormat       s              1
     D keyForm         s              1
     d p_KStr          s               *
     d LenExpKRet      s             10i 0
     d ExportedKey     s            256a

     DDestroyKeyCtx    pr                  extproc('Qc3DestroyKeyContext')
     D keyTkn                         8    const
     D errCod                         1

     DDestroyAlgCtx    pr                  extproc('Qc3DestroyAlgorithmContext')
     D AESTkn                         8    const
     D errCod                         1

     pExportKeyProc    b                   export
     d ExportKeyProc   pi
     d QualNKeyStore                 20a
     d RecLabel                      32a
     d RetKey                       256a

     C                   eval      QC3D040000 = *loval
     C                   eval      QC3KS00 = QualNKeyStore
     c                   eval      QC3RL   = RecLabel

      * Create a key context for KEYSTORE01
     C                   eval      keySize = %size(QC3D040000)
     C                   eval      keyType = 22
     C                   eval      keyForm = '0'
     C                   callp     CrtKeyCtx( QC3D040000 :keySize :'4'
     C                                       :keyType    :keyForm :*OMIT
     C                                       :*OMIT      :KEKctx  :QUSEC)

      * Create an AES algorithm context
     C                   eval      QC3D0200 = *loval
     C                   eval      QC3BCA = keyType
     C                   eval      QC3BL = 16
     C                   eval      QC3MODE = '1'
     C                   eval      QC3PO = '0'
     C                   callp     CrtAlgCtx( QC3D0200 :'ALGD0200'
     C                                       :AESctx   :QUSEC)
     C
      *Export Key
     c                   Eval      P_KStr = %Addr(QC3D040000)
     C                   callp     Exportkey( QC3D040000 :keySize :'4'
     C                                       :KEKctx     :AESctx :ExportedKey
     C                                       :128        :LenExpKRet :QUSEC)

     c                   Eval      RetKey = ExportedKey

      * Cleanup
     C                   callp     DestroyKeyCtx( KEKctx  :QUSEC)
     C                   callp     DestroyAlgCtx( AESctx  :QUSEC)

     C                   EVAL      *Inlr = *On
     pExportKeyProc    e
