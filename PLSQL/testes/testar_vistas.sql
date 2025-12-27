-- =============================================================================
-- TESTE DE VISTAS E RELATÓRIOS
-- Valida se as vistas VW_PAUTA_TURMA e VW_ALERTA_ASSIDUIDADE funcionam.
-- =============================================================================

SET SERVEROUTPUT ON;

DECLARE
    v_uc_id  NUMBER;
    v_tur_id NUMBER;
    v_mat_id NUMBER;
    v_ins_id NUMBER;
    v_est_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTE DE VISTAS ===');

    -- Obter um estudante existente
    SELECT id INTO v_est_id FROM (SELECT id FROM estudante ORDER BY id) WHERE ROWNUM = 1;

    -- 1. Criar dados para teste
    v_uc_id := seq_unidade_curricular.NEXTVAL;
    INSERT INTO unidade_curricular (id, nome, codigo, horas_teoricas, horas_praticas) 
    VALUES (v_uc_id, 'VISTA_UC_'||v_uc_id, 'VUC'||v_uc_id, 10, 10);

    v_tur_id := seq_turma.NEXTVAL;
    INSERT INTO turma (id, nome, ano_letivo, unidade_curricular_id, docente_id)
    VALUES (v_tur_id, 'T_'||v_tur_id, '2025/26', v_uc_id, 1);

    -- Criar Matrícula e Inscrição
    v_mat_id := seq_matricula.NEXTVAL;
    INSERT INTO matricula (id, curso_id, ano_inscricao, estado_matricula_id, estudante_id, numero_parcelas)
    VALUES (v_mat_id, 1, 2025, 1, v_est_id, 10);

    v_ins_id := seq_inscricao.NEXTVAL;
    INSERT INTO inscricao (id, turma_id, matricula_id, data)
    VALUES (v_ins_id, v_tur_id, v_mat_id, SYSDATE);

    -- Criar Aulas e Faltas (Simular 50% de faltas)
    FOR i IN 1..4 LOOP
        DECLARE
            v_aula_id NUMBER := seq_aula.NEXTVAL;
        BEGIN
            INSERT INTO aula (id, data, hora_inicio, hora_fim, sumario, sala_id, tipo_aula_id, turma_id)
            VALUES (v_aula_id, SYSDATE-i, SYSDATE, SYSDATE, 'Aula Teste '||i, 1, 1, v_tur_id);
            
            -- Limpar presenças anteriores (caso existam por algum motivo bizarro de cache de seq)
            DELETE FROM presenca WHERE aula_id = v_aula_id AND inscricao_id = v_ins_id;

            -- Presente em 2, Falta em 2
            IF i <= 2 THEN
                INSERT INTO presenca (aula_id, inscricao_id, presente) VALUES (v_aula_id, v_ins_id, '1');
            ELSE
                INSERT INTO presenca (aula_id, inscricao_id, presente) VALUES (v_aula_id, v_ins_id, '0');
            END IF;
        END;
    END LOOP;

    COMMIT;

    -- 2. Consultar Relatório de Assiduidade
    DBMS_OUTPUT.PUT_LINE('RELATORIO DE ASSIDUIDADE (Esperado Aluno com 50% Faltas):');
    -- Forçar a vista a atualizar ou verificar diretamente os dados recém criados
    FOR r IN (SELECT * FROM VW_ALERTA_ASSIDUIDADE WHERE nome_turma = 'T_'||v_tur_id) LOOP
        DBMS_OUTPUT.PUT_LINE('ALUNO: ' || r.nome_estudante || ' | FALTAS: ' || r.perc_faltas || '%');
    END LOOP;

    -- 3. Consultar Pauta
    DBMS_OUTPUT.PUT_LINE('CONSULTANDO PAUTA DA TURMA:');
    FOR p IN (SELECT * FROM VW_PAUTA_TURMA WHERE turma = 'T_'||v_tur_id) LOOP
        DBMS_OUTPUT.PUT_LINE('ALUNO: ' || p.nome_estudante || ' | RESULTADO: ' || p.resultado);
    END LOOP;

EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('ERRO NOS TESTES DE VISTAS: ' || SQLERRM);
END;
/