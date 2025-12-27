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
    v_aula_id NUMBER;
    
    CURSOR c_assiduidade IS 
        SELECT nome_estudante, perc_faltas FROM VW_ALERTA_ASSIDUIDADE WHERE nome_turma = 'T_'||v_tur_id;
    v_reg_assiduidade c_assiduidade%ROWTYPE;

    CURSOR c_pauta IS 
        SELECT nome_estudante, resultado FROM VW_PAUTA_TURMA WHERE turma = 'T_'||v_tur_id;
    v_reg_pauta c_pauta%ROWTYPE;

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
    INSERT INTO matricula (id, curso_id, ano_inscricao, estado_matricula, estudante_id, numero_parcelas)
    VALUES (v_mat_id, 1, 2025, 'Ativa', v_est_id, 10);

    v_ins_id := seq_inscricao.NEXTVAL;
    INSERT INTO inscricao (id, turma_id, matricula_id, data)
    VALUES (v_ins_id, v_tur_id, v_mat_id, SYSDATE);

    -- Criar Aulas e Faltas (Simular 50% de faltas)
    FOR i IN 1..4 LOOP
        v_aula_id := seq_aula.NEXTVAL;
        INSERT INTO aula (id, data, hora_inicio, hora_fim, sumario, sala_id, tipo_aula_id, turma_id)
        VALUES (v_aula_id, SYSDATE-i, SYSDATE, SYSDATE, 'Aula Teste '||i, 1, 1, v_tur_id);
        
        -- Limpar presenças anteriores
        DELETE FROM presenca WHERE aula_id = v_aula_id AND inscricao_id = v_ins_id;

        -- Presente em 2, Falta em 2
        IF i <= 2 THEN
            INSERT INTO presenca (aula_id, inscricao_id, presente) VALUES (v_aula_id, v_ins_id, '1');
        ELSE
            INSERT INTO presenca (aula_id, inscricao_id, presente) VALUES (v_aula_id, v_ins_id, '0');
        END IF;
    END LOOP;

    COMMIT;

    -- 2. Consultar Relatório de Assiduidade
    DBMS_OUTPUT.PUT_LINE('RELATORIO DE ASSIDUIDADE (Esperado Aluno com 50% Faltas):');
    OPEN c_assiduidade;
    LOOP
        FETCH c_assiduidade INTO v_reg_assiduidade;
        EXIT WHEN c_assiduidade%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('ALUNO: ' || v_reg_assiduidade.nome_estudante || ' | FALTAS: ' || v_reg_assiduidade.perc_faltas || '%');
    END LOOP;
    CLOSE c_assiduidade;

    -- 3. Consultar Pauta
    DBMS_OUTPUT.PUT_LINE('CONSULTANDO PAUTA DA TURMA:');
    OPEN c_pauta;
    LOOP
        FETCH c_pauta INTO v_reg_pauta;
        EXIT WHEN c_pauta%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('ALUNO: ' || v_reg_pauta.nome_estudante || ' | RESULTADO: ' || v_reg_pauta.resultado);
    END LOOP;
    CLOSE c_pauta;

EXCEPTION WHEN OTHERS THEN
    IF c_assiduidade%ISOPEN THEN CLOSE c_assiduidade; END IF;
    IF c_pauta%ISOPEN THEN CLOSE c_pauta; END IF;
    DBMS_OUTPUT.PUT_LINE('ERRO NOS TESTES DE VISTAS: ' || SQLERRM);
END;
/
