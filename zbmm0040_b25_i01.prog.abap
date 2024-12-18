*&---------------------------------------------------------------------*
*& Include          ZBMM0040_I01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE USER_COMMAND_0100 INPUT.
  CASE OK_CODE.
    WHEN 'EXIT'.
      LEAVE PROGRAM.
    WHEN 'BACK' OR 'CANCEL'.
      LEAVE TO SCREEN 0.
    WHEN 'TAB1' OR 'TAB2'.
      TAB_STRIP-ACTIVETAB = OK_CODE.
    WHEN 'CREATE'.
      IF TAB_STRIP-ACTIVETAB = 'TAB1'.
        PERFORM CHECK_DISPLAY2.
      ELSE.
        PERFORM CHECK_DISPLAY5.
      ENDIF.

  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  EXIT  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE EXIT INPUT.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0130  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE USER_COMMAND_0130 INPUT.
  CASE OK_CODE.
    WHEN 'CANCEL'.
      MESSAGE S247.
      LEAVE TO SCREEN 0.
    WHEN 'SAVE'.
      PERFORM CREATE_PR.
  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0110  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE USER_COMMAND_0110 INPUT.
  CASE OK_CODE.
    WHEN 'BTN1'. " 검색 버튼 눌렀을 때.
      PERFORM GET_SUPPLIER.
  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0120  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE USER_COMMAND_0120 INPUT.
  CASE OK_CODE.
    WHEN 'BTN2'.
      PERFORM GET_DATA_ALV5. " '자동생성' Tab에서 '조회'버튼 눌렀을 때.
  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0140  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE USER_COMMAND_0140 INPUT.
  CASE OK_CODE.
    WHEN 'SAVE'.
      PERFORM CREATE_PR2. " 구매요청결과 확인에서 최종 'YES' 누를시.
    WHEN 'CANCEL'.
      MESSAGE S247. " 구매요청 생성을 취소하였습니다.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.
