-- =============================================================================
-- TESTES DE VALIDAÇÃO E FORMATAÇÃO DE DADOS
-- Cobre: PKG_VALIDACAO, TRG_VAL_DADOS_*, TRG_FMT_*
-- =============================================================================
SET SERVEROUTPUT ON;

DECLARE
    v_sufixo VARCHAR2(10) := TO_CHAR(SYSTIMESTAMP, 'SSSSS');
    v_est_id NUMBER;
    v_cur_id NUMBER;
    v_uc_id  NUMBER;
    v_log_count NUMBER;
    
    -- Variáveis para verificação
    v_nome_check VARCHAR2(100);
    v_email_check VARCHAR2(100);
    v_cod_check VARCHAR2(20);
    
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTES DE VALIDAÇÃO E FORMATAÇÃO ===');

    -- -------------------------------------------------------------------------
    -- 1. TESTE DE FORMATAÇÃO (TRG_FMT_*)
    -- -------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('1. Testando Formatação Automática (InitCap, Lower, Upper)...');
    
    -- Inserir dados "sujos"
    INSERT INTO estudante (nome, email, data_nascimento, cc, nif, telemovel)
    VALUES ('  joao  da  silva  ', '  JOAO.SILVA@TESTE.COM  ', SYSDATE-7000, 
            SUBSTR('12345'||v_sufixo,1,12), SUBSTR('999'||v_sufixo,1,9), '910000000')
    RETURNING id INTO v_est_id;
    
    INSERT INTO unidade_curricular (nome, codigo, horas_teoricas, horas_praticas)
    VALUES ('Matematica', '  mat-101  ', 10, 10)
    RETURNING id INTO v_uc_id;

    -- Verificar
    SELECT nome, email INTO v_nome_check, v_email_check FROM estudante WHERE id = v_est_id;
    SELECT codigo INTO v_cod_check FROM unidade_curricular WHERE id = v_uc_id;

    IF v_nome_check = 'Joao Da Silva' AND v_email_check = 'joao.silva@teste.com' THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Formatação de Estudante (Nome/Email) correta.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FALHA] Formatação de Estudante incorreta: ' || v_nome_check || ' / ' || v_email_check);
    END IF;

    IF v_cod_check = 'MAT-101' THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Formatação de UC (Código Upper/Trim) correta.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FALHA] Formatação de UC incorreta: ' || v_cod_check);
    END IF;

    -- -------------------------------------------------------------------------
    -- 2. TESTE DE VALIDAÇÃO DE DADOS (CC, EMAIL, IBAN)
    -- -------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('2. Testando Validações de Dados (CC, Email, IBAN)...');

    -- Inserir dados inválidos
    INSERT INTO docente (nome, data_contratacao, cc, nif, email, telemovel, iban)
    VALUES ('Docente Teste', SYSDATE, 
            '1',                -- CC Inválido (curto)
            SUBSTR('888'||v_sufixo,1,9), 
            'email_sem_arroba', -- Email Inválido
            '930000000',
            'ES991234'          -- IBAN Inválido (não PT)
           );
           
    COMMIT; -- Persistir logs autónomos

    -- Verificar Logs
    SELECT COUNT(*) INTO v_log_count FROM log 
    WHERE acao = 'ALERTA' AND data LIKE '%CC inválido%' AND created_at > SYSDATE - 1/24;
    
    IF v_log_count > 0 THEN DBMS_OUTPUT.PUT_LINE('[OK] CC Inválido detetado.'); 
    ELSE DBMS_OUTPUT.PUT_LINE('[FALHA] CC Inválido não detetado.'); END IF;

    SELECT COUNT(*) INTO v_log_count FROM log 
    WHERE acao = 'ALERTA' AND data LIKE '%Email inválido%' AND created_at > SYSDATE - 1/24;
    
    IF v_log_count > 0 THEN DBMS_OUTPUT.PUT_LINE('[OK] Email Inválido detetado.'); 
    ELSE DBMS_OUTPUT.PUT_LINE('[FALHA] Email Inválido não detetado.'); END IF;

    SELECT COUNT(*) INTO v_log_count FROM log 
    WHERE acao = 'ALERTA' AND data LIKE '%IBAN inválido%' AND created_at > SYSDATE - 1/24;
    
    IF v_log_count > 0 THEN DBMS_OUTPUT.PUT_LINE('[OK] IBAN Inválido detetado.'); 
    ELSE DBMS_OUTPUT.PUT_LINE('[FALHA] IBAN Inválido não detetado.'); END IF;

    DBMS_OUTPUT.PUT_LINE('=== FIM DOS TESTES DE VALIDAÇÃO ===');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('ERRO CRÍTICO: ' || SQLERRM);
END;
/
