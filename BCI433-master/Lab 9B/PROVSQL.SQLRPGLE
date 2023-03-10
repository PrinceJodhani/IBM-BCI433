       //***********************************************************************
       //* THIS PROGRAM USES A CURSOR TO LOAD A TEMPORARY RESULT TABLE FROM 3
       //* SEPARATE TABLES, ONTARIO, QUEBEC AND MANITOBA. A NUMBER IS PASSED
       //* TO THE PROGRAM TO DETERMINE WHICH RECORDS ARE INLCUDED FROM THE 3 TAB
       //***********************************************************************
           DCL-F PROVREPORT PRINTER OFLIND(*IN01) ;
           DCL-S ProvinceH    Char(10);
           DCL-S EndOfFile    IND;
           DCL-S TotalRecords PACKED(5:0) ;
       // LowLimit is passed to the program
           Dcl-PI Main extPgm('PROVSQLH');
             LowLimitIn Packed(15:5);
           END-PI;


       // All Host Variables available under a single name

            DCL-DS CustomerRecord;
             CustId    Char(6);
             FullName  Char(31);
             City      Char(20);
             Purchase  Packed(7:2);
             PDate     Date;
             Province  Char(10);
           END-DS;







     C/EJECT
     C**************************************************************************
     C*                        ***   M A I N   R O U T I N E   ***
     C**************************************************************************
      /FREE
                LowLimit = LowLimitIn;
                EXSR PrepareFiles;
                Write StartOfRpt;
                Write ColHeading;
                EXSR GetRow;
                Write NewProv;
                ProvinceH = Province;
                DOW NOT EndOfFile;
                    IF *IN01 = *ON;
                        Write StartOfRpt;
                        Write ColHeading;
                       *IN01 = *OFF;
                    ENDIF;
           // Province may change
                 If ProvinceH = Province;
                    Write CustDetail;
                 Else;
                    ProvinceH = Province;
                    Write TotalPurch;
                    TotalAmt = 0;
                    Write NewProv;
                    Write CustDetail;
                  ENDIF;
                    TotalAmt     = TotalAmt     + Purchase;
                    TotalRecords= TotalRecords + 1;
                    EXSR GetRow;
                ENDDO;
                Write TotalPurch;
                EXSR   WRAPUP;
                Write LessThan;
                *INLR = *ON;
                RETURN;
        //**********************************************************************
        // O P E N F I L E S   S U B R O U T I N E
        //**********************************************************************
         BEGSR  PrepareFiles;
        // S E T   U P   T H E   T E M P O R A R Y   R E S U L T  S T R U C T U


         EXEC SQL
        DECLARE ALLPROVCURSOR CURSOR
             FOR

          SELECT CustId, TRIM(FNAME) || ' ' || LNAME AS FullName,
            City, Purchase, PDate,
            'Ontario' as Province
            FROM BCI433LIB/ONTARIO
            WHERE Purchase > :LowLimit
            union all
          SELECT CustId, TRIM(FNAME) || ' ' || LNAME AS FullName,
            City, Purchase, PDate,
            'Ouebec' as Province
            FROM BCI433LIB/QUEBEC
            WHERE Purchase > :LowLimit
            union all
          SELECT CustId, TRIM(FNAME) || ' ' || LNAME AS FullName,
            City, Purchase, PDate,
            'Manitoba' as Province
            FROM BCI433LIB/MANITOBA
            WHERE Purchase > :LowLimit
            FOR READ ONLY;



        // A   T E M P O R A R Y   R E S U L T   T A B L E   I S   C R E A T E D

            EXEC SQL
             OPEN ALLPROVCURSOR;

        If (SQLCODE <> 0) OR (SQLWN0 = 'W');
          EndOfFile = *ON;
        ENDIF;


            ENDSR;
        //**********************************************************************
        //   G E T     R O W    S U B R O U T I N E
        //**********************************************************************
            BEGSR     GETROW;
              EXEC SQL
              FETCH NEXT
              FROM ALLPROVCURSOR
              INTO :CustomerRecord;

              If (SQLCODE <> 0) OR (SQLWN0 = 'W');
                EndOfFile = *ON;
              ENDIF;











             ENDSR;
        //**********************************************************************
        // W R A P U P     S U B R O U T I N E
        //**********************************************************************
           BEGSR WRAPUP;
           EXEC SQL
               CLOSE ALLPROVCURSOR;

           If (SQLCODE <> 0) OR (SQLWN0 = 'W');
                EndOfFile = *ON;
              ENDIF;

           EXEC SQL
             SELECT COUNT(*) INTO :ONTTOTAL
               FROM BCI433LIB/ONTARIO
               WHERE Purchase <= :LowLimit;

           EXEC SQL
             SELECT COUNT(*) INTO :QUETOTAL
               FROM BCI433LIB/QUEBEC
               WHERE Purchase <= :LowLimit;

           EXEC SQL
             SELECT COUNT(*) INTO :MANTOTAL
               FROM BCI433LIB/MANITOBA
               WHERE Purchase <= :LowLimit;


          ENDSR;        