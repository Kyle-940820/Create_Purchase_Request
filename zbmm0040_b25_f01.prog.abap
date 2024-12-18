*&---------------------------------------------------------------------*
*& Include          ZBMM0040_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form SET_ACTIVETAB
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_ACTIVETAB .
  "TAB STRIP 에서 선택한 TAB에 따라 불러온 SUB SCREEN 설정.
  CASE TAB_STRIP-ACTIVETAB.
    WHEN 'TAB1'.
      GV_DYNNR = '0110'.
    WHEN 'TAB2'.
      GV_DYNNR = '0120'.
    WHEN OTHERS.
      TAB_STRIP-ACTIVETAB = 'TAB1'.
      GV_DYNNR = '0110'.
  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form GET_SUPPLIER
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM GET_SUPPLIER .
  DATA: LV_ANSWER. " CONFIRM POPUP RETURN 변수.
  DATA: LS_BTN TYPE LVC_S_STYL. " ALV1에 버튼 만드는 변수.
  DATA: LV_BPNAME TYPE STRING. " BPNAME SELECT-OPTION 변수.
  DATA: RT_BPCODE TYPE RANGE OF ZSBMM0010_ALV1-BPCODE, " BPCODE Range 변수.
        RS_BPCODE LIKE LINE OF RT_BPCODE.

  DATA: LS_DISPLAY1 LIKE GS_DISPLAY1,
        LT_DISPLAY1 LIKE TABLE OF LS_DISPLAY1.

* 구매요청 자재 리스트 ALV2에 데이터가 존재할 때 초기화 컨펌 팝업.
  IF GT_DISPLAY2 IS NOT INITIAL.

    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        TITLEBAR              = TEXT-T01 " 구매요청 자재 리스트 초기화 확인.
        TEXT_QUESTION         = TEXT-Q01 " 구매요청 자재 리스트가 초기화 됩니다. 새로 조회하시겠습니까?
        TEXT_BUTTON_1         = 'YES'
        ICON_BUTTON_1         = 'ICON_OKAY'
        TEXT_BUTTON_2         = 'NO'
        ICON_BUTTON_2         = 'ICON_CANCEL'
        DEFAULT_BUTTON        = '1'
        DISPLAY_CANCEL_BUTTON = ''
      IMPORTING
        ANSWER                = LV_ANSWER.

    IF LV_ANSWER = '2'. " 컨펌팝업에서 NO 눌렀을 때.
      MESSAGE S237.

    ELSE. " 컨펀팝업에서 YES 눌렀을 때.
      CLEAR: GT_DISPLAY2, GS_DISPLAY2, GT_DISPLAY1, GS_DISPLAY1, ZSBMM0060.

* BP명 필드에 입력한 글자를 포함하는 단어에 대해서 조회결과를 얻기 위해 앞 뒤로 %를 붙임.
      LV_BPNAME = '%' && ZSBMM0010_ALV1-BPNAME && '%'.

      IF ZSBMM0010_ALV1-BPCODE IS NOT INITIAL.
        RS_BPCODE-SIGN = 'I'.
        RS_BPCODE-OPTION = 'EQ'.
        RS_BPCODE-LOW = ZSBMM0010_ALV1-BPCODE.
        APPEND RS_BPCODE TO RT_BPCODE.
      ENDIF.

* 조회 조건에 해당하는 결과값에 대해 확인.
      SELECT *
         FROM ZTBMM0070 AS A
    LEFT JOIN ZTBSD1051 AS B
           ON A~BPCODE EQ B~BPCODE
        WHERE A~BPCODE IN @RT_BPCODE
          AND B~BPNAME LIKE @LV_BPNAME
         INTO CORRESPONDING FIELDS OF TABLE @LT_DISPLAY1.

      DELETE ADJACENT DUPLICATES FROM LT_DISPLAY1 COMPARING BPCODE.

      READ TABLE LT_DISPLAY1 TRANSPORTING NO FIELDS INDEX 1.

      IF SY-SUBRC = 0. " 조회 결과값이 존재할 때.

        READ TABLE LT_DISPLAY1 TRANSPORTING NO FIELDS INDEX 2.

        IF SY-SUBRC = 0. " 조회 조건 결과가 2개 이상일때.
          MESSAGE S238 DISPLAY LIKE 'E'.

        ELSE. " 조회 조건 결과가 1개 일때.

* 거래처 조회 조건에 해당하는 인포레코드 ALV1 ITAB에 담기.
          SELECT *
             FROM ZTBMM0070 AS A
        LEFT JOIN ZTBSD1051 AS B
               ON A~BPCODE EQ B~BPCODE
        LEFT JOIN ZTBMM1011 AS C
               ON A~MATCODE EQ C~MATCODE
            WHERE A~BPCODE IN @RT_BPCODE
              AND B~BPNAME LIKE @LV_BPNAME
            ORDER BY A~MATCODE ASCENDING
             INTO CORRESPONDING FIELDS OF TABLE @GT_DISPLAY1.

* 거래처 조회 조건에 해당하는 거래처를 거래처 정보박스에 띄우기.
          SELECT SINGLE *
             FROM ZTBSD1050 AS A
        LEFT JOIN ZTBSD1051 AS B
               ON A~BPCODE EQ B~BPCODE
            WHERE A~BPCODE IN @RT_BPCODE
              AND B~BPNAME LIKE @LV_BPNAME
             INTO CORRESPONDING FIELDS OF @ZSBMM0060.

          SELECT SINGLE BPNAME " 거래처 명 취득.
            FROM ZTBSD1051
           WHERE BPCODE EQ @ZSBMM0060-BPCODE
            INTO @ZSBMM0060-BPNAME1.

          SELECT SINGLE BPNAME " 은행 명 취득.
            FROM ZTBSD1051
           WHERE BPCODE EQ 'BP00000015'
            INTO @ZSBMM0060-BPNAME2.

          SELECT SINGLE TERMTXT " 지급조건설명 취득.
            FROM ZTBFI0040
           WHERE ZTERM EQ @ZSBMM0060-ZTERM
            INTO @ZSBMM0060-TERMTXT.

* ALV1의 'ADD', 'DEL' 필드에 '추가', '차감' 버튼 생성.
          LOOP AT GT_DISPLAY1 INTO GS_DISPLAY1.
            LS_BTN-FIELDNAME = 'ADD'.
            LS_BTN-STYLE = CL_GUI_ALV_GRID=>MC_STYLE_BUTTON.
            APPEND LS_BTN TO GS_DISPLAY1-GT_BTN1.
            CLEAR LS_BTN.

            GS_DISPLAY1-ADD = '추가'.

            LS_BTN-FIELDNAME = 'DEL'.
            LS_BTN-STYLE = CL_GUI_ALV_GRID=>MC_STYLE_BUTTON.
            APPEND LS_BTN TO GS_DISPLAY1-GT_BTN1.
            CLEAR LS_BTN.

            GS_DISPLAY1-DEL = '차감'.
            MODIFY GT_DISPLAY1 FROM GS_DISPLAY1.

            MESSAGE S241. " 조회에 성공하였습니다.
          ENDLOOP.
        ENDIF.
      ELSE. " 조회 결과값이 존재하지 않을 때.
        MESSAGE S210 DISPLAY LIKE 'E'. " 조회 조건에 해당하는 데이터가 없습니다.
      ENDIF.
    ENDIF.

  ELSE. " 구매요청 자재 리스트 ALV2에 데이터 없으면 바로 조회.
    CLEAR: GT_DISPLAY2, GS_DISPLAY2, GT_DISPLAY1, GS_DISPLAY1, ZSBMM0060.

    LV_BPNAME = '%' && ZSBMM0010_ALV1-BPNAME && '%'.

    IF ZSBMM0010_ALV1-BPCODE IS NOT INITIAL.
      RS_BPCODE-SIGN = 'I'.
      RS_BPCODE-OPTION = 'EQ'.
      RS_BPCODE-LOW = ZSBMM0010_ALV1-BPCODE.
      APPEND RS_BPCODE TO RT_BPCODE.
    ENDIF.

* 거래처 조회 조건에 해당하는 인포레코드 정보 GT_DISPLAY1에 담기.
    SELECT *
       FROM ZTBMM0070 AS A
  LEFT JOIN ZTBSD1051 AS B
         ON A~BPCODE EQ B~BPCODE
      WHERE A~BPCODE IN @RT_BPCODE
        AND B~BPNAME LIKE @LV_BPNAME
       INTO CORRESPONDING FIELDS OF TABLE @LT_DISPLAY1.

    DELETE ADJACENT DUPLICATES FROM LT_DISPLAY1 COMPARING BPCODE.

    READ TABLE LT_DISPLAY1 TRANSPORTING NO FIELDS INDEX 1.

    IF SY-SUBRC = 0. " 조회 결과값이 존재할 때.

      READ TABLE LT_DISPLAY1 TRANSPORTING NO FIELDS INDEX 2.

      IF SY-SUBRC = 0. " 조회 조건 결과가 2개 이상일때.
        MESSAGE S238 DISPLAY LIKE 'E'.

      ELSE. " 조회 조건 결과가 1개 일때.

* 거래처 조회 조건에 해당하는 인포레코드 ALV1 ITAB에 담기.
        SELECT *
           FROM ZTBMM0070 AS A
      LEFT JOIN ZTBSD1051 AS B
             ON A~BPCODE EQ B~BPCODE
      LEFT JOIN ZTBMM1011 AS C
             ON A~MATCODE EQ C~MATCODE
          WHERE A~BPCODE IN @RT_BPCODE
            AND B~BPNAME LIKE @LV_BPNAME
          ORDER BY A~MATCODE ASCENDING
           INTO CORRESPONDING FIELDS OF TABLE @GT_DISPLAY1.

