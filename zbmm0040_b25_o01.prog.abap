*&---------------------------------------------------------------------*
*& Include          ZBMM0040_O01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE STATUS_0100 OUTPUT.
  SET PF-STATUS 'S100'.
  SET TITLEBAR 'T100'.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_0130 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE STATUS_0130 OUTPUT.
  SET PF-STATUS 'S130'.
  SET TITLEBAR 'T130'.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module SET_DYNNR OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE SET_DYNNR OUTPUT.
  PERFORM SET_ACTIVETAB.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module CLEAR_OKCODE OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE CLEAR_OKCODE OUTPUT.
  CLEAR OK_CODE.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module INIT_ALV1 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE INIT_ALV1 OUTPUT.

  IF GO_CUST1 IS INITIAL.
    PERFORM CREATE_OBJECT_1.
    PERFORM SET_LAYOUT_ALV1.
    PERFORM SET_FIELDCAT_ALV1.
    PERFORM SET_EVENT_ALV1.
    PERFORM INIT_ALV1.
  ELSE.
    PERFORM REFRESH_ALV1.
  ENDIF.


ENDMODULE.
*&---------------------------------------------------------------------*
*& Module INIT_AVL2 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE INIT_AVL2 OUTPUT.
  IF GO_CUST2 IS INITIAL.
    PERFORM CREATE_OBJECT_2.
    PERFORM SET_LAYOUT_ALV2.
    PERFORM SET_FIELDCAT_ALV2.
    PERFORM SET_EVENT_ALV2.
    PERFORM INIT_ALV2.

  ELSE.
    PERFORM REFRESH_ALV2.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_0140 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE STATUS_0140 OUTPUT.
  SET PF-STATUS 'S140'.
  SET TITLEBAR 'T140'.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module SET_DATA_ALV3 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE SET_DATA_ALV3 OUTPUT.
  PERFORM SET_DATA_ALV3.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module INIT_ALV3 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE INIT_ALV3 OUTPUT.
  IF GO_CUST3 IS INITIAL.
    PERFORM CREATE_OBJECT_3.
    PERFORM SET_LAYOUT_ALV3.
    PERFORM SET_FIELDCAT_ALV3.
    PERFORM INIT_ALV3.

  ELSE.
    PERFORM REFRESH_ALV3.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module INIT_ALV4 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE INIT_ALV4 OUTPUT.
  IF GO_CUST4 IS INITIAL.
    PERFORM CREATE_OBJECT_4.
    PERFORM SET_LAYOUT_ALV4.
    PERFORM SET_FIELDCAT_ALV4.
*    PERFORM SET_SORT_ALV4.
*    PERFORM SET_EVENT_ALV4.
    PERFORM INIT_ALV4.

  ELSE.
    PERFORM REFRESH_ALV4.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module INIT_ALV5 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE INIT_ALV5 OUTPUT.
    IF GO_CUST5 IS INITIAL.
    PERFORM CREATE_OBJECT_5.
    PERFORM SET_LAYOUT_ALV5.
    PERFORM SET_FIELDCAT_ALV5.
*    PERFORM SET_SORT_ALV5.
*    PERFORM SET_EVENT_ALV5.
    PERFORM INIT_ALV5.

  ELSE.
    PERFORM REFRESH_ALV5.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module SET_DATA_ALV6 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE SET_DATA_ALV6 OUTPUT.
  PERFORM SET_DATA_ALV6.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module INIT_ALV6 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE INIT_ALV6 OUTPUT.
  IF GO_CUST6 IS INITIAL.
    PERFORM CREATE_OBJECT_6.
    PERFORM SET_LAYOUT_ALV6.
    PERFORM SET_FIELDCAT_ALV6.
    PERFORM INIT_ALV6.

  ELSE.
    PERFORM REFRESH_ALV6.
  ENDIF.
ENDMODULE.
