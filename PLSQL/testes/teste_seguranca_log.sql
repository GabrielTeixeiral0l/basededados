-- =============================================================================
-- TESTE DE SEGURANÇA DE LOGS
-- Verifica se a tabela LOG é imutável (impede DELETE e UPDATE).
-- =============================================================================

SET SERVEROUTPUT ON;

DECLARE
    v_log_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTE DE SEGURANÇA DE LOGS ===');

    -- 1. Inserir um log de teste (INSERT é permitido)
    -- Chave primária ID deve ser gerada por trigger ou sequência conforme 1_auto_increment.sql
    INSERT INTO log (acao, tabela, data)
    VALUES ('TESTE_SEGURANCA', 'TESTE', 'Teste de imutabilidade')
    RETURNING id INTO v_log_id;
    
    DBMS_OUTPUT.PUT_LINE('[OK] Insert no LOG permitido. ID: ' || v_log_id);

    -- 2. Tentar UPDATE (Deve falhar)
    BEGIN
        UPDATE log SET acao = 'HACKED' WHERE id = v_log_id;
        DBMS_OUTPUT.PUT_LINE('[FALHA] UPDATE no LOG foi permitido!');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE = 1 THEN 
            DBMS_OUTPUT.PUT_LINE('[OK] UPDATE bloqueado por imutabilidade.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[ERRO] UPDATE bloqueado, mas com erro inesperado: ' || SQLERRM);
        END IF;
    END;

    -- 3. Tentar DELETE (Deve falhar)
    BEGIN
        DELETE FROM log WHERE id = v_log_id;
        DBMS_OUTPUT.PUT_LINE('[FALHA] DELETE no LOG foi permitido!');
    EXCEPTION WHEN OTHERS THEN
        IF SQLCODE = 1 THEN
            DBMS_OUTPUT.PUT_LINE('[OK] DELETE bloqueado por imutabilidade.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[ERRO] DELETE bloqueado, mas com erro inesperado: ' || SQLERRM);
        END IF;
    END;

    DBMS_OUTPUT.PUT_LINE('=== TESTE DE SEGURANÇA CONCLUÍDO ===');
END;
/
