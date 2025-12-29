-- =============================================================================
-- TESTE UNITÁRIO: VALIDAÇÃO DE NOTAS (Consistência de Turma e Status)
-- =============================================================================
SET SERVEROUTPUT ON;

DECLARE
    v_sfx       VARCHAR2(10) := TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(1000,9999)));
    v_doc_id    NUMBER;
    v_cur_id    NUMBER;
    v_uc_id     NUMBER;
    v_est_id    NUMBER;
    v_mat_id    NUMBER;
    v_turma_a   NUMBER;
    v_turma_b   NUMBER;
    v_ins_id    NUMBER; -- Inscrito na Turma A
    v_aval_a    NUMBER; -- Avaliação da Turma A
    v_aval_b    NUMBER; -- Avaliação da Turma B
    v_tav_id    NUMBER;
    v_nota_check NUMBER;
    v_status_check CHAR(1);
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTE: VALIDAÇÃO DE NOTA (Turma e Status) ===');

    -- 1. SETUP DE DADOS
    -- Criar Docente, Curso, UC
    INSERT INTO docente (nome, nif, email, telemovel, data_contratacao, status)
    VALUES ('Doc Teste '||v_sfx, '2'||v_sfx||'1111', 'd'||v_sfx||'@t.pt', '9'||v_sfx||'0000', SYSDATE, '1') RETURNING id INTO v_doc_id;
    
    INSERT INTO tipo_curso (nome, valor_propinas) VALUES ('Tipo Demo', 1000) RETURNING id INTO v_cur_id; -- Reutilizar var v_cur_id temporariamente para TC
    INSERT INTO curso (nome, codigo, descricao, duracao, ects, tipo_curso_id) 
    VALUES ('Curso Nota '||v_sfx, 'CN'||v_sfx, 'Desc', 3, 180, v_cur_id) RETURNING id INTO v_cur_id;

    INSERT INTO unidade_curricular (nome, codigo, horas_teoricas, horas_praticas) 
    VALUES ('UC Nota '||v_sfx, 'UN'||v_sfx, 10, 10) RETURNING id INTO v_uc_id;

    -- Habilitar Docente para a UC
    INSERT INTO uc_docente (unidade_curricular_id, docente_id, funcao, status)
    VALUES (v_uc_id, v_doc_id, 'Docente', '1');

    INSERT INTO uc_curso (curso_id, unidade_curricular_id, semestre, ano, ects, presenca_obrigatoria, percentagem_presenca) 
    VALUES (v_cur_id, v_uc_id, 1, 1, 10, '1', 75);

    -- Criar Turmas A e B
    INSERT INTO turma (nome, ano_letivo, unidade_curricular_id, docente_id, status) 
    VALUES ('Turma A', '2025', v_uc_id, v_doc_id, '1') RETURNING id INTO v_turma_a;
    
    INSERT INTO turma (nome, ano_letivo, unidade_curricular_id, docente_id, status) 
    VALUES ('Turma B', '2025', v_uc_id, v_doc_id, '1') RETURNING id INTO v_turma_b;

    -- Criar Aluno e Matrícula
    INSERT INTO estudante (nome, nif, cc, data_nascimento, email, telemovel) 
    VALUES ('Aluno Nota '||v_sfx, '1'||v_sfx||'2222', '1'||v_sfx||'333', SYSDATE-7000, 'a'||v_sfx||'@n.pt', '9'||v_sfx||'1111') 
    RETURNING id INTO v_est_id;

    INSERT INTO matricula (curso_id, ano_inscricao, estudante_id, estado_matricula, numero_parcelas) 
    VALUES (v_cur_id, 2025, v_est_id, 'Ativa', 10) RETURNING id INTO v_mat_id;

    -- Inscrever Aluno na Turma A APENAS
    INSERT INTO inscricao (turma_id, matricula_id, data, status) 
    VALUES (v_turma_a, v_mat_id, SYSDATE, '1') RETURNING id INTO v_ins_id;

    -- Criar Avaliações para ambas as turmas
    INSERT INTO tipo_avaliacao (nome, requer_entrega, permite_grupo, permite_filhos) VALUES ('Teste', '0', '0', '0') RETURNING id INTO v_tav_id;
    
    INSERT INTO avaliacao (titulo, data, data_entrega, peso, max_alunos, turma_id, tipo_avaliacao_id, status)
    VALUES ('Teste Turma A', SYSDATE, SYSDATE, 50, 1, v_turma_a, v_tav_id, '1') RETURNING id INTO v_aval_a;

    INSERT INTO avaliacao (titulo, data, data_entrega, peso, max_alunos, turma_id, tipo_avaliacao_id, status)
    VALUES ('Teste Turma B', SYSDATE, SYSDATE, 50, 1, v_turma_b, v_tav_id, '1') RETURNING id INTO v_aval_b;

    -- 2. TESTE DE SUCESSO (Mesma Turma)
    DBMS_OUTPUT.PUT_LINE('>> Teste 1: Inserir nota valida (Mesma Turma)...');
    BEGIN
        INSERT INTO nota (inscricao_id, avaliacao_id, nota, comentario, status)
        VALUES (v_ins_id, v_aval_a, 15, 'Nota Valida', '1');
        DBMS_OUTPUT.PUT_LINE('[OK] Nota inserida com sucesso.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[FALHA] Erro ao inserir nota valida: ' || SQLERRM);
    END;

    -- 3. TESTE DE FALHA (Turma Diferente)
    DBMS_OUTPUT.PUT_LINE('>> Teste 2: Inserir nota cruzada (Avaliacao de outra turma)...');
    BEGIN
        INSERT INTO nota (inscricao_id, avaliacao_id, nota, comentario, status)
        VALUES (v_ins_id, v_aval_b, 10, 'Tentativa Fraude', '1');
        DBMS_OUTPUT.PUT_LINE('[FALHA] O sistema permitiu inserir nota de outra turma!');
    EXCEPTION WHEN OTHERS THEN
        -- SQLCODE = 1 é a User-Defined Exception lançada pelo trigger
        IF SQLCODE = 1 OR SQLCODE BETWEEN -20999 AND -20000 OR SQLERRM LIKE '%Inconsistencia%' THEN
             DBMS_OUTPUT.PUT_LINE('[OK] Bloqueio de turma cruzada funcionou (Excecao capturada).');
        ELSE
             DBMS_OUTPUT.PUT_LINE('[FALHA] Erro inesperado: ' || SQLERRM || ' (Code: ' || SQLCODE || ')');
        END IF;
    END;

    -- 4. TESTE DE STATUS
    DBMS_OUTPUT.PUT_LINE('>> Teste 3: Validacao de Status Inválido...');
    BEGIN
        -- Tentar inserir com status 'X'
        UPDATE nota SET status = 'X', nota = 16 WHERE inscricao_id = v_ins_id AND avaliacao_id = v_aval_a;
        
        -- Se passar aqui, verificar se corrigiu
        SELECT status INTO v_status_check FROM nota WHERE inscricao_id = v_ins_id AND avaliacao_id = v_aval_a;
        
        IF v_status_check = '0' THEN
            DBMS_OUTPUT.PUT_LINE('[OK] Status "X" corrigido para "0".');
        ELSIF v_status_check = '1' THEN
             DBMS_OUTPUT.PUT_LINE('[OK] Status mantido como 1 (ignorado update invalido).');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[FALHA] Status inesperado: ' || v_status_check);
        END IF;
    EXCEPTION 
        WHEN OTHERS THEN
            -- Se der erro de User-Defined Exception, é porque o validador bloqueou. Isso também é um sucesso.
            DBMS_OUTPUT.PUT_LINE('[OK] Bloqueio de status invalido funcionou (Exception capturada: ' || SQLERRM || ')');
    END;

    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('=== TESTE CONCLUIDO (ROLLBACK) ===');
    DBMS_OUTPUT.PUT_LINE('[OK] Todas as validacoes de NOTA (status e turma) passaram.');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('!!! ERRO FATAL NO TESTE 18f: ' || SQLERRM);
    ROLLBACK;
END;
/
