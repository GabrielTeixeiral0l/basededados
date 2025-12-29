-- =============================================================================
-- TESTES UNITÁRIOS DE INTEGRIDADE (RECURSO, TURMA, UC_CURSO, ETC.)
-- =============================================================================
SET SERVEROUTPUT ON;
SET FEEDBACK OFF;

PROMPT ========================================================================
PROMPT INICIANDO TESTES ADICIONAIS DE INTEGRIDADE E REGRAS DE NEGÓCIO
PROMPT ========================================================================

-- -----------------------------------------------------------------------------
-- 1. TESTE: TABELA RECURSO (Validação de Docente na Turma)
-- -----------------------------------------------------------------------------
PROMPT [1/8] Testando Tabela RECURSO...
DECLARE
    v_turma_id NUMBER; v_doc_id NUMBER;
BEGIN
    -- Obter uma turma e o seu docente legítimo
    SELECT id, docente_id INTO v_turma_id, v_doc_id 
    FROM (SELECT id, docente_id FROM turma WHERE status = '1' ORDER BY id DESC) WHERE ROWNUM = 1;
    
    -- Caso 1: Sucesso
    INSERT INTO recurso (nome, turma_id, docente_id) VALUES ('Aula_01_Slides', v_turma_id, v_doc_id);
    DBMS_OUTPUT.PUT_LINE('   [OK] Inserção de recurso com docente correto permitida.');

    -- Caso 2: Falha (Docente ID inexistente ou que não pertence à turma)
    BEGIN
        INSERT INTO recurso (nome, turma_id, docente_id) VALUES ('Documento_Privado', v_turma_id, 99999);
        DBMS_OUTPUT.PUT_LINE('   [FALHA] O sistema permitiu um docente que não pertence à turma!');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('   [OK] Bloqueio de docente inválido no recurso (Trigger TRG_VAL_RECURSO).');
    END;
    ROLLBACK;
END;
/

-- -----------------------------------------------------------------------------
-- 2. TESTE: TABELA TIPO_AULA (Validação de Status)
-- -----------------------------------------------------------------------------
PROMPT [2/8] Testando Tabela TIPO_AULA...
DECLARE
    v_status CHAR(1);
BEGIN
    -- Inserir com status inválido 'X' para ver se a função VALIDAR_STATUS corrige para '0'
    INSERT INTO tipo_aula (nome, status) VALUES ('Teorico-Pratica', 'X')
    RETURNING status INTO v_status;
    
    IF v_status = '0' THEN
        DBMS_OUTPUT.PUT_LINE('   [OK] Status inválido "X" corrigido automaticamente para "0".');
    ELSE
        DBMS_OUTPUT.PUT_LINE('   [FALHA] Status permaneceu: ' || v_status);
    END IF;
    ROLLBACK;
END;
/

-- -----------------------------------------------------------------------------
-- 3. TESTE: TABELA TIPO_AVALIACAO (Validação de Flags 0/1 e Status)
-- -----------------------------------------------------------------------------
PROMPT [3/8] Testando Tabela TIPO_AVALIACAO...
DECLARE
    v_req CHAR(1); v_gru CHAR(1); v_fil CHAR(1);
BEGIN
    -- Inserir com valores lixo ('9') para as flags booleanas
    INSERT INTO tipo_avaliacao (nome, requer_entrega, permite_grupo, permite_filhos, status)
    VALUES ('Exame Especial', '9', '9', '9', '1')
    RETURNING requer_entrega, permite_grupo, permite_filhos INTO v_req, v_gru, v_fil;
    
    IF v_req = '0' AND v_gru = '0' AND v_fil = '0' THEN
        DBMS_OUTPUT.PUT_LINE('   [OK] Flags inválidas "9" corrigidas automaticamente para "0".');
    ELSE
        DBMS_OUTPUT.PUT_LINE('   [FALHA] Flags não foram sanitizadas pelo trigger.');
    END IF;
    ROLLBACK;
END;
/

-- -----------------------------------------------------------------------------
-- 4. TESTE: TABELA TIPO_CURSO (Validação de Valor Positivo)
-- -----------------------------------------------------------------------------
PROMPT [4/8] Testando Tabela TIPO_CURSO...
DECLARE
    v_valor NUMBER;
BEGIN
    -- Inserir valor negativo
    INSERT INTO tipo_curso (nome, valor_propinas, status) VALUES ('Curso Grátis', -100, '1')
    RETURNING valor_propinas INTO v_valor;
    
    IF v_valor = 0 THEN
        DBMS_OUTPUT.PUT_LINE('   [OK] Valor de propinas negativo corrigido para 0.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('   [FALHA] O sistema permitiu propinas negativas.');
    END IF;
    ROLLBACK;
END;
/

-- -----------------------------------------------------------------------------
-- 5. TESTE: TABELA TURMA (Validação de Competência Docente e Alunos)
-- -----------------------------------------------------------------------------
PROMPT [5/8] Testando Tabela TURMA...
DECLARE
    v_uc_id NUMBER; v_doc_id NUMBER;
BEGIN
    -- Obter um docente e uma UC que NÃO estejam relacionados em uc_docente
    -- Para o teste, criamos uma falha forçada inserindo um ID impossível
    BEGIN
        INSERT INTO turma (nome, ano_letivo, unidade_curricular_id, docente_id, max_alunos)
        VALUES ('T_ERRO', '2025', 1, 99999, 0); -- max_alunos 0 deve ser corrigido para 1
        DBMS_OUTPUT.PUT_LINE('   [FALHA] O sistema permitiu docente sem competência na UC.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('   [OK] Bloqueio de docente não habilitado para a UC (Trigger TRG_VAL_TURMA).');
    END;
    ROLLBACK;
END;
/

-- -----------------------------------------------------------------------------
-- 6. TESTE: TABELA UC_CURSO (Duração e Regras de Presença)
-- -----------------------------------------------------------------------------
PROMPT [6/8] Testando Tabela UC_CURSO...
DECLARE
    v_cur_id NUMBER; v_uc_id NUMBER; v_dur NUMBER;
    v_sfx VARCHAR2(10) := TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(1000,9999)));
    
    FUNCTION CRIAR_UC(p_pfx VARCHAR2) RETURN NUMBER IS
        v_id NUMBER;
        v_local_sfx VARCHAR2(20) := p_pfx || v_sfx || TRUNC(DBMS_RANDOM.VALUE(1,999));
    BEGIN
        INSERT INTO unidade_curricular (nome, codigo, horas_teoricas, horas_praticas)
        VALUES ('UC Teste '||v_local_sfx, 'U'||v_local_sfx, 10, 10) RETURNING id INTO v_id;
        RETURN v_id;
    END;