* 거래처 조회 조건에 해당하는 거래처 정보 띄우기.
        SELECT SINGLE *
           FROM ZTBSD1050 AS A
      LEFT JOIN ZTBSD1051 AS B
             ON A~BPCODE EQ B~BPCODE
          WHERE A~BPCODE IN @RT_BPCODE
            AND B~BPNAME LIKE @LV_BPNAME
           INTO CORRESPONDING FIELDS OF @ZSBMM0060.

        SELECT SINGLE BPNAME
          FROM ZTBSD1051
         WHERE BPCODE EQ @ZSBMM0060-BPCODE
          INTO @ZSBMM0060-BPNAME1.

        SELECT SINGLE BPNAME
          FROM ZTBSD1051
         WHERE BPCODE EQ 'BP00000015'
          INTO @ZSBMM0060-BPNAME2.

        SELECT SINGLE TERMTXT
          FROM ZTBFI0040
         WHERE ZTERM EQ @ZSBMM0060-ZTERM
          INTO @ZSBMM0060-TERMTXT.

        LOOP AT GT_DISPLAY1 INTO GS_DISPLAY1.
          LS_BTN-FIELDNAME = 'ADD'.
          LS_BTN-STYLE = CL_GUI_ALV_GRID=>MC_STYLE_BUTTON.
          APPEND LS_BTN TO GS_DISPLAY1-GT_BTN1.
          CLEAR LS_BTN.

          GS_DISPLAY1-ADD = '추가'.

          LS_BTN-FIELDNAME = 'DEL'.
          LS_BTN-STYLE = CL_GUI_ALV_GRID=>MC_STYLE_BUTTON.
          APPEND LS_BTN TO GS_DISPLAY1-GT_BTN1.
          CLEAR LS_BTN.

          GS_DISPLAY1-DEL = '차감'.
          MODIFY GT_DISPLAY1 FROM GS_DISPLAY1.

          MESSAGE S241. " 성공적으로 조회되었습니다.
        ENDLOOP.
      ENDIF.

    ELSE. " 조회 결과값이 존재하지 않을 때.
      MESSAGE S210 DISPLAY LIKE 'E'.
    ENDIF.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form CREATE_OBJECT_1
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CREATE_OBJECT_1 .
  CREATE OBJECT GO_CUST1
    EXPORTING
      CONTAINER_NAME              = 'CUST1'
    EXCEPTIONS
      CNTL_ERROR                  = 1
      CNTL_SYSTEM_ERROR           = 2
      CREATE_ERROR                = 3
      LIFETIME_ERROR              = 4
      LIFETIME_DYNPRO_DYNPRO_LINK = 5
      OTHERS                      = 6.
  IF SY-SUBRC <> 0.
  ENDIF.

  CREATE OBJECT GO_ALV1
    EXPORTING
      I_PARENT          = GO_CUST1
    EXCEPTIONS
      ERROR_CNTL_CREATE = 1
      ERROR_CNTL_INIT   = 2
      ERROR_CNTL_LINK   = 3
      ERROR_DP_CREATE   = 4
      OTHERS            = 5.
  IF SY-SUBRC <> 0.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SET_LAYOUT_ALV1
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_LAYOUT_ALV1 .
  CLEAR GS_LAYO1.

  GS_LAYO1-GRID_TITLE = '인포레코드 자재 리스트'.
  GS_LAYO1-ZEBRA = 'X'.
  GS_LAYO1-CWIDTH_OPT = 'A'.
  GS_LAYO1-STYLEFNAME = 'GT_BTN1'.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SET_FIELDCAT_ALV1
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_FIELDCAT_ALV1 .
  CLEAR GS_FCAT1.

  GS_FCAT1-FIELDNAME = 'BPCODE'.
  GS_FCAT1-JUST = 'C'.
  GS_FCAT1-COLTEXT = '거래처 코드'.
  GS_FCAT1-KEY = 'X'.
  APPEND GS_FCAT1 TO GT_FCAT1.
  CLEAR GS_FCAT1.

  GS_FCAT1-FIELDNAME = 'BPNAME'.
  GS_FCAT1-COLTEXT = '거래처 명'.
  GS_FCAT1-JUST = 'C'.
  APPEND GS_FCAT1 TO GT_FCAT1.
  CLEAR GS_FCAT1.

  GS_FCAT1-FIELDNAME = 'MATCODE'.
  GS_FCAT1-JUST = 'C'.
  APPEND GS_FCAT1 TO GT_FCAT1.
  CLEAR GS_FCAT1.

  GS_FCAT1-FIELDNAME = 'MATNAME'.
  GS_FCAT1-JUST = 'C'.
  APPEND GS_FCAT1 TO GT_FCAT1.
  CLEAR GS_FCAT1.

  GS_FCAT1-FIELDNAME = 'INFQUANT'.
  GS_FCAT1-JUST = 'R'.
  APPEND GS_FCAT1 TO GT_FCAT1.
  CLEAR GS_FCAT1.

  GS_FCAT1-FIELDNAME = 'UNITCODE'.
  GS_FCAT1-JUST = 'L'.
  APPEND GS_FCAT1 TO GT_FCAT1.
  CLEAR GS_FCAT1.

  GS_FCAT1-FIELDNAME = 'INFPRICE'.
  GS_FCAT1-JUST = 'R'.
  APPEND GS_FCAT1 TO GT_FCAT1.
  CLEAR GS_FCAT1.

  GS_FCAT1-FIELDNAME = 'CURRENCY'.
  GS_FCAT1-JUST = 'L'.
  APPEND GS_FCAT1 TO GT_FCAT1.
  CLEAR GS_FCAT1.

  GS_FCAT1-FIELDNAME = 'ADD'.
  GS_FCAT1-JUST = 'C'.
  APPEND GS_FCAT1 TO GT_FCAT1.
  CLEAR GS_FCAT1.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SET_EVENT_ALV1
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_EVENT_ALV1 .
  SET HANDLER LCL_EVENT_HANDLER=>ON_BUTTON_CLICK FOR GO_ALV1.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form INIT_ALV1
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM INIT_ALV1 .
  DATA: LS_EXCLUD TYPE UI_FUNC,
        LT_EXCLUD TYPE UI_FUNCTIONS.

  LS_EXCLUD = CL_GUI_ALV_GRID=>MC_FC_EXCL_ALL.
  APPEND LS_EXCLUD TO LT_EXCLUD.

  CALL METHOD GO_ALV1->SET_TABLE_FOR_FIRST_DISPLAY
    EXPORTING
      I_STRUCTURE_NAME              = 'ZSBMM0010_ALV1'
*     IS_VARIANT                    =
*     I_SAVE                        =
*     I_DEFAULT                     =
      IS_LAYOUT                     = GS_LAYO1
      IT_TOOLBAR_EXCLUDING          = LT_EXCLUD
    CHANGING
      IT_OUTTAB                     = GT_DISPLAY1
      IT_FIELDCATALOG               = GT_FCAT1
*     IT_SORT                       =
*     IT_FILTER                     =
    EXCEPTIONS
      INVALID_PARAMETER_COMBINATION = 1
      PROGRAM_ERROR                 = 2
      TOO_MANY_LINES                = 3
      OTHERS                        = 4.
  IF SY-SUBRC <> 0.
    MESSAGE S205 DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form REFRESH_ALV1
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM REFRESH_ALV1 .
* ALV1 DATA 바뀔 시 최적화 및 REFRESH.
  DATA: LS_STABLE TYPE LVC_S_STBL.

  CALL METHOD GO_ALV1->GET_FRONTEND_LAYOUT
    IMPORTING
      ES_LAYOUT = GS_LAYO1.

  GS_LAYO1-CWIDTH_OPT = ABAP_ON.

  CALL METHOD GO_ALV1->SET_FRONTEND_LAYOUT
    EXPORTING
      IS_LAYOUT = GS_LAYO1.

  CALL METHOD GO_ALV1->REFRESH_TABLE_DISPLAY
    EXPORTING
      IS_STABLE = LS_STABLE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form ADD_PRMAT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM ADD_PRMAT .
  CLEAR: GS_DISPLAY2.

* 클릭한 버튼의 행의 MATCODE가 ALV2에 존재하는지 check
  READ TABLE GT_DISPLAY2 INTO GS_DISPLAY2
    WITH KEY MATCODE = GS_DISPLAY1-MATCODE.

  IF SY-SUBRC <> 0. " '추가' 버튼 누른 MATCODE가 GT_DISPLAY2 에 없으면 추가.
*         선택한 자재의 현재 재고와 적정 재고 수량 데이터 취득.
    SELECT SINGLE CURRSTOCK, SAFESTOCK
             FROM ZTBMM0030
            WHERE MATCODE EQ @GS_DISPLAY1-MATCODE
             INTO @DATA(LS_STOCK).

    IF LS_STOCK-CURRSTOCK >= LS_STOCK-SAFESTOCK * 2. " 해당 자재의 현재 수량이 적정재고 수량의 2배 이상 일때.
      MESSAGE S235 DISPLAY LIKE 'E'.
      EXIT.
    ELSE. " 해당 자재의 현재 수량이 적정재고 수량의 2배 미만 일때.

      MOVE-CORRESPONDING GS_DISPLAY1 TO GS_DISPLAY2.
      GS_DISPLAY2-PRQUANT = GS_DISPLAY1-INFQUANT.
      GS_DISPLAY2-PRPRICE = GS_DISPLAY1-INFPRICE.

      APPEND GS_DISPLAY2 TO GT_DISPLAY2.
      SORT GT_DISPLAY2 BY MATCODE ASCENDING.

      PERFORM REFRESH_ALV2.
      MESSAGE S239. " 성공적으로 추가되었습니다.
    ENDIF.

  ELSE. " '추가' 버튼 누른 MATCODE가 GT_DISPLAY2 에 있으면 수량, 금액 증가.
    LOOP AT GT_DISPLAY2 INTO GS_DISPLAY2.
      IF GS_DISPLAY2-MATCODE = GS_DISPLAY1-MATCODE. " ALV1에서 '추가' 버튼 누른 행의 MATCODE와 같은 MATCODE 행을 ALV2에서 찾음.

