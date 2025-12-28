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
    
    -- Inserir dados "sujos" mas VÁLIDOS (para passar na integridade)
    -- Usando NIF válido conhecido do DML e idade > 18
    BEGIN
        INSERT INTO estudante (nome, email, data_nascimento, cc, nif, telemovel, iban)
        VALUES ('  joao  da  silva  ', 'JOAO.SILVA@TESTE.COM', ADD_MONTHS(SYSDATE, -12*20), -- 20 anos
                '12345678', '275730972', '910000000', 'PT50000000000000000000000')
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
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[ERRO NO TESTE 1] Inserção falhou devido a validação: ' || SQLERRM);
    END;

    -- -------------------------------------------------------------------------
    -- 2. TESTE DE VALIDAÇÃO DE DADOS (CC, EMAIL, IBAN)
    -- -------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('2. Testando Validações de Dados (CC, Email, IBAN) individualmente...');

    -- 2.1 Teste CC Inválido
    BEGIN
        INSERT INTO docente (nome, data_contratacao, cc, nif, email, telemovel, iban)
        VALUES ('Docente CC Inv', SYSDATE, 
                '1',                -- INVÁLIDO
                '275730972',        -- Válido (Golden NIF)
                'doc.cc@teste.com', -- Válido
                '930000000',
                'PT50000000000000000000000');
        DBMS_OUTPUT.PUT_LINE('[FALHA] CC Inválido foi permitido!');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[OK] CC Inválido bloqueado.');
    END;
    
    SELECT COUNT(*) INTO v_log_count FROM log WHERE acao = 'ERRO' AND data LIKE '%CC inv_lido%';
    IF v_log_count > 0 THEN DBMS_OUTPUT.PUT_LINE('[OK] Log de CC detetado.'); ELSE DBMS_OUTPUT.PUT_LINE('[FALHA] Log de CC não detetado.'); END IF;

    -- 2.2 Teste Email Inválido
    BEGIN
        INSERT INTO docente (nome, data_contratacao, cc, nif, email, telemovel, iban)
        VALUES ('Docente Email Inv', SYSDATE, 
                '12345678',         -- Válido
                '275730972',        -- Válido (Golden NIF)
                'email_sem_arroba', -- INVÁLIDO
                '930000000',
                'PT50000000000000000000000');
        DBMS_OUTPUT.PUT_LINE('[FALHA] Email Inválido foi permitido!');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Email Inválido bloqueado.');
    END;

    SELECT COUNT(*) INTO v_log_count FROM log WHERE acao = 'ERRO' AND data LIKE '%Email inv_lido%';
    IF v_log_count > 0 THEN DBMS_OUTPUT.PUT_LINE('[OK] Log de Email detetado.'); ELSE DBMS_OUTPUT.PUT_LINE('[FALHA] Log de Email não detetado.'); END IF;

    -- 2.3 Teste IBAN Inválido
    BEGIN
        INSERT INTO docente (nome, data_contratacao, cc, nif, email, telemovel, iban)
        VALUES ('Docente IBAN Inv', SYSDATE, 
                '87654321',         -- Válido
                '275730972',        -- Válido (Golden NIF)
                'doc.iban@teste.com', -- Válido
                '930000000',
                'ES991234'          -- INVÁLIDO
               );
        DBMS_OUTPUT.PUT_LINE('[FALHA] IBAN Inválido foi permitido!');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[OK] IBAN Inválido bloqueado.');
    END;

    SELECT COUNT(*) INTO v_log_count FROM log WHERE acao = 'ERRO' AND data LIKE '%IBAN inv%';
    IF v_log_count > 0 THEN DBMS_OUTPUT.PUT_LINE('[OK] Log de IBAN detetado.'); ELSE DBMS_OUTPUT.PUT_LINE('[FALHA] Log de IBAN não detetado.'); END IF;

    DBMS_OUTPUT.PUT_LINE('=== FIM DOS TESTES DE VALIDAÇÃO ===');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('ERRO CRÍTICO: ' || SQLERRM);
END;
/
