-- =============================================================================
-- 12. PACOTE DE VALIDAÇÕES
-- Centraliza validações comuns (NIF, CC, Emails, etc).
-- =============================================================================

CREATE OR REPLACE PACKAGE PKG_VALIDACAO IS
    FUNCTION FUN_VALIDAR_NIF(p_nif IN VARCHAR2) RETURN BOOLEAN;
    FUNCTION FUN_VALIDAR_CC(p_cc IN VARCHAR2) RETURN BOOLEAN;
    FUNCTION FUN_VALIDAR_EMAIL(p_email IN VARCHAR2) RETURN BOOLEAN;
    FUNCTION FUN_VALIDAR_IBAN(p_iban IN VARCHAR2) RETURN BOOLEAN;
    FUNCTION FUN_VALIDAR_TELEMOVEL(p_telemovel IN VARCHAR2) RETURN BOOLEAN;
    FUNCTION FUN_VALIDAR_TAMANHO_FICHEIRO(p_tamanho IN NUMBER) RETURN BOOLEAN;
    
    -- Validação e Correção de Status (0 ou 1)
    FUNCTION FUN_VALIDAR_STATUS(p_status IN VARCHAR2, p_tabela IN VARCHAR2) RETURN VARCHAR2;
END PKG_VALIDACAO;
/

CREATE OR REPLACE PACKAGE BODY PKG_VALIDACAO IS

    -- Validação de Status (0 ou 1)
    FUNCTION FUN_VALIDAR_STATUS(p_status IN VARCHAR2, p_tabela IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        IF p_status NOT IN ('0', '1') OR p_status IS NULL THEN
            PKG_LOG.ERRO('Status invalido (' || NVL(p_status, 'NULL') || ') na tabela ' || p_tabela || '. Forcado a 0.', p_tabela);
            RETURN '0';
        END IF;
        RETURN p_status;
    END FUN_VALIDAR_STATUS;

    FUNCTION FUN_VALIDAR_NIF(p_nif IN VARCHAR2) RETURN BOOLEAN IS
        v_nif VARCHAR2(9) := p_nif;
        v_soma NUMBER := 0;
        v_resto NUMBER;
        v_check_digit NUMBER;
        i NUMBER := 1;
    BEGIN
        -- Formato Básico (9 dígitos numéricos)
        IF LENGTH(v_nif) != 9 OR NOT REGEXP_LIKE(v_nif, '^[0-9]+$') THEN
            RETURN FALSE;
        END IF;

        -- Se não for rigorosa, o formato basta
        IF NOT PKG_CONSTANTES.VALIDACAO_RIGOROSA_NIF THEN
            RETURN TRUE;
        END IF;

        -- Algoritmo Modulo 11
        LOOP
            EXIT WHEN i > 8;
            v_soma := v_soma + TO_NUMBER(SUBSTR(v_nif, i, 1)) * (10 - i);
            i := i + 1;
        END LOOP;

        v_resto := MOD(v_soma, 11);
        v_check_digit := CASE WHEN v_resto IN (0, 1) THEN 0 ELSE 11 - v_resto END;

        RETURN v_check_digit = TO_NUMBER(SUBSTR(v_nif, 9, 1));
    EXCEPTION WHEN OTHERS THEN RETURN FALSE;
    END FUN_VALIDAR_NIF;

    FUNCTION FUN_VALIDAR_CC(p_cc IN VARCHAR2) RETURN BOOLEAN IS
        v_cc VARCHAR2(20) := UPPER(REPLACE(p_cc, ' ', ''));
    BEGIN
        RETURN REGEXP_LIKE(v_cc, '^[0-9A-Z]{12}$');
    END FUN_VALIDAR_CC;

    FUNCTION FUN_VALIDAR_EMAIL(p_email IN VARCHAR2) RETURN BOOLEAN IS
    BEGIN
        RETURN REGEXP_LIKE(p_email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
    END FUN_VALIDAR_EMAIL;

    FUNCTION FUN_VALIDAR_IBAN(p_iban IN VARCHAR2) RETURN BOOLEAN IS
    BEGIN
        RETURN LENGTH(TRIM(p_iban)) = 25 AND SUBSTR(TRIM(p_iban), 1, 2) = 'PT' 
               AND REGEXP_LIKE(SUBSTR(TRIM(p_iban), 3), '^[0-9]+$');
    END FUN_VALIDAR_IBAN;

    FUNCTION FUN_VALIDAR_TELEMOVEL(p_telemovel IN VARCHAR2) RETURN BOOLEAN IS
    BEGIN
        RETURN REGEXP_LIKE(p_telemovel, '^9[0-9]{8}$');
    END FUN_VALIDAR_TELEMOVEL;

    FUNCTION FUN_VALIDAR_TAMANHO_FICHEIRO(p_tamanho IN NUMBER) RETURN BOOLEAN IS
    BEGIN
        RETURN p_tamanho > 0 AND p_tamanho <= PKG_CONSTANTES.TAMANHO_MAX_FICHEIRO;
    END FUN_VALIDAR_TAMANHO_FICHEIRO;

END PKG_VALIDACAO;
/