* 선택한 자재의 현재 재고와 적정 재고 수량 데이터 취득.
        SELECT SINGLE CURRSTOCK, SAFESTOCK
                 FROM ZTBMM0030
                WHERE MATCODE EQ @GS_DISPLAY1-MATCODE
                 INTO @LS_STOCK.

        IF LS_STOCK-CURRSTOCK >= LS_STOCK-SAFESTOCK * 2. " 해당 자재의 현재 수량이 적정재고 수량의 2배 이상 일때.
          MESSAGE S235 DISPLAY LIKE 'E'. " 해당 자재의 현 재고수량이 적정 재고수량의 2배 이상입니다.
          EXIT.
        ELSE. " 해당 자재의 현재 수량이 적정재고 수량의 2배 미만 일때.

          IF LS_STOCK-CURRSTOCK + GS_DISPLAY2-PRQUANT >= LS_STOCK-SAFESTOCK * 2. " 현재 수량 + 구매 예정 수량 >= 적정재고 수량일때.
            MESSAGE S236 DISPLAY LIKE 'E'. " 적정재고수량과 비교하여 구매요청 수량이 너무 많습니다.

          ELSE. " 현재 수량 + 구매 예정 수량 < 적정재고 수량일때.

            GS_DISPLAY2-PRQUANT = GS_DISPLAY2-PRQUANT + GS_DISPLAY1-INFQUANT.
            GS_DISPLAY2-PRPRICE = GS_DISPLAY2-PRPRICE + GS_DISPLAY1-INFPRICE.

            MODIFY GT_DISPLAY2 FROM GS_DISPLAY2 INDEX SY-TABIX.

            PERFORM REFRESH_ALV2.
            MESSAGE S239. " 성공적으로 추가되었습니다.
            EXIT.

          ENDIF.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form CREATE_OBJECT_2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CREATE_OBJECT_2 .
  CREATE OBJECT GO_CUST2
    EXPORTING
      CONTAINER_NAME              = 'CUST2'
    EXCEPTIONS
      CNTL_ERROR                  = 1
      CNTL_SYSTEM_ERROR           = 2
      CREATE_ERROR                = 3
      LIFETIME_ERROR              = 4
      LIFETIME_DYNPRO_DYNPRO_LINK = 5
      OTHERS                      = 6.
  IF SY-SUBRC <> 0.
  ENDIF.

  CREATE OBJECT GO_ALV2
    EXPORTING
      I_PARENT          = GO_CUST2
    EXCEPTIONS
      ERROR_CNTL_CREATE = 1
      ERROR_CNTL_INIT   = 2
      ERROR_CNTL_LINK   = 3
      ERROR_DP_CREATE   = 4
      OTHERS            = 5.
  IF SY-SUBRC <> 0.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SET_LAYOUT_ALV2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_LAYOUT_ALV2 .
  CLEAR GS_LAYO2.

  GS_LAYO2-GRID_TITLE = '구매요청 자재 리스트'.
  GS_LAYO2-ZEBRA = 'X'.
  GS_LAYO2-CWIDTH_OPT = 'A'.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SET_FIELDCAT_ALV2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_FIELDCAT_ALV2 .
  CLEAR GS_FCAT2.

  GS_FCAT2-FIELDNAME = 'BPCODE'.
  GS_FCAT2-JUST = 'C'.
  GS_FCAT2-COLTEXT = '거래처 코드'.
  GS_FCAT2-KEY = 'X'.
  APPEND GS_FCAT2 TO GT_FCAT2.
  CLEAR GS_FCAT2.

  GS_FCAT2-FIELDNAME = 'BPNAME'.
  GS_FCAT2-JUST = 'C'.
  GS_FCAT2-COLTEXT = '거래처 명'.
  APPEND GS_FCAT2 TO GT_FCAT2.
  CLEAR GS_FCAT2.

  GS_FCAT2-FIELDNAME = 'MATCODE'.
  GS_FCAT2-JUST = 'C'.
  APPEND GS_FCAT2 TO GT_FCAT2.
  CLEAR GS_FCAT2.

  GS_FCAT2-FIELDNAME = 'MATNAME'.
  GS_FCAT2-JUST = 'C'.
  APPEND GS_FCAT2 TO GT_FCAT2.
  CLEAR GS_FCAT2.

  GS_FCAT2-FIELDNAME = 'PRQUANT'.
  GS_FCAT2-JUST = 'R'.
  APPEND GS_FCAT2 TO GT_FCAT2.
  CLEAR GS_FCAT2.

  GS_FCAT2-FIELDNAME = 'UNITCODE'.
  GS_FCAT2-JUST = 'L'.
  APPEND GS_FCAT2 TO GT_FCAT2.
  CLEAR GS_FCAT2.

  GS_FCAT2-FIELDNAME = 'PRPRICE'.
  GS_FCAT2-JUST = 'R'.
  APPEND GS_FCAT2 TO GT_FCAT2.
  CLEAR GS_FCAT2.

  GS_FCAT2-FIELDNAME = 'CURRENCY'.
  GS_FCAT2-JUST = 'L'.
  APPEND GS_FCAT2 TO GT_FCAT2.
  CLEAR GS_FCAT2.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SET_EVENT_ALV2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_EVENT_ALV2 .
  SET HANDLER LCL_EVENT_HANDLER=>ON_TOOLBAR2 FOR GO_ALV2.
  SET HANDLER LCL_EVENT_HANDLER=>ON_USER_COMMAND2 FOR GO_ALV2.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form INIT_ALV2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM INIT_ALV2 .
* DIALOG ALV DISPLAY.
  GS_VARIANT-REPORT = SY-CPROG.
  GS_VARIANT-VARIANT = '/ZALV2'.

  CALL METHOD GO_ALV2->SET_TABLE_FOR_FIRST_DISPLAY
    EXPORTING
      I_STRUCTURE_NAME              = 'ZSBMM0010_ALV2'
      IS_VARIANT                    = GS_VARIANT
      I_SAVE                        = 'A'
*     I_DEFAULT                     = 'X'
      IS_LAYOUT                     = GS_LAYO2
*     IT_TOOLBAR_EXCLUDING          = LT_EXCLUD
    CHANGING
      IT_OUTTAB                     = GT_DISPLAY2
      IT_FIELDCATALOG               = GT_FCAT2
      IT_SORT                       = GT_SORT2
*     IT_FILTER                     =
    EXCEPTIONS
      INVALID_PARAMETER_COMBINATION = 1
      PROGRAM_ERROR                 = 2
      TOO_MANY_LINES                = 3
      OTHERS                        = 4.
  IF SY-SUBRC <> 0.
    MESSAGE S205 DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form REFRESH_ALV2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM REFRESH_ALV2 .
  DATA: LS_STABLE TYPE LVC_S_STBL.

  CALL METHOD GO_ALV2->GET_FRONTEND_LAYOUT
    IMPORTING
      ES_LAYOUT = GS_LAYO2.


  GS_LAYO2-CWIDTH_OPT = ABAP_ON.

  CALL METHOD GO_ALV2->SET_FRONTEND_LAYOUT
    EXPORTING
      IS_LAYOUT = GS_LAYO2.

  CALL METHOD GO_ALV2->REFRESH_TABLE_DISPLAY
    EXPORTING
      IS_STABLE = LS_STABLE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form DEL_PRMAT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM DEL_PRMAT .
  CLEAR: GS_DISPLAY2.

  READ TABLE GT_DISPLAY2 INTO GS_DISPLAY2
  WITH KEY MATCODE = GS_DISPLAY1-MATCODE.

  IF SY-SUBRC <> 0. " '차감' 버튼 누른 MATCODE가 GT_DISPLAY2 에 없을 때.
    MESSAGE S233 DISPLAY LIKE 'E'. " 해당 자재는 구매요청 자재 리스트에 없습니다.

  ELSE. " '차감' 버튼 누른 MATCODE가 GT_DISPLAY2 에 있을 때.

    IF GS_DISPLAY2-PRQUANT LE GS_DISPLAY1-INFQUANT. " 구매요청 예정 리스트의 수량값이 구매단위수량 값 이하 일때.
      MESSAGE S234 DISPLAY LIKE 'E'. " 더 이상 차감할 수 없습니다.

    ELSE. " 구매요청 예정 리스트의 수량값이 구매단위수량 값 초과 일때.
      LOOP AT GT_DISPLAY2 INTO GS_DISPLAY2.
        IF GS_DISPLAY2-MATCODE = GS_DISPLAY1-MATCODE.

          GS_DISPLAY2-PRQUANT = GS_DISPLAY2-PRQUANT - GS_DISPLAY1-INFQUANT.
          GS_DISPLAY2-PRPRICE = GS_DISPLAY2-PRPRICE - GS_DISPLAY1-INFPRICE.

          MODIFY GT_DISPLAY2 FROM GS_DISPLAY2 INDEX SY-TABIX.
          PERFORM REFRESH_ALV2.
          MESSAGE S240. " 성공적으로 차감되었습니다.
          EXIT.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form HANDLE_TOOLBAR2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> E_OBJECT
*&---------------------------------------------------------------------*
FORM HANDLE_TOOLBAR2  USING    PV_OBJECT TYPE REF TO CL_ALV_EVENT_TOOLBAR_SET.
  DATA LS_BUTTON LIKE LINE OF PV_OBJECT->MT_TOOLBAR.

* 구분자 추가.
  CLEAR LS_BUTTON.
  LS_BUTTON-BUTN_TYPE = 3.
  APPEND LS_BUTTON TO PV_OBJECT->MT_TOOLBAR.
  CLEAR LS_BUTTON.

* 버튼 'DEL' 추가.
  LS_BUTTON-BUTN_TYPE = 0. " 일반 버튼(NORMAL BUTTON)
  LS_BUTTON-TEXT      = ' 삭제 '.
  LS_BUTTON-FUNCTION  = 'DEL'.
  APPEND LS_BUTTON TO PV_OBJECT->MT_TOOLBAR.
  CLEAR LS_BUTTON.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form HANDLE_USER_COMMAND2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> E_UCOMM
*&---------------------------------------------------------------------*
FORM HANDLE_USER_COMMAND2  USING PV_UCOMM.
  CASE PV_UCOMM.
    WHEN 'DEL'.
      PERFORM DELETE_PRMAT. " ALV2의 toolbar button '삭제'를 눌렀을 때.
  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form DELETE_PRMAT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM DELETE_PRMAT .
  DATA : LV_ANSWER.

  CLEAR: GT_ROW2, GS_ROW2, GS_DISPLAY2.

  CALL METHOD GO_ALV2->GET_SELECTED_ROWS
    IMPORTING
      ET_ROW_NO = GT_ROW2.

