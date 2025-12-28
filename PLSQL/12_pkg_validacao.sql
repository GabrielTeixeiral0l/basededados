-- =============================================================================
-- 12. PACOTE DE VALIDAÇÕES
-- Centraliza validações comuns (NIF, CC, Emails, etc).
-- =============================================================================

CREATE OR REPLACE PACKAGE PKG_VALIDACAO IS
    FUNCTION FUN_VALIDAR_NIF(p_nif IN VARCHAR2) RETURN BOOLEAN;
    FUNCTION FUN_VALIDAR_CC(p_cc IN VARCHAR2) RETURN BOOLEAN;
    FUNCTION FUN_VALIDAR_EMAIL(p_email IN VARCHAR2) RETURN BOOLEAN;
    FUNCTION FUN_VALIDAR_IBAN(p_iban IN VARCHAR2) RETURN BOOLEAN;
END PKG_VALIDACAO;
/

CREATE OR REPLACE PACKAGE BODY PKG_VALIDACAO IS

    FUNCTION FUN_VALIDAR_NIF(p_nif IN VARCHAR2) RETURN BOOLEAN IS
        v_check_digit NUMBER;
        v_soma NUMBER := 0;
        v_nif VARCHAR2(9) := TRIM(p_nif);
        i NUMBER := 1;
    BEGIN
        IF LENGTH(v_nif) != 9 OR NOT REGEXP_LIKE(v_nif, '^[0-9]+$') THEN
            RETURN FALSE;
        END IF;

        -- Validação básica do dígito de controlo (Algoritmo Modulo 11)
        WHILE i <= 8 LOOP
            v_soma := v_soma + TO_NUMBER(SUBSTR(v_nif, i, 1)) * (10 - i + 1);
            i := i + 1;
        END LOOP;

        v_check_digit := 11 - MOD(v_soma, 11);
        IF v_check_digit >= 10 THEN
            v_check_digit := 0;
        END IF;

        RETURN v_check_digit = TO_NUMBER(SUBSTR(v_nif, 9, 1));
    EXCEPTION WHEN OTHERS THEN
        RETURN FALSE;
    END FUN_VALIDAR_NIF;

    FUNCTION FUN_VALIDAR_CC(p_cc IN VARCHAR2) RETURN BOOLEAN IS
    BEGIN
        -- Implementação simplificada (apenas tamanho e formato)
        RETURN LENGTH(TRIM(p_cc)) >= 8;
    END FUN_VALIDAR_CC;

    FUNCTION FUN_VALIDAR_EMAIL(p_email IN VARCHAR2) RETURN BOOLEAN IS
    BEGIN
        RETURN REGEXP_LIKE(p_email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
    END FUN_VALIDAR_EMAIL;

    FUNCTION FUN_VALIDAR_IBAN(p_iban IN VARCHAR2) RETURN BOOLEAN IS
    BEGIN
        -- Validação simples de formato PT50...
        RETURN LENGTH(TRIM(p_iban)) = 25 AND SUBSTR(TRIM(p_iban), 1, 2) = 'PT';
    END FUN_VALIDAR_IBAN;

END PKG_VALIDACAO;
/
