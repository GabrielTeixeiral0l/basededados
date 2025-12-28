SET SERVEROUTPUT ON;
DECLARE
    v_res BOOLEAN;
BEGIN
    v_res := PKG_VALIDACAO.FUN_VALIDAR_EMAIL('d@l.com');
    IF v_res THEN DBMS_OUTPUT.PUT_LINE('Email d@l.com: VALIDO'); ELSE DBMS_OUTPUT.PUT_LINE('Email d@l.com: INVALIDO'); END IF;
    
    v_res := PKG_VALIDACAO.FUN_VALIDAR_EMAIL('teste.123@dominio.co.uk');
    IF v_res THEN DBMS_OUTPUT.PUT_LINE('Email complexo: VALIDO'); ELSE DBMS_OUTPUT.PUT_LINE('Email complexo: INVALIDO'); END IF;
END;
/