* 선택한 행 정보.
  READ TABLE GT_ROW2 INTO GS_ROW2 INDEX 1.
  READ TABLE GT_DISPLAY2 INTO GS_DISPLAY2 INDEX GS_ROW2-ROW_ID.

  IF GS_DISPLAY2 IS INITIAL. " 데이터 선택안하고 눌렀을 때.
    MESSAGE S242 DISPLAY LIKE 'E'. " 자재 데이터를 선택해주세요.

  ELSE. " 데이터를 선택하고 눌렀을 때.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        TITLEBAR              = TEXT-T02 " 구매요청 리스트 삭제 확인.
        TEXT_QUESTION         = TEXT-Q02 " 선택한 자재를 구매요청 리스트에서 삭제하시겠습니까?
        TEXT_BUTTON_1         = 'YES'
        ICON_BUTTON_1         = 'ICON_OKAY'
        TEXT_BUTTON_2         = 'NO'
        ICON_BUTTON_2         = 'ICON_CANCEL'
        DEFAULT_BUTTON        = '1'
        DISPLAY_CANCEL_BUTTON = ''
      IMPORTING
        ANSWER                = LV_ANSWER.

    IF LV_ANSWER = '1'. " 컨펌 팝업에서 YES 눌렀을 때.
      DELETE GT_DISPLAY2 INDEX GS_ROW2-ROW_ID. " 선택한 행 삭제.

      CALL METHOD CL_GUI_CFW=>SET_NEW_OK_CODE " 삭제 후 PAI-PBO 동작해서 ALV2 REFRESH.
        EXPORTING
          NEW_CODE = 'ENTER'.

      MESSAGE S244. " 자재 삭제를 성공하였습니다.
    ELSE. " 컨펌 팝업에서 NO 눌렀을 때.
      MESSAGE S243. " 자재 삭제를 취소하였습니다.
    ENDIF.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form CREATE_PR
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CREATE_PR .
  DATA: LV_PRNR TYPE NUM8.

  DATA: LV_ANSWER TYPE NUM1.

  DATA: LS_ZTBMM0010 TYPE ZTBMM0010,
        LS_ZTBMM0011 TYPE ZTBMM0011.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      TITLEBAR              = TEXT-T04 " 구매요청 생성 확인.
      TEXT_QUESTION         = TEXT-Q04 " 구매요청을 생성하시겠습니까?
      TEXT_BUTTON_1         = 'YES'
      ICON_BUTTON_1         = 'ICON_OKAY'
      TEXT_BUTTON_2         = 'NO'
      ICON_BUTTON_2         = 'ICON_CANCEL'
      DEFAULT_BUTTON        = '1'
      DISPLAY_CANCEL_BUTTON = ''
    IMPORTING
      ANSWER                = LV_ANSWER.

  IF LV_ANSWER = '1'. "CONFIRM POPUP - YES

    MOVE-CORRESPONDING GT_DISPLAY2 TO GT_ZSBMM0010_PR.

    CALL FUNCTION 'NUMBER_GET_NEXT'
      EXPORTING
        NR_RANGE_NR             = '01'
        OBJECT                  = 'ZBBMM0010'
      IMPORTING
        NUMBER                  = LV_PRNR
      EXCEPTIONS
        INTERVAL_NOT_FOUND      = 1
        NUMBER_RANGE_NOT_INTERN = 2
        OBJECT_NOT_FOUND        = 3
        QUANTITY_IS_0           = 4
        QUANTITY_IS_NOT_1       = 5
        INTERVAL_OVERFLOW       = 6
        BUFFER_OVERFLOW         = 7
        OTHERS                  = 8.
    IF SY-SUBRC <> 0.
    ENDIF.

    LOOP AT GT_ZSBMM0010_PR INTO GS_ZSBMM0010_PR.

      SELECT SINGLE EMPID
        FROM ZTBSD1030
       WHERE LOGID = @SY-UNAME
        INTO @DATA(LV_EMPID).

      GS_ZSBMM0010_PR-PLTCODE = 'PLT0000001'.
      GS_ZSBMM0010_PR-WHCODE = 'STP0000001'.
      GS_ZSBMM0010_PR-PRDATE = SY-DATUM.
      GS_ZSBMM0010_PR-EMPID = LV_EMPID.
      GS_ZSBMM0010_PR-STATUS = 'X'.

      CONCATENATE 'PR' LV_PRNR INTO GS_ZSBMM0010_PR-PRNUM. " 구매요청 번호 채번.

      MODIFY GT_ZSBMM0010_PR FROM GS_ZSBMM0010_PR.
    ENDLOOP.

* 헤더 WA 데이터 할당.
    MOVE-CORRESPONDING GS_ZSBMM0010_PR TO LS_ZTBMM0010.
    INSERT ZTBMM0010 FROM LS_ZTBMM0010.

* 행을 차례로 읽으면서 아이템 WA 데이터 할당하고, TP TABLE CREATE.
    LOOP AT GT_ZSBMM0010_PR INTO GS_ZSBMM0010_PR.
      MOVE-CORRESPONDING GS_ZSBMM0010_PR TO LS_ZTBMM0011.
      INSERT ZTBMM0011 FROM LS_ZTBMM0011.
    ENDLOOP.

    IF SY-SUBRC = 0. " 구매요청 생성 완료.
      MESSAGE S245 WITH GS_ZSBMM0010_PR-PRNUM.
      CLEAR GT_DISPLAY4.
      PERFORM SET_DATA_ALV4. " ALV4 ITAB에 데이터 할당.

      CLEAR GT_DISPLAY2.
      PERFORM REFRESH_ALV2.

      LEAVE TO SCREEN 0.

      STOP.
    ELSE. " 구매요청 생성 실패.
      MESSAGE S246.
      LEAVE TO SCREEN 0.
    ENDIF.

  ELSE. " CONFIRM POPUP - NO
    MESSAGE S247.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form CREATE_OBJECT_3
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CREATE_OBJECT_3 .
  CREATE OBJECT GO_CUST3
    EXPORTING
      CONTAINER_NAME              = 'CUST3'
    EXCEPTIONS
      CNTL_ERROR                  = 1
      CNTL_SYSTEM_ERROR           = 2
      CREATE_ERROR                = 3
      LIFETIME_ERROR              = 4
      LIFETIME_DYNPRO_DYNPRO_LINK = 5
      OTHERS                      = 6.
  IF SY-SUBRC <> 0.
  ENDIF.

  CREATE OBJECT GO_ALV3
    EXPORTING
      I_PARENT          = GO_CUST3
    EXCEPTIONS
      ERROR_CNTL_CREATE = 1
      ERROR_CNTL_INIT   = 2
      ERROR_CNTL_LINK   = 3
      ERROR_DP_CREATE   = 4
      OTHERS            = 5.
  IF SY-SUBRC <> 0.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SET_LAYOUT_ALV3
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_LAYOUT_ALV3 .
  CLEAR GS_LAYO3.

  GS_LAYO3-GRID_TITLE = '구매요청 생성 자재 리스트'.
  GS_LAYO3-ZEBRA = 'X'.
  GS_LAYO3-CWIDTH_OPT = 'A'.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SET_FIELDCAT_ALV3
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_FIELDCAT_ALV3 .
  CLEAR GS_FCAT3.

  GS_FCAT3-FIELDNAME = 'PRNUM'.
  GS_FCAT3-JUST = 'C'.
  GS_FCAT3-NO_OUT = 'X'.
  APPEND GS_FCAT3 TO GT_FCAT3.
  CLEAR GS_FCAT3.

  GS_FCAT3-FIELDNAME = 'BPCODE'.
  GS_FCAT3-JUST = 'C'.
  GS_FCAT3-NO_OUT = 'X'.
  APPEND GS_FCAT3 TO GT_FCAT3.
  CLEAR GS_FCAT3.

  GS_FCAT3-FIELDNAME = 'BPNAME'.
  GS_FCAT3-JUST = 'C'.
  GS_FCAT3-NO_OUT = 'X'.
  APPEND GS_FCAT3 TO GT_FCAT3.
  CLEAR GS_FCAT3.

  GS_FCAT3-FIELDNAME = 'PLTCODE'.
  GS_FCAT3-JUST = 'C'.
  GS_FCAT3-NO_OUT = 'X'.
  APPEND GS_FCAT3 TO GT_FCAT3.
  CLEAR GS_FCAT3.

  GS_FCAT3-FIELDNAME = 'PLTNAME'.
  GS_FCAT3-JUST = 'C'.
  GS_FCAT3-NO_OUT = 'X'.
  APPEND GS_FCAT3 TO GT_FCAT3.
  CLEAR GS_FCAT3.

  GS_FCAT3-FIELDNAME = 'WHCODE'.
  GS_FCAT3-JUST = 'C'.
  GS_FCAT3-NO_OUT = 'X'.
  APPEND GS_FCAT3 TO GT_FCAT3.
  CLEAR GS_FCAT3.

  GS_FCAT3-FIELDNAME = 'WHNAME'.
  GS_FCAT3-JUST = 'C'.
  GS_FCAT3-NO_OUT = 'X'.
  APPEND GS_FCAT3 TO GT_FCAT3.
  CLEAR GS_FCAT3.

  GS_FCAT3-FIELDNAME = 'PRDATE'.
  GS_FCAT3-JUST = 'C'.
  GS_FCAT3-NO_OUT = 'X'.
  APPEND GS_FCAT3 TO GT_FCAT3.
  CLEAR GS_FCAT3.

  GS_FCAT3-FIELDNAME = 'MATCODE'.
  GS_FCAT3-JUST = 'C'.
  GS_FCAT3-KEY = 'X'.
  APPEND GS_FCAT3 TO GT_FCAT3.
  CLEAR GS_FCAT3.

  GS_FCAT3-FIELDNAME = 'MATNAME'.
  GS_FCAT3-JUST = 'C'.
  APPEND GS_FCAT3 TO GT_FCAT3.
  CLEAR GS_FCAT3.

  GS_FCAT3-FIELDNAME = 'PRQUANT'.
  GS_FCAT3-JUST = 'R'.
  APPEND GS_FCAT3 TO GT_FCAT3.
  CLEAR GS_FCAT3.

  GS_FCAT3-FIELDNAME = 'UNITCODE'.
  GS_FCAT3-JUST = 'L'.
  APPEND GS_FCAT3 TO GT_FCAT3.
  CLEAR GS_FCAT3.

  GS_FCAT3-FIELDNAME = 'PRPRICE'.
  GS_FCAT3-JUST = 'R'.
  APPEND GS_FCAT3 TO GT_FCAT3.
  CLEAR GS_FCAT3.

  GS_FCAT3-FIELDNAME = 'CURRENCY'.
  GS_FCAT3-JUST = 'L'.
  APPEND GS_FCAT3 TO GT_FCAT3.
  CLEAR GS_FCAT3.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form INIT_ALV3
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM INIT_ALV3 .
  " DIALOG ALV DISPLAY.
  GS_VARIANT-REPORT = SY-CPROG.
  GS_VARIANT-VARIANT = '/ZALV3'.

  CALL METHOD GO_ALV3->SET_TABLE_FOR_FIRST_DISPLAY
    EXPORTING
      I_STRUCTURE_NAME              = 'ZSBMM0010_ALV3'
      IS_VARIANT                    = GS_VARIANT
      I_SAVE                        = 'A'
