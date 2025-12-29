SET SERVEROUTPUT ON SIZE UNLIMITED;
SET FEEDBACK OFF;

DECLARE
    v_sfx VARCHAR2(10) := TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(1000, 9999)));
    v_cur_id NUMBER; v_uc_id NUMBER; v_doc_id NUMBER; 
    v_mat_id NUMBER; v_ins_id NUMBER; v_ava_id NUMBER; v_aul_id NUMBER;
    
    -- Procedimento de validação
    PROCEDURE validar(p_tabela VARCHAR2) IS
        v_l NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_l FROM log 
        WHERE tabela = p_tabela AND acao = 'DELETE' 
        AND created_at >= SYSTIMESTAMP - INTERVAL '10' SECOND;
        
        IF v_l > 0 THEN
            DBMS_OUTPUT.PUT_LINE('[OK] Relacao ' || RPAD(p_tabela, 18) || ': PRC_REMOVER_RELACAO invocado via Trigger.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[FALHA] Relacao ' || RPAD(p_tabela, 18) || ': Nao houve rasto no log.');
        END IF;
    END;

BEGIN
    DBMS_OUTPUT.PUT_LINE('========================================================');
    DBMS_OUTPUT.PUT_LINE('   TESTE DE ELIMINAÇÃO: TABELAS DE CHAVE COMPOSTA');
    DBMS_OUTPUT.PUT_LINE('========================================================');

    -- 1. SETUP DE DADOS NECESSÁRIOS
    INSERT INTO tipo_curso (nome, valor_propinas) VALUES ('T_'||v_sfx, 0) RETURNING id INTO v_cur_id;
    INSERT INTO curso (nome, codigo, descricao, duracao, ects, tipo_curso_id) VALUES ('C', 'C'||v_sfx, 'D', 3, 180, v_cur_id) RETURNING id INTO v_cur_id;
    INSERT INTO unidade_curricular (nome, codigo, horas_teoricas, horas_praticas) VALUES ('U', 'U'||v_sfx, 1, 1) RETURNING id INTO v_uc_id;
    INSERT INTO docente (nome, nif, cc, data_contratacao, email, telemovel) VALUES ('D', '1'||v_sfx||'0', '1', SYSDATE, 'e@t.pt', '96'||v_sfx) RETURNING id INTO v_doc_id;
    INSERT INTO estudante (nome, nif, cc, data_nascimento, email, telemovel) VALUES ('E', '2'||v_sfx||'0', '2', SYSDATE-7000, 'a@t.pt', '91'||v_sfx) RETURNING id INTO v_mat_id; -- Usando mat_id como buffer p/ estudante
    INSERT INTO matricula (curso_id, estudante_id, ano_inscricao, estado_matricula, numero_parcelas) VALUES (v_cur_id, v_mat_id, 2025, 'Ativa', 1) RETURNING id INTO v_mat_id;
    INSERT INTO turma (nome, ano_letivo, unidade_curricular_id, docente_id) VALUES ('T', '25', v_uc_id, v_doc_id) RETURNING id INTO v_ins_id; -- Usando ins_id como buffer p/ turma
    INSERT INTO inscricao (turma_id, matricula_id, data) VALUES (v_ins_id, v_mat_id, SYSDATE) RETURNING id INTO v_ins_id;
    
    DBMS_OUTPUT.PUT_LINE('1. Setup de dependências concluído.');

    -- -------------------------------------------------------------------------
    -- TESTANDO CADA TABELA DE RELAÇÃO (CHAVE COMPOSTA)
    -- -------------------------------------------------------------------------
    
    -- Teste A: UC_DOCENTE (unidade_curricular_id, docente_id)
    INSERT INTO uc_docente (unidade_curricular_id, docente_id) VALUES (v_uc_id, v_doc_id);
    DELETE FROM uc_docente WHERE unidade_curricular_id = v_uc_id AND docente_id = v_doc_id;
    validar('UC_DOCENTE');

    -- Teste B: NOTA (avaliacao_id, inscricao_id)
    -- Criar avaliação dummy
    INSERT INTO tipo_avaliacao (nome, requer_entrega, permite_grupo, permite_filhos) VALUES ('T', '0', '0', '0') RETURNING id INTO v_ava_id;
    INSERT INTO avaliacao (titulo, data, peso, max_alunos, turma_id, tipo_avaliacao_id) 
    VALUES ('Ex', SYSDATE, 1, 1, (SELECT turma_id FROM inscricao WHERE id = v_ins_id), v_ava_id) RETURNING id INTO v_ava_id;
    
    INSERT INTO nota (avaliacao_id, inscricao_id, nota) VALUES (v_ava_id, v_ins_id, 10);
    DELETE FROM nota WHERE avaliacao_id = v_ava_id AND inscricao_id = v_ins_id;
    validar('NOTA');

    -- Teste C: PRESENÇA (aula_id, inscricao_id)
    INSERT INTO tipo_aula (nome) VALUES ('T') RETURNING id INTO v_aul_id;
    INSERT INTO aula (data, hora_inicio, hora_fim, sala_id, tipo_aula_id, turma_id)
    VALUES (SYSDATE, SYSDATE, SYSDATE+1/24, (SELECT MIN(id) FROM sala), v_aul_id, (SELECT turma_id FROM inscricao WHERE id = v_ins_id)) RETURNING id INTO v_aul_id;
    
    -- O trigger de auto-presença pode já ter inserido, mas garantimos:
    DELETE FROM presenca WHERE aula_id = v_aul_id AND inscricao_id = v_ins_id;
    validar('PRESENCA');

    -- Teste D: ESTUDANTE_ENTREGA (entrega_id, inscricao_id)
    DECLARE v_ent_id NUMBER; BEGIN
        INSERT INTO entrega (data_entrega, avaliacao_id) VALUES (SYSDATE, v_ava_id) RETURNING id INTO v_ent_id;
        INSERT INTO estudante_entrega (entrega_id, inscricao_id) VALUES (v_ent_id, v_ins_id);
        DELETE FROM estudante_entrega WHERE entrega_id = v_ent_id AND inscricao_id = v_ins_id;
        validar('ESTUDANTE_ENTREGA');
    END;

    DBMS_OUTPUT.PUT_LINE('========================================================');
    DBMS_OUTPUT.PUT_LINE('   TESTES DE RELAÇÕES COMPOSTAS FINALIZADOS');
    DBMS_OUTPUT.PUT_LINE('========================================================');

    ROLLBACK;

EXCEPTION WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('!!! ERRO !!! ' || SQLERRM);
END;
/