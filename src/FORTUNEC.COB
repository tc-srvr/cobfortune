       IDENTIFICATION DIVISION.
       PROGRAM-ID. FORTUNEC.

      ******************************************************************
      *  FORTUNEC.COB - Fortune Cookie Compiler
      *  This program compiles a text file of fortune cookies into a
      *  line-indexed file for use by the fortune cookie program.
      *  The input file is expected to be in the standard fortune-mod
      *  format, with each fortune cookie separated by a line containing
      *  only a single percent sign (%).
      *  The output file is a line-indexed file with each fortune cookie
      *  stored as a record, along with a header record containing 
      *  metadata about the fortune cookie.
      *  The program reads the input file, processes each fortune 
      *  cookie, and writes the corresponding records to the output 
      *  file. The program also maintains a count of the number of 
      *  fortune cookies processed and updates the header record 
      *  accordingly.
      *  
      *  Author: THOMAS CORRIGAN
      *  Date: 2026-08-08
      ******************************************************************
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT FORTUNE-FILE ASSIGN TO WS-FORTUNE-FILE-OUTPUT
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS FF-KEY
               FILE STATUS IS FF-OUTFILE-STATUS.

           SELECT FORTUNE-INPUT-FILE ASSIGN TO WS-FORTUNE-FILE-INPUT
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS FF-INFILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  FORTUNE-FILE.
       01  FORTUNE-RECORD.
           05  FF-KEY.
               10  FF-KEY-INDEX                       PIC 9(7) COMP-3.
               10  FF-KEY-LINE                        PIC 9(3) COMP-3.
           05  FF-RECORD.
               10  FF-TEXT                            PIC U(80).
           05  FF-HEADER REDEFINES FF-RECORD.
               10  FF-NAME                            PIC U(20).
               10  FF-COUNT                           PIC 9(7) COMP-3.
               10  FF-IS-OFFENSIVE                    PIC X VALUE 'N'.
               10  FF-DATE-CREATED                    PIC 9(8).
               10  FF-DATE-UPDATED                    PIC 9(8).
               10  FF-VERSION                         PIC 9(3) COMP-3.
               10  FILLER                             PIC X(38).

       FD  FORTUNE-INPUT-FILE.
       01  FORTUNE-INPUT-RECORD.
           05  FF-INPUT-TEXT                        PIC U(80).

       WORKING-STORAGE SECTION.
       77  VERSION-NUMBER    PIC ZZ9.99 VALUE '1.00'.
       77  NAME-OF-PROGRAM   PIC X(9) VALUE 'FORTUNEC '.
       77  DESCRIPTION       PIC X(80) VALUE 'Fortune Cookie Compiler'.
       
       77  FF-OUTFILE-STATUS PIC XX.
       77  FF-INFILE-STATUS  PIC XX.

       01  WS-VARS.
           05  WS-ERROR-OCCURED               PIC X VALUE 'N'.
           05  WS-FORTUNE-FILE-OUTPUT         PIC X(256) VALUE SPACES.
           05  WS-FORTUNE-FILE-INPUT          PIC X(256) VALUE SPACES.
           05  WS-FORTUNE-COUNT               PIC 9(7) COMP-3 VALUE 0.
           05  WS-FORTUNE-LINE-COUNT          PIC 9(3) COMP-3 VALUE 0.
           05  WS-FORTUNE-IS-OFFENSIVE-FLAG   PIC X(5) VALUE 'N'.
      * Allowable values for WS-FORTUNE-IS-OFFENSIVE-FLAG are 
      * 'Y', 'N', 'y', 'n', 'yes', 'no', 'YES', 'NO', 't', 'f', 'T', 
      * 'F', 'true', 'false', 'TRUE', 'FALSE' 'Yes' 'No' 'True' 'False'
      * to allow for the program to be forgiving of user input. 
               88  WS-FORTUNE-IS-OFFENSIVE 
                   VALUE 'Y' 'y' 'yes' 'YES' 't' 'T' 'true' 'TRUE'
                          'Yes' 'True'.
               88  WS-FORTUNE-IS-NOT-OFFENSIVE
                   VALUE 'N' 'n' 'no' 'NO' 'f' 'F' 'false' 'FALSE'
                          'No' 'False'.
           05  WS-FORTUNE-DATE-CREATED        PIC 9(8) VALUE 0.
           05  WS-FORTUNE-DATE-UPDATED        PIC 9(8) VALUE 0.
           05  WS-FORTUNE-VERSION             PIC 9(3) COMP-3 VALUE 1.
           05  WS-FORTUNE-NAME                PIC X(20).
           05  WS-FORTUNE-RECORD.
               10  WS-FORTUNE-FIRST-CHARACTER PIC U VALUE SPACES.
               10  FILLER                     PIC U(79) VALUE SPACES.
           05  WS-VERBOSE-MODE                PIC X VALUE 'N'.
           05  WS-HELP-MODE                   PIC X VALUE 'N'.
      * offensive fortunes will not be stored as plain text.
        01  WS-ROT13.
           05  WS-ROT13-INPUT                      PIC X(52)
           VALUE 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'.
           05  WS-ROT13-OUTPUT                     PIC X(52)
           VALUE 'NOPQRSTUVWXYZABCDEFGHIJKLMnopqrstuvwxyzabcdefghijklm'.

       01  HELP-MESSAGE.
           05  HELP-MESSAGE-TEXT.
               10  FILLER              PIC X(80) 
           VALUE 'Usage: fortunec -i inputfile -o outputfile [-v]' &
      -          '[-f Y/N]'.
               10  FILLER              PIC X(80)
           VALUE '  -i inputfile  : Input file containing fortunes'.
               10  FILLER              PIC X(80)
           VALUE '  -o outputfile : Output file to write compiled' &
      -           'fortunes'.
               10  FILLER              PIC X(80)
           VALUE '  -v            : Verbose mode, displays ' & 
      -           'processing information'.
               10  FILLER              PIC X(80)
           VALUE '  -f            : Mark fortunes as offensive'.
               10  FILLER              PIC X(80)
           VALUE '  -h            : Display this help message'.
           05  FILLER REDEFINES HELP-MESSAGE-TEXT.
               10  HELP-LINE           PIC X(80) OCCURS 6 TIMES
                   INDEXED BY HELP-LINE-IDX.

      * THIS IS UGLY, BUT  IT IS THE ONLY WAY I COULD FIGURE OUT HOW TO
      * PASS MULTIPLE ARGUMENTS TO A COBOL PROGRAM FROM THE COMMAND
      * LINE. THE CHAINING STATEMENT IN THE PROCEDURE DIVISION WILL
      * PASS THE ARGUMENTS TO THE PROGRAM. ANY ATTEMPT TO USE AN ARRAY
      * OR TABLE TO PASS THE ARGUMENTS WILL ONLY PASS THE FIRST ARGUMENT.

       01  LS-ARG1 PIC X(256) VALUE SPACES .
       01  LS-ARG2 PIC X(256) VALUE SPACES .
       01  LS-ARG3 PIC X(256) VALUE SPACES .
       01  LS-ARG4 PIC X(256) VALUE SPACES .
       01  LS-ARG5 PIC X(256) VALUE SPACES .
       01  LS-ARG6 PIC X(256) VALUE SPACES .
       01  LS-ARG7 PIC X(256) VALUE SPACES .
       01  LS-ARG8 PIC X(256) VALUE SPACES .

       01 LS-ARGUMENTS.
           05  LS-ARGUMENT OCCURS 8 TIMES
               INDEXED BY LS-ARGUMENT-IDX.
               10 LS-ARGUMENT-SWITCH        PIC X(2)   VALUE SPACES.
               88 LS-ARG-INPUT-FILE-SWITCH             VALUE '-i'.
               88 LS-ARG-OUTPUT-FILE-SWITCH            VALUE '-o'.
               88 LS-ARG-VERBOSE-SWITC                 VALUE '-v'.
               88 LS-ARG-OFFENSIVE-SWITCH              VALUE '-f'.
               88 LS-ARG-HELP-SWITCH                   VALUE '-h'.
               88 LS-ARG-IS-SWITCH                     
                  VALUE '-i' '-o' '-v' '-f' '-h'.                                    
               10 FILLER                    PIC X(254) VALUE SPACES.              

       PROCEDURE DIVISION CHAINING LS-ARG1 LS-ARG2 LS-ARG3 LS-ARG4 
                                   LS-ARG5 LS-ARG6 LS-ARG7 LS-ARG8.
               DISPLAY NAME-OF-PROGRAM VERSION-NUMBER ' - ' DESCRIPTION.
               PERFORM 10000-PROCESS-ARGUMENTS
                  THRU 10000-EXIT.
               IF WS-HELP-MODE = 'Y'
                  PERFORM VARYING HELP-LINE-IDX FROM 1 BY 1 
                            UNTIL HELP-LINE-IDX GREATER THAN 6
                     DISPLAY HELP-LINE (HELP-LINE-IDX)
                  END-PERFORM
                  GO TO 00000-EXIT.
                PERFORM 20000-OPEN-FILES
                   THRU 20000-EXIT.
                IF  WS-ERROR-OCCURED EQUAL 'Y'
                    GO TO 00000-EXIT.
      *         PERFORM 30000-PROCESS-FORTUNES.
      *         PERFORM 40000-CLOSE-FILES.
      *         PERFORM 90000-CLEANUP.
       00000-EXIT.
               STOP RUN.    

       10000-PROCESS-ARGUMENTS.
           IF  LS-ARG1 EQUAL SPACES
               MOVE 'Y' TO WS-HELP-MODE
               GO TO 10000-EXIT
           END-IF.

           MOVE LS-ARG1 TO LS-ARGUMENT (1).
           MOVE LS-ARG2 TO LS-ARGUMENT (2).
           MOVE LS-ARG3 TO LS-ARGUMENT (3).
           MOVE LS-ARG4 TO LS-ARGUMENT (4).
           MOVE LS-ARG5 TO LS-ARGUMENT (5).
           MOVE LS-ARG6 TO LS-ARGUMENT (6).
           MOVE LS-ARG7 TO LS-ARGUMENT (7).
           MOVE LS-ARG8 TO LS-ARGUMENT (8).

           PERFORM VARYING LS-ARGUMENT-IDX FROM 1 BY 1
                     UNTIL LS-ARGUMENT-IDX GREATER THAN 8
               IF  LS-ARGUMENT (LS-ARGUMENT-IDX) NOT EQUAL SPACES
                   IF  NOT LS-ARG-IS-SWITCH (LS-ARGUMENT-IDX)
                       DISPLAY 'Invalid switch: ' 
      -                         LS-ARGUMENT (LS-ARGUMENT-IDX)
                       MOVE 'Y' TO WS-HELP-MODE
                   END-IF
                   IF  LS-ARGUMENT-SWITCH (LS-ARGUMENT-IDX) = '-i'
                       PERFORM 10100-CHECK-INPUT-FILE-SWITCH
                          THRU 10100-EXIT
                   ELSE IF LS-ARGUMENT-SWITCH (LS-ARGUMENT-IDX) = '-o'
                       PERFORM 10200-CHECK-OUT-FILE-SWITCH
                          THRU 10200-EXIT
                   ELSE IF LS-ARGUMENT-SWITCH (LS-ARGUMENT-IDX) = '-v'
                       MOVE 'Y' TO WS-VERBOSE-MODE
                   ELSE IF LS-ARGUMENT-SWITCH (LS-ARGUMENT-IDX) = '-f'
                      ADD  1 
                        TO LS-ARGUMENT-IDX
                       IF  LS-ARGUMENT-IDX NOT GREATER THAN 8
                          MOVE LS-ARGUMENT (LS-ARGUMENT-IDX) 
                            TO WS-FORTUNE-IS-OFFENSIVE-FLAG
                      ELSE
                          MOVE SPACES 
                            TO WS-FORTUNE-IS-OFFENSIVE-FLAG
                      END-IF      
                      IF  NOT WS-FORTUNE-IS-OFFENSIVE 
                      AND NOT WS-FORTUNE-IS-NOT-OFFENSIVE
                          DISPLAY 'Invalid value for -f switch. ' &
      -                           'Use Y or N.'
                          MOVE 'Y' TO WS-HELP-MODE
                      END-IF  
                   ELSE IF LS-ARGUMENT-SWITCH (LS-ARGUMENT-IDX) = '-h'
                       MOVE 'Y' TO WS-HELP-MODE
                   END-IF
               END-IF
           END-PERFORM.
       10000-EXIT.
           EXIT.

       10100-CHECK-INPUT-FILE-SWITCH.
           ADD 1 
            TO LS-ARGUMENT-IDX
           IF  LS-ARGUMENT-IDX NOT GREATER THAN 8 
           AND NOT LS-ARG-IS-SWITCH (LS-ARGUMENT-IDX)
                 MOVE LS-ARGUMENT (LS-ARGUMENT-IDX) 
                   TO WS-FORTUNE-FILE-INPUT
            ELSE
               SUBTRACT 1 
                FROM LS-ARGUMENT-IDX
           END-IF.
           IF  WS-FORTUNE-FILE-INPUT EQUAL SPACES
                  DISPLAY 'Input file not specified. Use -i switch.'
                  MOVE 'Y' TO WS-HELP-MODE
            END-IF.
       10100-EXIT.
           EXIT.
       10200-CHECK-OUT-FILE-SWITCH.
           ADD 1 
            TO LS-ARGUMENT-IDX
           IF  LS-ARGUMENT-IDX NOT GREATER THAN 8 
           AND NOT LS-ARG-IS-SWITCH (LS-ARGUMENT-IDX)
                 MOVE LS-ARGUMENT (LS-ARGUMENT-IDX) 
                   TO WS-FORTUNE-FILE-OUTPUT
           ELSE
               SUBTRACT 1 
                FROM LS-ARGUMENT-IDX
           END-IF.
           IF  WS-FORTUNE-FILE-OUTPUT EQUAL SPACES
                  DISPLAY 'Output file not specified. Use -o switch.'
                  MOVE 'Y' TO WS-HELP-MODE
            END-IF.
       10200-EXIT.
           EXIT.    

       20000-OPEN-FILES.
           PERFORM 20100-OPEN-INPUT-FILE
              THRU 20100-EXIT.
           IF  WS-ERROR-OCCURED EQUAL 'Y'
               GO TO 20000-EXIT.
           PERFORM 20200-OPEN-OUTPUT-FILE
              THRU 20200-EXIT. 
       20000-EXIT.
           EXIT.

       20100-OPEN-INPUT-FILE.
           IF  WS-VERBOSE-MODE EQUAL 'Y'
               DISPLAY 'Opening input file: ' WS-FORTUNE-FILE-INPUT
           END-IF.
           OPEN INPUT FORTUNE-INPUT-FILE.
           IF  FF-INFILE-STATUS NOT EQUAL '00'
               MOVE 'Y'                     TO WS-ERROR-OCCURED
               DISPLAY 'Error opening input file: '
      -            WS-FORTUNE-FILE-INPUT ' Status: ' 
      -            FF-INFILE-STATUS
           END-IF.
       20100-EXIT.
           EXIT.

       20200-OPEN-OUTPUT-FILE.
           IF  WS-VERBOSE-MODE EQUAL 'Y'
               DISPLAY 'Opening output file: ' WS-FORTUNE-FILE-OUTPUT
           END-IF.
           OPEN I-O FORTUNE-FILE.
           IF  FF-OUTFILE-STATUS NOT EQUAL '00'
               MOVE 'Y'                     TO WS-ERROR-OCCURED
               DISPLAY 'Error opening input file: '
      -                WS-FORTUNE-FILE-INPUT ' Status: ' 
      -                FF-INFILE-STATUS 
           END-IF.
       20200-EXIT.
           EXIT.    

       