*     I_DEFAULT                     = 'X'
      IS_LAYOUT                     = GS_LAYO3
*     IT_TOOLBAR_EXCLUDING          = LT_EXCLUD
    CHANGING
      IT_OUTTAB                     = GT_DISPLAY3
      IT_FIELDCATALOG               = GT_FCAT3
*     IT_SORT                       = GT_SORT3
*     IT_FILTER                     =
    EXCEPTIONS
      INVALID_PARAMETER_COMBINATION = 1
      PROGRAM_ERROR                 = 2
      TOO_MANY_LINES                = 3
      OTHERS                        = 4.
  IF SY-SUBRC <> 0.
    MESSAGE S205 DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form REFRESH_ALV3
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM REFRESH_ALV3 .
  DATA: LS_STABLE TYPE LVC_S_STBL.

  CALL METHOD GO_ALV3->GET_FRONTEND_LAYOUT
    IMPORTING
      ES_LAYOUT = GS_LAYO3.

  GS_LAYO3-CWIDTH_OPT = ABAP_ON.

  CALL METHOD GO_ALV3->SET_FRONTEND_LAYOUT
    EXPORTING
      IS_LAYOUT = GS_LAYO3.

  CALL METHOD GO_ALV3->REFRESH_TABLE_DISPLAY
    EXPORTING
      IS_STABLE = LS_STABLE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SET_DATA_ALV3
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_DATA_ALV3 .
  MOVE-CORRESPONDING GT_DISPLAY2 TO GT_DISPLAY3.

  READ TABLE GT_DISPLAY2 INTO GS_DISPLAY2 INDEX 1.

  MOVE-CORRESPONDING GS_DISPLAY2 TO ZSBMM0010_ALV3.
  ZSBMM0010_ALV3-PLTCODE = 'PLT0000001'.
  ZSBMM0010_ALV3-PLTNAME = '이천 플랜트'.
  ZSBMM0010_ALV3-WHCODE = 'STP0000001'.
  ZSBMM0010_ALV3-WHNAME = '이천 구매자재 창고'.
  ZSBMM0010_ALV3-PRDATE = SY-DATUM.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form CHECK_DISPLAY2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CHECK_DISPLAY2 .
  DATA : LV_ANSWER.

  IF GT_DISPLAY2 IS INITIAL. " ALV2에 데이터 없을 때.
    MESSAGE S248 DISPLAY LIKE 'E'.

  ELSE. " ALV2에 데이터 존재할 때.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        TITLEBAR              = TEXT-T03 " 구매요청 진행 확인.
        TEXT_QUESTION         = TEXT-Q03 " 구매요청을 진행하시겠습니까?
        TEXT_BUTTON_1         = 'YES'
        ICON_BUTTON_1         = 'ICON_OKAY'
        TEXT_BUTTON_2         = 'NO'
        ICON_BUTTON_2         = 'ICON_CANCEL'
        DEFAULT_BUTTON        = '1'
        DISPLAY_CANCEL_BUTTON = ''
      IMPORTING
        ANSWER                = LV_ANSWER.

    IF LV_ANSWER = '1'. " CONFIRM POPUP - YES
      MESSAGE S249. " 구매요청 생성을 확인해주세요.
      CALL SCREEN 130
        STARTING AT 10 7.
    ELSE. " CONFIRM POPUP - NO
      MESSAGE S247.
    ENDIF.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form CREATE_OBJECT_4
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CREATE_OBJECT_4 .
  CREATE OBJECT GO_CUST4
    EXPORTING
      CONTAINER_NAME              = 'CUST4'
    EXCEPTIONS
      CNTL_ERROR                  = 1
      CNTL_SYSTEM_ERROR           = 2
      CREATE_ERROR                = 3
      LIFETIME_ERROR              = 4
      LIFETIME_DYNPRO_DYNPRO_LINK = 5
      OTHERS                      = 6.
  IF SY-SUBRC <> 0.
  ENDIF.

  CREATE OBJECT GO_ALV4
    EXPORTING
      I_PARENT          = GO_CUST4
    EXCEPTIONS
      ERROR_CNTL_CREATE = 1
      ERROR_CNTL_INIT   = 2
      ERROR_CNTL_LINK   = 3
      ERROR_DP_CREATE   = 4
      OTHERS            = 5.
  IF SY-SUBRC <> 0.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SET_LAYOUT_ALV4
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_LAYOUT_ALV4 .
  CLEAR GS_LAYO4.

  GS_LAYO4-GRID_TITLE = '구매요청 생성 완료 리스트'.
  GS_LAYO4-ZEBRA = 'X'.
  GS_LAYO4-CWIDTH_OPT = 'A'.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SET_FIELDCAT_ALV4
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_FIELDCAT_ALV4 .
  CLEAR GS_FCAT4.

  GS_FCAT4-FIELDNAME = 'PRNUM'.
  GS_FCAT4-JUST = 'C'.
  GS_FCAT4-COLTEXT = '구매요청번호'.
  GS_FCAT4-KEY = 'X'.
  APPEND GS_FCAT4 TO GT_FCAT4.
  CLEAR GS_FCAT4.

  GS_FCAT4-FIELDNAME = 'BPCODE'.
  GS_FCAT4-JUST = 'C'.
  GS_FCAT4-COLTEXT = '거래처 코드'.
  APPEND GS_FCAT4 TO GT_FCAT4.
  CLEAR GS_FCAT4.

  GS_FCAT4-FIELDNAME = 'BPNAME'.
  GS_FCAT4-JUST = 'C'.
  GS_FCAT4-COLTEXT = '거래처 명'.
  APPEND GS_FCAT4 TO GT_FCAT4.
  CLEAR GS_FCAT4.

  GS_FCAT4-FIELDNAME = 'PLTCODE'.
  GS_FCAT4-JUST = 'C'.
  GS_FCAT4-COLTEXT = '플랜트 코드'.
  APPEND GS_FCAT4 TO GT_FCAT4.
  CLEAR GS_FCAT4.

  GS_FCAT4-FIELDNAME = 'PLTNAME'.
  GS_FCAT4-JUST = 'C'.
  GS_FCAT4-COLTEXT = '플랜트 명'.
  APPEND GS_FCAT4 TO GT_FCAT4.
  CLEAR GS_FCAT4.

  GS_FCAT4-FIELDNAME = 'WHCODE'.
  GS_FCAT4-JUST = 'C'.
  GS_FCAT4-COLTEXT = '창고 코드'.
  APPEND GS_FCAT4 TO GT_FCAT4.
  CLEAR GS_FCAT4.

  GS_FCAT4-FIELDNAME = 'WHNAME'.
  GS_FCAT4-JUST = 'C'.
  GS_FCAT4-COLTEXT = '창고 명'.
  APPEND GS_FCAT4 TO GT_FCAT4.
  CLEAR GS_FCAT4.

  GS_FCAT4-FIELDNAME = 'PRDATE'.
  GS_FCAT4-JUST = 'C'.
  GS_FCAT4-COLTEXT = '구매요청 생성일'.
  APPEND GS_FCAT4 TO GT_FCAT4.
  CLEAR GS_FCAT4.

  GS_FCAT4-FIELDNAME = 'MATCODE'.
  GS_FCAT4-JUST = 'C'.
  GS_FCAT4-COLTEXT = '자재 번호'.
  APPEND GS_FCAT4 TO GT_FCAT4.
  CLEAR GS_FCAT4.

  GS_FCAT4-FIELDNAME = 'MATNAME'.
  GS_FCAT4-JUST = 'C'.
  GS_FCAT4-COLTEXT = '자재 이름'.
  APPEND GS_FCAT4 TO GT_FCAT4.
  CLEAR GS_FCAT4.

  GS_FCAT4-FIELDNAME = 'PRQUANT'.
  GS_FCAT4-JUST = 'R'.
  GS_FCAT4-COLTEXT = '구매요청수량'.
  APPEND GS_FCAT4 TO GT_FCAT4.
  CLEAR GS_FCAT4.

  GS_FCAT4-FIELDNAME = 'UNITCODE'.
  GS_FCAT4-JUST = 'L'.
  GS_FCAT4-COLTEXT = '단위'.
  APPEND GS_FCAT4 TO GT_FCAT4.
  CLEAR GS_FCAT4.

  GS_FCAT4-FIELDNAME = 'PRPRICE'.
  GS_FCAT4-JUST = 'R'.
  GS_FCAT4-COLTEXT = '구매요청금액'.
  APPEND GS_FCAT4 TO GT_FCAT4.
  CLEAR GS_FCAT4.

  GS_FCAT4-FIELDNAME = 'CURRENCY'.
  GS_FCAT4-JUST = 'L'.
  GS_FCAT4-COLTEXT = '단위'.
  APPEND GS_FCAT4 TO GT_FCAT4.
  CLEAR GS_FCAT4.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form INIT_ALV4
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM INIT_ALV4 .
* DIALOG ALV DISPLAY.
  GS_VARIANT-REPORT = SY-CPROG.
  GS_VARIANT-VARIANT = '/ZALV4'.

  CALL METHOD GO_ALV4->SET_TABLE_FOR_FIRST_DISPLAY
    EXPORTING
      I_STRUCTURE_NAME              = 'ZSBMM0010_ALV3'
      IS_VARIANT                    = GS_VARIANT
      I_SAVE                        = 'A'
*     I_DEFAULT                     = 'X'
      IS_LAYOUT                     = GS_LAYO4
*     IT_TOOLBAR_EXCLUDING          = LT_EXCLUD
    CHANGING
      IT_OUTTAB                     = GT_DISPLAY4
      IT_FIELDCATALOG               = GT_FCAT4
