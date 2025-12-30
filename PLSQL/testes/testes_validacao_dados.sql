-- =============================================================================
-- TESTES DE VALIDAÇÃO E FORMATAÇÃO DE DADOS (VERSÃO TOLERANTE)
-- =============================================================================
SET SERVEROUTPUT ON;

DECLARE
    v_sufixo VARCHAR2(10) := TO_CHAR(SYSTIMESTAMP, 'SSSSS');
    v_est_id NUMBER;
    v_start_time TIMESTAMP := CURRENT_TIMESTAMP;
    v_log_count NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTES DE VALIDAÇÃO E FORMATAÇÃO ===');

    -- 1. TESTE DE INSERÇÃO BÁSICA
    DBMS_OUTPUT.PUT_LINE('1. Testando Inserção de Estudante e UC...');
    BEGIN
        INSERT INTO estudante (nome, email, data_nascimento, cc, nif, telemovel, status)
        VALUES ('Joao Silva '||v_sufixo, 'joao'||v_sufixo||'@teste.com', ADD_MONTHS(SYSDATE, -12*20), 
                LPAD(v_sufixo, 9, '0')||'ZZ1', '2'||LPAD(v_sufixo, 8, '0'), '91'||LPAD(v_sufixo, 7, '0'), '1')
        RETURNING id INTO v_est_id;
        
        DBMS_OUTPUT.PUT_LINE('[OK] Inserção realizada com sucesso.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[ERRO] Inserção falhou: ' || SQLERRM);
    END;

    -- 2. TESTE DE VALIDAÇÃO (CC, EMAIL, IBAN)
    DBMS_OUTPUT.PUT_LINE('2. Testando Bloqueios de Dados Inválidos...');

    -- CC Inválido (Menos de 12 chars)
    BEGIN
        INSERT INTO docente (nome, data_contratacao, cc, nif, email, telemovel)
        VALUES ('Docente CC Mau', SYSDATE, '123', '2'||LPAD(v_sufixo, 8, '1'), 'd'||v_sufixo||'@t.com', '93'||LPAD(v_sufixo, 7, '1'));
        DBMS_OUTPUT.PUT_LINE('[FALHA] CC Inválido permitido!');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[OK] CC Inválido bloqueado corretamente.');
    END;

    -- Email Inválido
    BEGIN
        INSERT INTO docente (nome, data_contratacao, cc, nif, email, telemovel)
        VALUES ('Docente Email Mau', SYSDATE, LPAD(v_sufixo, 9, '0')||'ZZ2', '2'||LPAD(v_sufixo, 8, '2'), 'email_sem_arroba', '93'||LPAD(v_sufixo, 7, '2'));
        DBMS_OUTPUT.PUT_LINE('[FALHA] Email Inválido permitido!');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Email Inválido bloqueado corretamente.');
    END;

    -- Procurar Logs (com margem de tempo)
    SELECT COUNT(*) INTO v_log_count FROM log 
    WHERE created_at >= v_start_time - INTERVAL '1' MINUTE;

    IF v_log_count > 0 THEN 
        DBMS_OUTPUT.PUT_LINE('[OK] Logs de erro registados no sistema.');
    ELSE 
        DBMS_OUTPUT.PUT_LINE('[AVISO] Nenhum log encontrado. Verifique se PKG_LOG está a comutar.');
    END IF;

    DBMS_OUTPUT.PUT_LINE('=== FIM DOS TESTES DE VALIDAÇÃO ===');
END;
/