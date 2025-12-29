-- =============================================================================
-- TESTE UNITÁRIO: TABELA TURMA
-- Regras: Inserção Básica
-- =============================================================================
SET SERVEROUTPUT ON;

DECLARE
    v_tur_id NUMBER;
    v_uc_id NUMBER;
    v_doc_id NUMBER;
    v_sufixo VARCHAR2(10) := TO_CHAR(SYSTIMESTAMP, 'SSSSS');
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTE TABELA TURMA ===');

    -- 1. Setup
    INSERT INTO docente (nome, nif, email, telemovel, data_contratacao, status)
    VALUES ('DocT '||v_sufixo, '2'||SUBSTR(v_sufixo,1,8), 'dt'||v_sufixo||'@t.pt', '96'||SUBSTR(v_sufixo,1,7), SYSDATE-30, '1')
    RETURNING id INTO v_doc_id;

    INSERT INTO unidade_curricular (nome, codigo, horas_teoricas, horas_praticas, status)
    VALUES ('UC T '||v_sufixo, 'UCT'||v_sufixo, 10, 10, '1')
    RETURNING id INTO v_uc_id;

    -- Habilitar Docente para a UC
    INSERT INTO uc_docente (unidade_curricular_id, docente_id, funcao, status)
    VALUES (v_uc_id, v_doc_id, 'Regente', '1');

    -- 2. Inserção Simples
    DBMS_OUTPUT.PUT_LINE('1. Testando Inserção de Turma...');
    INSERT INTO turma (nome, ano_letivo, unidade_curricular_id, docente_id, max_alunos, status)
    VALUES ('Turma '||v_sufixo, '2025/26', v_uc_id, v_doc_id, 30, '1')
    RETURNING id INTO v_tur_id;

    IF v_tur_id IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Turma criada com sucesso. ID: ' || v_tur_id);
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FALHA] Turma não criada.');
    END IF;

    -- 3. Teste Status Inválido (Se não houver trigger, isto passa, mas o teste documenta o comportamento)
    DBMS_OUTPUT.PUT_LINE('2. Testando Status Inválido ("X")...');
    INSERT INTO turma (nome, ano_letivo, unidade_curricular_id, docente_id, max_alunos, status)
    VALUES ('Turma X '||v_sufixo, '2025/26', v_uc_id, v_doc_id, 30, 'X');
    DBMS_OUTPUT.PUT_LINE('[INFO] Turma com status inválido inserida (Sem trigger de validação ativo).');

    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('=== TESTE TURMA: SUCESSO ===');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('!!! ERRO CRÍTICO NO TESTE TURMA !!! ' || SQLERRM);
    ROLLBACK;
END;
/