*     IT_SORT                       = GT_SORT2
*     IT_FILTER                     =
    EXCEPTIONS
      INVALID_PARAMETER_COMBINATION = 1
      PROGRAM_ERROR                 = 2
      TOO_MANY_LINES                = 3
      OTHERS                        = 4.
  IF SY-SUBRC <> 0.
    MESSAGE S205 DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form REFRESH_ALV4
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM REFRESH_ALV4 .
  DATA: LS_STABLE TYPE LVC_S_STBL.

  CALL METHOD GO_ALV4->GET_FRONTEND_LAYOUT
    IMPORTING
      ES_LAYOUT = GS_LAYO4.

  GS_LAYO4-CWIDTH_OPT = ABAP_ON.

  CALL METHOD GO_ALV4->SET_FRONTEND_LAYOUT
    EXPORTING
      IS_LAYOUT = GS_LAYO4.

  CALL METHOD GO_ALV4->REFRESH_TABLE_DISPLAY
    EXPORTING
      IS_STABLE = LS_STABLE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SET_DATA_ALV4
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_DATA_ALV4 .
  MOVE-CORRESPONDING GT_ZSBMM0010_PR TO GT_DISPLAY4.

  LOOP AT GT_DISPLAY4 INTO GS_DISPLAY4.
    SELECT SINGLE BPNAME
      FROM ZTBSD1051
     WHERE BPCODE EQ @GS_DISPLAY4-BPCODE
      INTO @GS_DISPLAY4-BPNAME.

    SELECT SINGLE PLTNAME
      FROM ZTBMM1020
     WHERE PLTCODE EQ @GS_DISPLAY4-PLTCODE
      INTO @GS_DISPLAY4-PLTNAME.

    SELECT SINGLE WHNAME
      FROM ZTBMM1030
     WHERE WHCODE EQ @GS_DISPLAY4-WHCODE
      INTO @GS_DISPLAY4-WHNAME.

    SELECT SINGLE MATNAME
      FROM ZTBMM1011
     WHERE MATCODE EQ @GS_DISPLAY4-MATCODE
      INTO @GS_DISPLAY4-MATNAME.

    IF SY-SUBRC = 0.
      MODIFY GT_DISPLAY4 FROM GS_DISPLAY4.
    ENDIF.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form GET_DATA_ALV5
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM GET_DATA_ALV5 .
  DATA: RT_MATCODE TYPE RANGE OF ZSBMM0010_ALV5-MATCODE,
        RS_MATCODE LIKE LINE OF RT_MATCODE.

  DATA: LS_SCOL TYPE LVC_S_SCOL.

  DATA: LV_MATNAME TYPE STRING.

  CLEAR: RS_MATCODE, RT_MATCODE, LV_MATNAME.

  LV_MATNAME = '%' && ZSBMM0010_ALV5-MATNAME && '%'.

* SELECT-OPTION TABLE 생성.
  IF ZSBMM0010_ALV5-MATCODE IS NOT INITIAL. " LOW값 입력했을 때.
    IF ZSBMM0010_ALV5-MATCODE2 IS NOT INITIAL. "HIGH값도 입력했을 때.
      RS_MATCODE-SIGN = 'I'.
      RS_MATCODE-OPTION = 'BT'.
      RS_MATCODE-LOW = ZSBMM0010_ALV5-MATCODE.
      RS_MATCODE-HIGH = ZSBMM0010_ALV5-MATCODE2.
      APPEND RS_MATCODE TO RT_MATCODE.
      CLEAR RS_MATCODE.
    ELSE. " HIGH 값은 입력안했을 때.
      RS_MATCODE-SIGN = 'I'.
      RS_MATCODE-OPTION = 'GE'.
      RS_MATCODE-LOW = ZSBMM0010_ALV5-MATCODE.
      APPEND RS_MATCODE TO RT_MATCODE.
      CLEAR RS_MATCODE.
    ENDIF.

  ELSE. " LOW값 입력안했을 때.
    IF ZSBMM0010_ALV5-MATCODE2 IS NOT INITIAL. "HIGH값 입력했을 때.
      RS_MATCODE-SIGN = 'I'.
      RS_MATCODE-OPTION = 'LE'.
      RS_MATCODE-LOW = ZSBMM0010_ALV5-MATCODE2.
      APPEND RS_MATCODE TO RT_MATCODE.
      CLEAR RS_MATCODE.
    ELSE. " LOW, HIGH값 모두 입력안했을 때.
    ENDIF.
  ENDIF.

* 구매자재에 해당하는 자재들 SELECT.
  SELECT *
    FROM ZCDS_MAT
   WHERE MATCODE IN @RT_MATCODE
     AND MATNAME LIKE @LV_MATNAME
     AND SPRAS EQ @SY-LANGU
     AND DELFLG EQ @SPACE
     AND MATTYPE EQ 'M' " 자재유형 = 구매자재
    ORDER BY MATCODE ASCENDING
    INTO CORRESPONDING FIELDS OF TABLE @GT_DISPLAY5.

  IF SY-SUBRC = 0. " 조회조건에 해당하는 자재가 있을 때.
* LOOP문으로 나머지 FIELD들 DATA 할당.
    LOOP AT GT_DISPLAY5 INTO GS_DISPLAY5.

* 구매자재를 보관하는 플랜트와 창고가 각각 1개뿐이기 때문에 직접 값 할당.
      GS_DISPLAY5-PLTCODE = 'PLT0000001'.
      GS_DISPLAY5-PLTNAME = '이천 플랜트'.
      GS_DISPLAY5-WHCODE = 'STP0000001'.
      GS_DISPLAY5-WHNAME = '이천 구매자재 창고'.

      SELECT SINGLE CURRSTOCK, SAFESTOCK, UNITCODE1, UNITCODE2
        FROM ZTBMM0030
       WHERE MATCODE EQ @GS_DISPLAY5-MATCODE
        INTO (@GS_DISPLAY5-CURRSTOCK, @GS_DISPLAY5-SAFESTOCK, @GS_DISPLAY5-UNITCODE1, @GS_DISPLAY5-UNITCODE2).

      IF SY-SUBRC = 0.
*      현재고와 적정재고수량 비교해서 LED 표시.
        IF GS_DISPLAY5-CURRSTOCK < GS_DISPLAY5-SAFESTOCK. " 현재고가 적정재고수량보다 100% 미만일 때.
          GS_DISPLAY5-EXCP = '1'. " 상태 빨간색
        ELSE. " 현재고가 적정재고수량보다 100% 이상일 때.
          GS_DISPLAY5-EXCP = '3'. " 상태 초록색
        ENDIF.

* Column 에 색깔 표시.
        LS_SCOL-FNAME = 'CURRSTOCK'.
        LS_SCOL-COLOR-COL = '3'.
        LS_SCOL-COLOR-INT = '0'.
        LS_SCOL-COLOR-INV = '0'.
        APPEND LS_SCOL TO GS_DISPLAY5-IT_COL.
        CLEAR LS_SCOL.

        LS_SCOL-FNAME = 'SAFESTOCK'.
        LS_SCOL-COLOR-COL = '5'.
        LS_SCOL-COLOR-INT = '0'.
        LS_SCOL-COLOR-INV = '0'.
        APPEND LS_SCOL TO GS_DISPLAY5-IT_COL.
        CLEAR LS_SCOL.

        MODIFY GT_DISPLAY5 FROM GS_DISPLAY5.
        CLEAR GS_DISPLAY5.
      ENDIF.
    ENDLOOP.

    MESSAGE S241. " 성공적으로 조회되었습니다.

  ELSE. "조회조건에 해당하는 자재가 없을 때.
    MESSAGE S210 DISPLAY LIKE 'E'. " 조회조건에 해당하는 데이터가 없습니다.
    RETURN.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form CREATE_OBJECT_5
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CREATE_OBJECT_5 .
  CREATE OBJECT GO_CUST5
    EXPORTING
      CONTAINER_NAME              = 'CUST5'
    EXCEPTIONS
      CNTL_ERROR                  = 1
      CNTL_SYSTEM_ERROR           = 2
      CREATE_ERROR                = 3
      LIFETIME_ERROR              = 4
      LIFETIME_DYNPRO_DYNPRO_LINK = 5
      OTHERS                      = 6.
  IF SY-SUBRC <> 0.
  ENDIF.

  CREATE OBJECT GO_ALV5
    EXPORTING
      I_PARENT          = GO_CUST5
    EXCEPTIONS
      ERROR_CNTL_CREATE = 1
      ERROR_CNTL_INIT   = 2
      ERROR_CNTL_LINK   = 3
      ERROR_DP_CREATE   = 4
      OTHERS            = 5.
  IF SY-SUBRC <> 0.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SET_LAYOUT_ALV5
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_LAYOUT_ALV5 .
  CLEAR GS_LAYO5.

  GS_LAYO5-GRID_TITLE = '자재 재고현황 리스트'.
  GS_LAYO5-ZEBRA = 'X'.
  GS_LAYO5-CWIDTH_OPT = 'A'.
  GS_LAYO5-EXCP_FNAME = 'EXCP'.
  GS_LAYO5-EXCP_LED = 'X'.
  GS_LAYO5-CTAB_FNAME = 'IT_COL'.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SET_FIELDCAT_ALV5
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_FIELDCAT_ALV5 .
  CLEAR GS_FCAT5.

  GS_FCAT5-FIELDNAME = 'EXCP'.
  GS_FCAT5-JUST = 'C'.
  GS_FCAT5-COLTEXT = '상태'.
  APPEND GS_FCAT5 TO GT_FCAT5.
  CLEAR GS_FCAT5.

  GS_FCAT5-FIELDNAME = 'PLTCODE'.
  GS_FCAT5-JUST = 'C'.
  APPEND GS_FCAT5 TO GT_FCAT5.
  CLEAR GS_FCAT5.

  GS_FCAT5-FIELDNAME = 'PLTNAME'.
  GS_FCAT5-JUST = 'C'.
  APPEND GS_FCAT5 TO GT_FCAT5.
  CLEAR GS_FCAT5.

  GS_FCAT5-FIELDNAME = 'WHCODE'.
  GS_FCAT5-JUST = 'C'.
  APPEND GS_FCAT5 TO GT_FCAT5.
  CLEAR GS_FCAT5.

  GS_FCAT5-FIELDNAME = 'WHNAME'.
  GS_FCAT5-JUST = 'C'.
  APPEND GS_FCAT5 TO GT_FCAT5.
  CLEAR GS_FCAT5.

  GS_FCAT5-FIELDNAME = 'MATCODE'.
  GS_FCAT5-JUST = 'C'.
  GS_FCAT5-KEY = 'X'.
  APPEND GS_FCAT5 TO GT_FCAT5.
  CLEAR GS_FCAT5.

  GS_FCAT5-FIELDNAME = 'MATCODE2'.
  GS_FCAT5-JUST = 'C'.
  GS_FCAT5-NO_OUT = 'X'.
  APPEND GS_FCAT5 TO GT_FCAT5.
  CLEAR GS_FCAT5.

  GS_FCAT5-FIELDNAME = 'MATNAME'.
  GS_FCAT5-JUST = 'C'.
  APPEND GS_FCAT5 TO GT_FCAT5.
  CLEAR GS_FCAT5.

  GS_FCAT5-FIELDNAME = 'MATTYPE'.
  GS_FCAT5-JUST = 'C'.
  GS_FCAT5-NO_OUT = 'X'.
  APPEND GS_FCAT5 TO GT_FCAT5.
  CLEAR GS_FCAT5.

  GS_FCAT5-FIELDNAME = 'CURRSTOCK'.
  GS_FCAT5-JUST = 'R'.
  APPEND GS_FCAT5 TO GT_FCAT5.
  CLEAR GS_FCAT5.

  GS_FCAT5-FIELDNAME = 'UNITCODE1'.
  GS_FCAT5-JUST = 'L'.
  APPEND GS_FCAT5 TO GT_FCAT5.
  CLEAR GS_FCAT5.

  GS_FCAT5-FIELDNAME = 'SAFESTOCK'.
  GS_FCAT5-JUST = 'R'.
  APPEND GS_FCAT5 TO GT_FCAT5.
  CLEAR GS_FCAT5.

  GS_FCAT5-FIELDNAME = 'UNITCODE2'.
  GS_FCAT5-JUST = 'L'.
  APPEND GS_FCAT5 TO GT_FCAT5.
  CLEAR GS_FCAT5.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form INIT_ALV5
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM INIT_ALV5 .
  CALL METHOD GO_ALV5->SET_TABLE_FOR_FIRST_DISPLAY
    EXPORTING
      I_STRUCTURE_NAME              = 'ZSBMM0010_ALV5'
