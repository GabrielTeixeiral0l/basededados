-- =============================================================================
-- 12. PACOTE DE VALIDAÇÃO DE DOCUMENTOS (NIF E CC OFICIAL)
-- =============================================================================

CREATE OR REPLACE PACKAGE PKG_VALIDACAO IS
    FUNCTION FUN_VAL_NIF(p_nif IN VARCHAR2) RETURN BOOLEAN;
    FUNCTION FUN_VAL_CC(p_cc IN VARCHAR2) RETURN BOOLEAN;
END PKG_VALIDACAO;
/

CREATE OR REPLACE PACKAGE BODY PKG_VALIDACAO IS

    -- -------------------------------------------------------------------------
    -- VALIDAÇÃO DE NIF
    -- -------------------------------------------------------------------------
    FUNCTION FUN_VAL_NIF(p_nif IN VARCHAR2) RETURN BOOLEAN 
    IS
        v_soma  NUMBER := 0;
        v_check NUMBER;
        v_i     NUMBER := 1;
    BEGIN
        -- Validação básica de tamanho (Sempre ativa)
        IF LENGTH(p_nif) != 9 OR NOT REGEXP_LIKE(p_nif, '^[0-9]+$') THEN 
            RETURN FALSE; 
        END IF;

        -- Se a validação rigorosa estiver desligada, termina aqui
        IF NOT PKG_CONSTANTES.VALIDACAO_RIGOROSA_NIF THEN
            RETURN TRUE;
        END IF;

        -- Validação Matemática (Checksum)
        IF SUBSTR(p_nif, 1, 1) NOT IN ('1','2','3','5','6','8','9') THEN 
            RETURN FALSE; 
        END IF;

        WHILE v_i <= 8 LOOP
            v_soma := v_soma + (TO_NUMBER(SUBSTR(p_nif, v_i, 1)) * (10 - v_i));
            v_i := v_i + 1;
        END LOOP;

        v_check := 11 - (MOD(v_soma, 11));
        IF v_check >= 10 THEN v_check := 0; END IF;

        RETURN (v_check = TO_NUMBER(SUBSTR(p_nif, 9, 1)));
    EXCEPTION 
        WHEN OTHERS THEN RETURN FALSE;
    END FUN_VAL_NIF;

    -- -------------------------------------------------------------------------
    -- VALIDAÇÃO DE CC
    -- -------------------------------------------------------------------------
    FUNCTION FUN_VAL_CC(p_cc IN VARCHAR2) RETURN BOOLEAN 
    IS
        v_soma     NUMBER := 0;
        v_valor    NUMBER;
        v_caracter CHAR(1);
        v_cc_limpo VARCHAR2(12);
        v_i        NUMBER := 12;
    BEGIN
        -- Limpeza e Validação básica de tamanho (Sempre ativa)
        v_cc_limpo := UPPER(REPLACE(p_cc, ' ', ''));

        IF LENGTH(v_cc_limpo) != 12 THEN 
            RETURN FALSE; 
        END IF;

        -- Se a validação rigorosa estiver desligada, termina aqui
        IF NOT PKG_CONSTANTES.VALIDACAO_RIGOROSA_CC THEN
            RETURN TRUE;
        END IF;

        -- Validação Matemática (Luhn Modulo 36)
        WHILE v_i >= 1 LOOP
            v_caracter := SUBSTR(v_cc_limpo, v_i, 1);

            IF v_caracter BETWEEN '0' AND '9' THEN
                v_valor := TO_NUMBER(v_caracter);
            ELSIF v_caracter BETWEEN 'A' AND 'Z' THEN
                v_valor := ASCII(v_caracter) - ASCII('A') + 10;
            ELSE
                RETURN FALSE;
            END IF;

            IF MOD(12 - v_i + 1, 2) = 0 THEN
                v_valor := v_valor * 2;
                IF v_valor > 35 THEN v_valor := v_valor - 35; END IF;
            END IF;

            v_soma := v_soma + v_valor;
            v_i := v_i - 1;
        END LOOP;

        RETURN (MOD(v_soma, 36) = 0);
    EXCEPTION 
        WHEN OTHERS THEN RETURN FALSE;
    END FUN_VAL_CC;

END PKG_VALIDACAO;
/