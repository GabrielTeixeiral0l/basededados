CREATE OR REPLACE PACKAGE PKG_GESTAO_DADOS IS
    -- Procedimento para remover registos de forma inteligente
    PROCEDURE PRC_REMOVER(
        p_nome_tabela      IN VARCHAR2,
        p_id_registo       IN NUMBER,
        p_forcar_hard      IN BOOLEAN DEFAULT FALSE
    );
END PKG_GESTAO_DADOS;
/

CREATE OR REPLACE PACKAGE BODY PKG_GESTAO_DADOS IS
    PROCEDURE PRC_REMOVER(
        p_nome_tabela      IN VARCHAR2,
        p_id_registo       IN NUMBER,
        p_forcar_hard      IN BOOLEAN DEFAULT FALSE
    ) IS
        v_count NUMBER;
        v_sql   VARCHAR2(500);
    BEGIN
        -- 1. Verificar se a coluna 'status' existe na tabela
        SELECT COUNT(*)
        INTO v_count
        FROM USER_TAB_COLUMNS
        WHERE TABLE_NAME = UPPER(p_nome_tabela)
          AND COLUMN_NAME = 'STATUS';

        -- 2. Decidir o tipo de remoção
        IF v_count > 0 AND NOT p_forcar_hard THEN
            -- Soft Delete
            v_sql := 'UPDATE ' || p_nome_tabela || ' SET status = ''0'', updated_at = SYSDATE WHERE id = :1';
            EXECUTE IMMEDIATE v_sql USING p_id_registo;
            
            IF SQL%ROWCOUNT = 0 THEN
                PKG_ERROS.RAISE_ERROR(PKG_ERROS.ERR_NAO_ENCONTRADO_CODE);
            END IF;
        ELSE
            -- Hard Delete
            v_sql := 'DELETE FROM ' || p_nome_tabela || ' WHERE id = :1';
            EXECUTE IMMEDIATE v_sql USING p_id_registo;

            IF SQL%ROWCOUNT = 0 THEN
                PKG_ERROS.RAISE_ERROR(PKG_ERROS.ERR_NAO_ENCONTRADO_CODE);
            END IF;
        END IF;
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END PRC_REMOVER;
END PKG_GESTAO_DADOS;
/
