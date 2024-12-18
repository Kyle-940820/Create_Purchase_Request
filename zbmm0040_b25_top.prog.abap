*&---------------------------------------------------------------------*
*& Include ZBMM0040_TOP                             - Module Pool      SAPMZBMM0040
*&---------------------------------------------------------------------*
PROGRAM SAPMZBMM0040 MESSAGE-ID ZCOMMON_MSG.

*&--------------------------------------------------------------------*
*& 사용할 테이블, TYPE, ITAB, WA 선언.
*&--------------------------------------------------------------------*
DATA: OK_CODE    TYPE SY-UCOMM,
      GV_DYNNR   TYPE SY-DYNNR,
      GS_VARIANT TYPE DISVARIANT.

CONTROLS: TAB_STRIP TYPE TABSTRIP.

TABLES: ZSBMM0010_ALV1, ZSBMM0060, ZSBMM0010_PR,
        ZSBMM0010_ALV3, ZSBMM0010_ALV5.

*&--------------------------------------------------------------------*
*& 조회한 거래처에 해당하는 인포레코드 정보를 표시할 ALV1 ITAB & WA
*&--------------------------------------------------------------------*
TYPES: BEGIN OF TS_DISPLAY1.
         INCLUDE TYPE ZSBMM0010_ALV1.
TYPES:   GT_BTN1 TYPE LVC_T_STYL,
       END OF TS_DISPLAY1.

DATA: GS_DISPLAY1 TYPE TS_DISPLAY1,
      GT_DISPLAY1 LIKE TABLE OF GS_DISPLAY1.

*&--------------------------------------------------------------------*
*& ALV1에 대한 ALV 관련 변수
*&--------------------------------------------------------------------*
DATA: GO_CUST1 TYPE REF TO CL_GUI_CUSTOM_CONTAINER,
      GO_ALV1  TYPE REF TO CL_GUI_ALV_GRID,
      GS_LAYO1 TYPE LVC_S_LAYO,
      GT_SORT1 TYPE LVC_T_SORT,
      GS_SORT1 TYPE LVC_S_SORT,
      GT_FCAT1 TYPE LVC_T_FCAT,
      GS_FCAT1 TYPE LVC_S_FCAT.

*&---------------------------------------------------------------------*
*& ALV1에서 각 자재에 대해 '추가'/'차감' 버튼 눌렀을 때, ALV2에 해당 자재 수량 반영시키는 ITAB & WA
*&---------------------------------------------------------------------*
DATA: GS_DISPLAY2 TYPE ZSBMM0010_ALV2,
      GT_DISPLAY2 LIKE TABLE OF GS_DISPLAY2.

*&---------------------------------------------------------------------*
*& ALV2에 대한 ALV 관련 변수.
*&---------------------------------------------------------------------*
DATA: GO_CUST2 TYPE REF TO CL_GUI_CUSTOM_CONTAINER,
      GO_ALV2  TYPE REF TO CL_GUI_ALV_GRID,
      GS_LAYO2 TYPE LVC_S_LAYO,
      GT_SORT2 TYPE LVC_T_SORT,
      GS_SORT2 TYPE LVC_S_SORT,
      GT_FCAT2 TYPE LVC_T_FCAT,
      GS_FCAT2 TYPE LVC_S_FCAT.

*&---------------------------------------------------------------------*
*& ALV2에서 선택한 자재에 대한 데이터를 담는 변수.
*&---------------------------------------------------------------------*
DATA: GT_ROW2 TYPE LVC_T_ROID,
      GS_ROW2 TYPE LVC_S_ROID.

*&---------------------------------------------------------------------*
*& 구매요청생성 클릭 시 구매요청생성 팝업창 I/O 필드 변수.
*&---------------------------------------------------------------------*
DATA: GS_ZSBMM0010_PR TYPE ZSBMM0010_PR,
      GT_ZSBMM0010_PR LIKE TABLE OF GS_ZSBMM0010_PR.


*&---------------------------------------------------------------------*
*& 수동생성 Tab strip 에서 '구매요청생성' 버튼 누를 때 띄우는 팝업 ALV3 ITAB & WA
*&---------------------------------------------------------------------*
DATA: GS_DISPLAY3 TYPE ZSBMM0010_ALV3,
      GT_DISPLAY3 LIKE TABLE OF GS_DISPLAY3.