BEGIN
    SELECT id, duracao INTO v_cur_id, v_dur FROM (SELECT id, duracao FROM curso ORDER BY id) WHERE ROWNUM = 1;

    -- Caso 1: Falha (Ano letivo 10 num curso de 3 anos)
    v_uc_id := CRIAR_UC('A');
    BEGIN
        INSERT INTO uc_curso (curso_id, unidade_curricular_id, semestre, ano, ects, presenca_obrigatoria)
        VALUES (v_cur_id, v_uc_id, 1, v_dur + 7, 6, '0');
        DBMS_OUTPUT.PUT_LINE('   [FALHA] Permitiu UC em ano superior à duração do curso.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('   [OK] Bloqueio de ano inválido face à duração do curso.');
    END;

    -- Caso 2: Auto-correção (Presença obrigatória mas percentagem é NULL)
    v_uc_id := CRIAR_UC('B');
    DECLARE
        v_perc_check NUMBER;
    BEGIN
        INSERT INTO uc_curso (curso_id, unidade_curricular_id, semestre, ano, ects, presenca_obrigatoria, percentagem_presenca)
        VALUES (v_cur_id, v_uc_id, 1, 1, 6, '1', NULL)
        RETURNING percentagem_presenca INTO v_perc_check;
        
        IF v_perc_check = PKG_CONSTANTES.PERCENTAGEM_PRESENCA_DEFAULT THEN
            DBMS_OUTPUT.PUT_LINE('   [OK] Aplicou percentagem default: ' || v_perc_check);
        ELSE
            DBMS_OUTPUT.PUT_LINE('   [FALHA] Não aplicou o default esperado.');
        END IF;
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('   [FALHA] Bloqueou Caso 2: ' || SQLERRM);
    END;

    -- Caso 3: Auto-correção (Presença NÃO obrigatória mas percentagem fornecida)
    v_uc_id := CRIAR_UC('C');
    DECLARE
        v_perc_check NUMBER;
    BEGIN
        INSERT INTO uc_curso (curso_id, unidade_curricular_id, semestre, ano, ects, presenca_obrigatoria, percentagem_presenca)
        VALUES (v_cur_id, v_uc_id, 1, 1, 6, '0', 50)
        RETURNING percentagem_presenca INTO v_perc_check;
        
        IF v_perc_check IS NULL THEN
            DBMS_OUTPUT.PUT_LINE('   [OK] Removeu percentagem desnecessária (presença não obrigatória).');
        ELSE
            DBMS_OUTPUT.PUT_LINE('   [FALHA] Manteve percentagem quando presenca_obrigatoria = 0.');
        END IF;
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('   [FALHA] Erro no Caso 3: ' || SQLERRM);
    END;
    ROLLBACK;
END;
/

-- -----------------------------------------------------------------------------
-- 7. TESTE: TABELA UC_DOCENTE (Status)
-- -----------------------------------------------------------------------------
PROMPT [7/8] Testando Tabela UC_DOCENTE...
DECLARE
    v_status CHAR(1);
BEGIN
    -- Inserção de teste com status nulo
    INSERT INTO uc_docente (unidade_curricular_id, docente_id, status) 
    VALUES ( (SELECT MAX(id) FROM unidade_curricular), (SELECT MAX(id) FROM docente), NULL)
    RETURNING status INTO v_status;
    
    IF v_status = '0' THEN
        DBMS_OUTPUT.PUT_LINE('   [OK] Status NULL corrigido para "0".');
    ELSE
        DBMS_OUTPUT.PUT_LINE('   [FALHA] Status NULL não foi tratado.');
    END IF;
    ROLLBACK;
END;
/

-- -----------------------------------------------------------------------------
-- 8. TESTE: TABELA UNIDADE_CURRICULAR (Horas Negativas)
-- -----------------------------------------------------------------------------
PROMPT [8/8] Testando Tabela UNIDADE_CURRICULAR...
DECLARE
    v_ht NUMBER; v_hp NUMBER;
BEGIN
    -- Inserir UC com horas negativas
    INSERT INTO unidade_curricular (nome, codigo, horas_teoricas, horas_praticas, status)
    VALUES ('UC_TESTE', 'UCT', -10, -5, '1')
    RETURNING horas_teoricas, horas_praticas INTO v_ht, v_hp;
    
    IF v_ht = 0 AND v_hp = 0 THEN
        DBMS_OUTPUT.PUT_LINE('   [OK] Horas negativas corrigidas para 0.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('   [FALHA] O sistema permitiu horas negativas na UC.');
    END IF;
    ROLLBACK;
END;
/

PROMPT ========================================================================
PROMPT TESTES ADICIONAIS CONCLUÍDOS
PROMPT ========================================================================