*     IS_VARIANT                    = GS_VARIANT2
*     I_SAVE                        = 'A'
*     I_DEFAULT                     = 'X'
      IS_LAYOUT                     = GS_LAYO5
*     IT_TOOLBAR_EXCLUDING          = LT_EXCLUD
    CHANGING
      IT_OUTTAB                     = GT_DISPLAY5
      IT_FIELDCATALOG               = GT_FCAT5
*     IT_SORT                       = GT_SORT5
*     IT_FILTER                     =
    EXCEPTIONS
      INVALID_PARAMETER_COMBINATION = 1
      PROGRAM_ERROR                 = 2
      TOO_MANY_LINES                = 3
      OTHERS                        = 4.
  IF SY-SUBRC <> 0.
    MESSAGE S205 DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form REFRESH_ALV5
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM REFRESH_ALV5 .
  DATA: LS_STABLE TYPE LVC_S_STBL.

  CALL METHOD GO_ALV5->GET_FRONTEND_LAYOUT
    IMPORTING
      ES_LAYOUT = GS_LAYO5.


  GS_LAYO5-CWIDTH_OPT = ABAP_ON.

  CALL METHOD GO_ALV5->SET_FRONTEND_LAYOUT
    EXPORTING
      IS_LAYOUT = GS_LAYO5.

  CALL METHOD GO_ALV5->REFRESH_TABLE_DISPLAY
    EXPORTING
      IS_STABLE = LS_STABLE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form CHECK_DISPLAY5
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CHECK_DISPLAY5 .
  DATA : LV_ANSWER.

* 재고 현황이 모두 초록불일 때.
  IF GT_DISPLAY5 IS INITIAL. " ALV5에 데이터 없을 때.
    MESSAGE S250 DISPLAY LIKE 'E'.

  ELSE. " ALV5에 데이터 존재할 때.

    READ TABLE GT_DISPLAY5 INTO GS_DISPLAY5
    WITH KEY EXCP = '1'.

    IF SY-SUBRC = 0. " 적정재고 보다 부족한 자재가 있을 때.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          TITLEBAR              = TEXT-T03 " 구매요청 진행 확인.
          TEXT_QUESTION         = TEXT-Q03 " 구매요청을 진행하시겠습니까?
          TEXT_BUTTON_1         = 'YES'
          ICON_BUTTON_1         = 'ICON_OKAY'
          TEXT_BUTTON_2         = 'NO'
          ICON_BUTTON_2         = 'ICON_CANCEL'
          DEFAULT_BUTTON        = '1'
          DISPLAY_CANCEL_BUTTON = ''
        IMPORTING
          ANSWER                = LV_ANSWER.

      IF LV_ANSWER = '1'. " CONFIRM POPUP - YES
        MESSAGE S249. " 구매요청 생성을 확인해주세요.
        CALL SCREEN 140
          STARTING AT 10 7.
      ELSE. " CONFIRM POPUP - NO
        MESSAGE S247.
      ENDIF.
    ELSE. " 적정재고 보다 부족한 자재가 없을 때.
      MESSAGE S251 DISPLAY LIKE 'E'.
    ENDIF.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SET_DATA_ALV6
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_DATA_ALV6 .
  DATA: LS_ZTBMM0010 TYPE ZTBMM0010, " 구매요청 헤더 WA
        LS_ZTBMM0011 TYPE ZTBMM0011. " 구매오더 아이템 WA

  DATA: LV_PRQUANT TYPE ZTBMM0011-PRQUANT,
        LV_PRPRICE TYPE ZTBMM0011-PRPRICE,
        LV_COUNT   TYPE N LENGTH 3. " 구매단위 수량을 몇번 곱했는지.


  CLEAR: GT_DISPLAY6, GS_DISPLAY6, ZSBMM0010_ALV3.

  ZSBMM0010_ALV3-PLTCODE = 'PLT0000001'.
  ZSBMM0010_ALV3-PLTNAME = '이천 플랜트'.
  ZSBMM0010_ALV3-WHCODE = 'STP0000001'.
  ZSBMM0010_ALV3-WHNAME = '이천 구매자재 창고'.
  ZSBMM0010_ALV3-PRDATE = SY-DATUM.


  LOOP AT GT_DISPLAY5 INTO GS_DISPLAY5.
    IF GS_DISPLAY5-EXCP = '1'.
      MOVE-CORRESPONDING GS_DISPLAY5 TO GS_DISPLAY6.
      APPEND GS_DISPLAY6 TO GT_DISPLAY6.
    ELSE.
      CONTINUE.
    ENDIF.
  ENDLOOP.

  SORT GT_DISPLAY6 BY MATCODE ASCENDING.

* 적정재고보다 현 수량이 부족한 자재들에 대한 나머지 필드들 데이터 할당.
  LOOP AT GT_DISPLAY6 INTO GS_DISPLAY6.
    CLEAR LV_COUNT.

    SELECT SINGLE A~BPCODE, B~BPNAME " 자재코드에 해당하는 거래처코드, 거래처 명.
      FROM ZTBMM0070 AS A
      JOIN ZTBSD1051 AS B
        ON A~BPCODE EQ B~BPCODE
     WHERE MATCODE EQ @GS_DISPLAY6-MATCODE
      INTO (@GS_DISPLAY6-BPCODE, @GS_DISPLAY6-BPNAME).

    READ TABLE GT_DISPLAY5 INTO GS_DISPLAY5 " 재고현황 테이블에서 현재고와 적정재고 데이터.
    WITH KEY MATCODE = GS_DISPLAY6-MATCODE.

    SELECT SINGLE INFQUANT, INFPRICE, UNITCODE, CURRENCY " 현재 MAT에 해당하는 구매단위수량, 가격 데이터.
      FROM ZTBMM0070
     WHERE MATCODE EQ @GS_DISPLAY6-MATCODE
      INTO (@LV_PRQUANT, @LV_PRPRICE, @GS_DISPLAY6-UNITCODE, @GS_DISPLAY6-CURRENCY).