*&---------------------------------------------------------------------*
*& ALV3에 대한 ALV 관련 변수.
*&---------------------------------------------------------------------*
DATA: GO_CUST3 TYPE REF TO CL_GUI_CUSTOM_CONTAINER,
      GO_ALV3  TYPE REF TO CL_GUI_ALV_GRID,
      GS_LAYO3 TYPE LVC_S_LAYO,
      GT_SORT3 TYPE LVC_T_SORT,
      GS_SORT3 TYPE LVC_S_SORT,
      GT_FCAT3 TYPE LVC_T_FCAT,
      GS_FCAT3 TYPE LVC_S_FCAT.

*&---------------------------------------------------------------------*
*& 구매요청생성 확인 팝업에서 최종 확인 눌렀을 때, '구매요청 생성 완료 리스트'에 해당하는  ALV4 ITAB & WA
*&---------------------------------------------------------------------*
* ALV4 - 구매요청생성 결과로 만들어진 구매요청 DATA DISPLAY.
DATA: GS_DISPLAY4 TYPE ZSBMM0010_ALV3,
      GT_DISPLAY4 LIKE TABLE OF GS_DISPLAY4.

*&---------------------------------------------------------------------*
*& ALV4에 대한 ALV 관련 변수.
*&---------------------------------------------------------------------*
DATA: GO_CUST4 TYPE REF TO CL_GUI_CUSTOM_CONTAINER,
      GO_ALV4  TYPE REF TO CL_GUI_ALV_GRID,
      GS_LAYO4 TYPE LVC_S_LAYO,
      GT_SORT4 TYPE LVC_T_SORT,
      GS_SORT4 TYPE LVC_S_SORT,
      GT_FCAT4 TYPE LVC_T_FCAT,
      GS_FCAT4 TYPE LVC_S_FCAT.

*&---------------------------------------------------------------------*
*& '자동생성' 탭에서 자재 현재고 상태 Data Display ALV5 ITAB & WA
*&---------------------------------------------------------------------*
* ALV5 - '자동생성'탭에서 자재 DATA DISPLAY.
TYPES: BEGIN OF TS_DISPLAY5.
         INCLUDE TYPE ZSBMM0010_ALV5.
TYPES:   IT_COL TYPE LVC_T_SCOL,
       END OF TS_DISPLAY5.

DATA: GS_DISPLAY5 TYPE TS_DISPLAY5,
      GT_DISPLAY5 LIKE TABLE OF GS_DISPLAY5.

*&---------------------------------------------------------------------*
*& ALV5에 대한 ALV 관련 변수.
*&---------------------------------------------------------------------*
DATA: GO_CUST5 TYPE REF TO CL_GUI_CUSTOM_CONTAINER,
      GO_ALV5  TYPE REF TO CL_GUI_ALV_GRID,
      GS_LAYO5 TYPE LVC_S_LAYO,
      GT_SORT5 TYPE LVC_T_SORT,
      GS_SORT5 TYPE LVC_S_SORT,
      GT_FCAT5 TYPE LVC_T_FCAT,
      GS_FCAT5 TYPE LVC_S_FCAT.

*&---------------------------------------------------------------------*
*& 자동생성 Tab strip 에서 '구매요청생성' 버튼 누를 때 띄우는 팝업 ALV6 ITAB & WA
*&---------------------------------------------------------------------*
DATA: GS_DISPLAY6 TYPE ZSBMM0010_ALV3,
      GT_DISPLAY6 LIKE TABLE OF GS_DISPLAY3.

*&---------------------------------------------------------------------*
*& ALV6에 대한 ALV 관련 변수.
*&---------------------------------------------------------------------*
DATA: GO_CUST6 TYPE REF TO CL_GUI_CUSTOM_CONTAINER,
      GO_ALV6  TYPE REF TO CL_GUI_ALV_GRID,
      GS_LAYO6 TYPE LVC_S_LAYO,
      GT_SORT6 TYPE LVC_T_SORT,
      GS_SORT6 TYPE LVC_S_SORT,
      GT_FCAT6 TYPE LVC_T_FCAT,
      GS_FCAT6 TYPE LVC_S_FCAT.