*   적정재고 수량 > 현재고 수량이면 구매단위수량만큼 수량 증가 반복.
    WHILE GS_DISPLAY5-SAFESTOCK > GS_DISPLAY5-CURRSTOCK. " WHILE 조건문이 참일때 구문 동작.
      GS_DISPLAY5-CURRSTOCK = GS_DISPLAY5-CURRSTOCK + LV_PRQUANT.
      LV_COUNT = LV_COUNT + 1.
    ENDWHILE.

    GS_DISPLAY6-PRQUANT = LV_PRQUANT * LV_COUNT.
    GS_DISPLAY6-PRPRICE = LV_PRPRICE * LV_COUNT.

    MODIFY GT_DISPLAY6 FROM GS_DISPLAY6.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form CREATE_OBJECT_6
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CREATE_OBJECT_6 .
  CREATE OBJECT GO_CUST6
    EXPORTING
      CONTAINER_NAME              = 'CUST6'
    EXCEPTIONS
      CNTL_ERROR                  = 1
      CNTL_SYSTEM_ERROR           = 2
      CREATE_ERROR                = 3
      LIFETIME_ERROR              = 4
      LIFETIME_DYNPRO_DYNPRO_LINK = 5
      OTHERS                      = 6.
  IF SY-SUBRC <> 0.
  ENDIF.

  CREATE OBJECT GO_ALV6
    EXPORTING
      I_PARENT          = GO_CUST6
    EXCEPTIONS
      ERROR_CNTL_CREATE = 1
      ERROR_CNTL_INIT   = 2
      ERROR_CNTL_LINK   = 3
      ERROR_DP_CREATE   = 4
      OTHERS            = 5.
  IF SY-SUBRC <> 0.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SET_LAYOUT_ALV6
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_LAYOUT_ALV6 .
  CLEAR GS_LAYO6.

  GS_LAYO6-GRID_TITLE = '구매요청 생성 자재 리스트'.
  GS_LAYO6-ZEBRA = 'X'.
  GS_LAYO6-CWIDTH_OPT = 'A'.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form SET_FIELDCAT_ALV6
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_FIELDCAT_ALV6 .
  CLEAR GS_FCAT6.

  GS_FCAT6-FIELDNAME = 'PRNUM'.
  GS_FCAT6-JUST = 'C'.
  GS_FCAT6-NO_OUT = 'X'.
  APPEND GS_FCAT6 TO GT_FCAT6.
  CLEAR GS_FCAT6.

  GS_FCAT6-FIELDNAME = 'BPCODE'.
  GS_FCAT6-JUST = 'C'.
  GS_FCAT6-COLTEXT = '거래처 코드'.
  APPEND GS_FCAT6 TO GT_FCAT6.
  CLEAR GS_FCAT6.

  GS_FCAT6-FIELDNAME = 'BPNAME'.
  GS_FCAT6-JUST = 'C'.
  GS_FCAT6-COLTEXT = '거래처 명'.
  APPEND GS_FCAT6 TO GT_FCAT6.
  CLEAR GS_FCAT6.

  GS_FCAT6-FIELDNAME = 'PLTCODE'.
  GS_FCAT6-JUST = 'C'.
  GS_FCAT6-NO_OUT = 'X'.
  APPEND GS_FCAT6 TO GT_FCAT6.
  CLEAR GS_FCAT6.

  GS_FCAT6-FIELDNAME = 'PLTNAME'.
  GS_FCAT6-JUST = 'C'.
  GS_FCAT6-NO_OUT = 'X'.
  APPEND GS_FCAT6 TO GT_FCAT6.
  CLEAR GS_FCAT6.

  GS_FCAT6-FIELDNAME = 'WHCODE'.
  GS_FCAT6-JUST = 'C'.
  GS_FCAT6-NO_OUT = 'X'.
  APPEND GS_FCAT6 TO GT_FCAT6.
  CLEAR GS_FCAT6.

  GS_FCAT6-FIELDNAME = 'WHNAME'.
  GS_FCAT6-JUST = 'C'.
  GS_FCAT6-NO_OUT = 'X'.
  APPEND GS_FCAT6 TO GT_FCAT6.
  CLEAR GS_FCAT6.

  GS_FCAT6-FIELDNAME = 'PRDATE'.
  GS_FCAT6-JUST = 'C'.
  GS_FCAT6-NO_OUT = 'X'.
  APPEND GS_FCAT6 TO GT_FCAT6.
  CLEAR GS_FCAT6.

  GS_FCAT6-FIELDNAME = 'MATCODE'.
  GS_FCAT6-JUST = 'C'.
  GS_FCAT6-KEY = 'X'.
  APPEND GS_FCAT6 TO GT_FCAT6.
  CLEAR GS_FCAT6.

  GS_FCAT6-FIELDNAME = 'MATNAME'.
  GS_FCAT6-JUST = 'C'.
  APPEND GS_FCAT6 TO GT_FCAT6.
  CLEAR GS_FCAT6.

  GS_FCAT6-FIELDNAME = 'PRQUANT'.
  GS_FCAT6-JUST = 'R'.
  APPEND GS_FCAT6 TO GT_FCAT6.
  CLEAR GS_FCAT6.

  GS_FCAT6-FIELDNAME = 'UNITCODE'.
  GS_FCAT6-JUST = 'L'.
  APPEND GS_FCAT6 TO GT_FCAT6.
  CLEAR GS_FCAT6.

  GS_FCAT6-FIELDNAME = 'PRPRICE'.
  GS_FCAT6-JUST = 'R'.
  APPEND GS_FCAT6 TO GT_FCAT6.
  CLEAR GS_FCAT6.

  GS_FCAT6-FIELDNAME = 'CURRENCY'.
  GS_FCAT6-JUST = 'L'.
  APPEND GS_FCAT6 TO GT_FCAT6.
  CLEAR GS_FCAT6.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form INIT_ALV6
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM INIT_ALV6 .
  " DIALOG ALV DISPLAY.
  GS_VARIANT-REPORT = SY-CPROG.
  GS_VARIANT-VARIANT = '/ZALV6'.

  CALL METHOD GO_ALV6->SET_TABLE_FOR_FIRST_DISPLAY
    EXPORTING
      I_STRUCTURE_NAME              = 'ZSBMM0010_ALV3'
      IS_VARIANT                    = GS_VARIANT
      I_SAVE                        = 'A'
*     I_DEFAULT                     = 'X'
      IS_LAYOUT                     = GS_LAYO6
*     IT_TOOLBAR_EXCLUDING          = LT_EXCLUD
    CHANGING
      IT_OUTTAB                     = GT_DISPLAY6
      IT_FIELDCATALOG               = GT_FCAT6
*     IT_SORT                       = GT_SORT3
*     IT_FILTER                     =
    EXCEPTIONS
      INVALID_PARAMETER_COMBINATION = 1
      PROGRAM_ERROR                 = 2
      TOO_MANY_LINES                = 3
      OTHERS                        = 4.
  IF SY-SUBRC <> 0.
    MESSAGE S205 DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form REFRESH_ALV6
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM REFRESH_ALV6 .
  DATA: LS_STABLE TYPE LVC_S_STBL.

  CALL METHOD GO_ALV6->GET_FRONTEND_LAYOUT
    IMPORTING
      ES_LAYOUT = GS_LAYO6.

  GS_LAYO6-CWIDTH_OPT = ABAP_ON.

  CALL METHOD GO_ALV6->SET_FRONTEND_LAYOUT
    EXPORTING
      IS_LAYOUT = GS_LAYO6.

  CALL METHOD GO_ALV6->REFRESH_TABLE_DISPLAY
    EXPORTING
      IS_STABLE = LS_STABLE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form CREATE_PR2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CREATE_PR2 .
*  GS_ZSBMM0010_PR TYPE ZSBMM0010_PR " 구매요청 헤더 & 아이템 WA
  DATA: LV_PRNR    TYPE NUM8,
        LV_BPCODE  TYPE C LENGTH 10,
        LV_BPCODE2 TYPE C LENGTH 10,
        LV_MATCODE TYPE C LENGTH 10.

  DATA: LV_ANSWER TYPE NUM1.

  DATA: LS_ZTBMM0010 TYPE ZTBMM0010,
        LS_ZTBMM0011 TYPE ZTBMM0011.

  CLEAR GT_DISPLAY4.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      TITLEBAR              = TEXT-T04 " 구매요청 생성 확인.
      TEXT_QUESTION         = TEXT-Q04 " 구매요청을 생성하시겠습니까?
      TEXT_BUTTON_1         = 'YES'
      ICON_BUTTON_1         = 'ICON_OKAY'
      TEXT_BUTTON_2         = 'NO'
      ICON_BUTTON_2         = 'ICON_CANCEL'
      DEFAULT_BUTTON        = '1'
      DISPLAY_CANCEL_BUTTON = ''
    IMPORTING
      ANSWER                = LV_ANSWER.

  IF LV_ANSWER = '1'. " 구매요청 생성 YES
    SELECT SINGLE EMPID
        FROM ZTBSD1030
       WHERE LOGID EQ @SY-UNAME
        INTO @DATA(LV_EMPID).

    MOVE-CORRESPONDING GT_DISPLAY6 TO GT_DISPLAY4.

    LOOP AT GT_DISPLAY4 INTO GS_DISPLAY4.
      IF GS_DISPLAY4-BPCODE <> LV_BPCODE. " 이전 행의 BPCODE와 현재행의 BPCODE 값이 다를 때.

        LV_BPCODE = GS_DISPLAY4-BPCODE.

        CALL FUNCTION 'NUMBER_GET_NEXT'
          EXPORTING
            NR_RANGE_NR             = '01'
            OBJECT                  = 'ZBBMM0010'
          IMPORTING
            NUMBER                  = LV_PRNR
          EXCEPTIONS
            INTERVAL_NOT_FOUND      = 1
            NUMBER_RANGE_NOT_INTERN = 2
            OBJECT_NOT_FOUND        = 3
            QUANTITY_IS_0           = 4
            QUANTITY_IS_NOT_1       = 5
            INTERVAL_OVERFLOW       = 6
            BUFFER_OVERFLOW         = 7
            OTHERS                  = 8.
        IF SY-SUBRC <> 0.
        ENDIF.

        CONCATENATE 'PR' LV_PRNR INTO GS_DISPLAY4-PRNUM.

      ELSE. " 이전 행의 BPCODE와 현재행의 BPCODE 값이 같을 때.
        CONCATENATE 'PR' LV_PRNR INTO GS_DISPLAY4-PRNUM.
      ENDIF.

      GS_DISPLAY4-PRDATE = SY-DATUM.
      MODIFY GT_DISPLAY4 FROM GS_DISPLAY4.
    ENDLOOP.

* GT_DISPLAY4 담긴 DATA GT_ZSBMM0010_PR에 할당.
    MOVE-CORRESPONDING GT_DISPLAY4 TO GT_ZSBMM0010_PR.

* GT_ZSBMM0010_PR ITAB에 EMPID, STATUS 할당.
    LOOP AT GT_ZSBMM0010_PR INTO GS_ZSBMM0010_PR.
      GS_ZSBMM0010_PR-EMPID = LV_EMPID.
      GS_ZSBMM0010_PR-STATUS = 'X'.

      MOVE-CORRESPONDING GS_ZSBMM0010_PR TO LS_ZTBMM0011.
      INSERT ZTBMM0011 FROM LS_ZTBMM0011. " 구매요청 아이템 데이터 TP TABLE CREATE.

      MODIFY GT_ZSBMM0010_PR FROM GS_ZSBMM0010_PR. " * GT_ZSBMM0010_PR DATA UPDATE.
    ENDLOOP.

* GT_ZSBMM0010_PR 에서 PRNUM 중복 행 제거.
    DELETE ADJACENT DUPLICATES FROM GT_ZSBMM0010_PR COMPARING PRNUM.

* 구매요청 헤더 데이터 TP TABLE CREATE.
    LOOP AT GT_ZSBMM0010_PR INTO GS_ZSBMM0010_PR.
      MOVE-CORRESPONDING GS_ZSBMM0010_PR TO LS_ZTBMM0010.
      INSERT ZTBMM0010 FROM LS_ZTBMM0010.
    ENDLOOP.

    MESSAGE S252. " 구매요청을 성공적으로 생성하였습니다.
    LEAVE TO SCREEN 0.
    PERFORM REFRESH_ALV4.

  ELSE. " 구매요청 생성 NO
    MESSAGE S247. " 구매요청 생성을 취소하였습니다.
  ENDIF.

ENDFORM.
