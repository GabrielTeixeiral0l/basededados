-- =============================================================================
-- TESTE DE VISTAS E RELATÓRIOS (Versão Corrigida para Trigger de Presenças)
-- Valida se as vistas VW_PAUTA_TURMA e VW_ALERTA_ASSIDUIDADE funcionam.
-- =============================================================================

SET SERVEROUTPUT ON;

DECLARE
    v_sfx    VARCHAR2(10) := TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(1000,9999)));
    v_uc_id  NUMBER;
    v_tur_id NUMBER;
    v_mat_id NUMBER;
    v_ins_id NUMBER;
    v_est_id NUMBER;
    v_aula_id NUMBER;
    v_doc_id NUMBER;
    v_curso_id NUMBER;
    v_sala_id NUMBER;
    v_ta_id NUMBER;
    
    CURSOR c_assiduidade IS 
        SELECT nome_estudante, perc_faltas FROM VW_ALERTA_ASSIDUIDADE WHERE nome_turma = 'T_VISTA_'||v_sfx;
    v_reg_assiduidade c_assiduidade%ROWTYPE;

    CURSOR c_pauta IS 
        SELECT nome_estudante, resultado FROM VW_PAUTA_TURMA WHERE turma = 'T_VISTA_'||v_sfx;
    v_reg_pauta c_pauta%ROWTYPE;

BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTE DE VISTAS (Sufixo: '||v_sfx||') ===');

    -- 1. SETUP DE DADOS
    SELECT id INTO v_est_id FROM (SELECT id FROM estudante ORDER BY id) WHERE ROWNUM = 1;
    SELECT id INTO v_doc_id FROM (SELECT id FROM docente ORDER BY id) WHERE ROWNUM = 1;
    SELECT id INTO v_sala_id FROM (SELECT id FROM sala ORDER BY id) WHERE ROWNUM = 1;
    SELECT id INTO v_ta_id FROM (SELECT id FROM tipo_aula ORDER BY id) WHERE ROWNUM = 1;

    -- Criar Curso e UC
    v_curso_id := seq_curso.NEXTVAL;
    INSERT INTO curso (id, nome, codigo, descricao, duracao, ects, tipo_curso_id) 
    VALUES (v_curso_id, 'Curso Vistas '||v_sfx, 'CV'||v_sfx, 'Desc', 3, 180, 1);

    v_uc_id := seq_unidade_curricular.NEXTVAL;
    INSERT INTO unidade_curricular (id, nome, codigo, horas_teoricas, horas_praticas) 
    VALUES (v_uc_id, 'UC VISTA '||v_sfx, 'UV'||v_sfx, 10, 10);

    INSERT INTO uc_curso (curso_id, unidade_curricular_id, semestre, ano, ects, presenca_obrigatoria)
    VALUES (v_curso_id, v_uc_id, 1, 1, 6, '1');

    -- Criar Turma (Isso ainda NÃO gera presenças pois não há alunos)
    v_tur_id := seq_turma.NEXTVAL;
    INSERT INTO turma (id, nome, ano_letivo, unidade_curricular_id, docente_id)
    VALUES (v_tur_id, 'T_VISTA_'||v_sfx, '2025/26', v_uc_id, v_doc_id);

    -- Criar Matrícula
    v_mat_id := seq_matricula.NEXTVAL;
    INSERT INTO matricula (id, curso_id, ano_inscricao, estado_matricula, estudante_id, numero_parcelas)
    VALUES (v_mat_id, v_curso_id, 2025, 'Ativa', v_est_id, 10);

    -- Criar Aulas ANTES da Inscrição (para testar o trigger TRG_AUTO_PRESENCA_INS)
    -- Ou DEPOIS (para testar TRG_AUTO_PRESENCA_AULA). Vamos criar ANTES.
    FOR i IN 1..4 LOOP
        v_aula_id := seq_aula.NEXTVAL;
        INSERT INTO aula (id, data, hora_inicio, hora_fim, sumario, sala_id, tipo_aula_id, turma_id)
        VALUES (v_aula_id, SYSDATE-i, SYSDATE, SYSDATE, 'Aula Teste '||i, v_sala_id, v_ta_id, v_tur_id);
    END LOOP;

    -- INSCRIÇÃO (Aqui o Trigger TRG_AUTO_PRESENCA_INS dispara e cria as 4 presenças como '0')
    v_ins_id := seq_inscricao.NEXTVAL;
    INSERT INTO inscricao (id, turma_id, matricula_id, data)
    VALUES (v_ins_id, v_tur_id, v_mat_id, SYSDATE);

    -- ATUALIZAR PRESENÇAS (Em vez de inserir)
    -- Vamos marcar 2 presenças como '1' (Presente) e deixar 2 como '0' (Falta)
    -- Como não temos os IDs das aulas facilmente aqui, vamos usar um cursor ou update massivo com rownum
    
    UPDATE presenca 
    SET presente = '1' 
    WHERE inscricao_id = v_ins_id 
      AND aula_id IN (
          SELECT id FROM (SELECT id FROM aula WHERE turma_id = v_tur_id ORDER BY id) WHERE ROWNUM <= 2
      );

    COMMIT;

    -- 2. Consultar Relatório de Assiduidade
    DBMS_OUTPUT.PUT_LINE('RELATORIO DE ASSIDUIDADE (Esperado 50% Faltas):');
    OPEN c_assiduidade;
    LOOP
        FETCH c_assiduidade INTO v_reg_assiduidade;
        EXIT WHEN c_assiduidade%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('ALUNO: ' || v_reg_assiduidade.nome_estudante || ' | FALTAS: ' || v_reg_assiduidade.perc_faltas || '%');
    END LOOP;
    CLOSE c_assiduidade;

    -- 3. Consultar Pauta
    DBMS_OUTPUT.PUT_LINE('CONSULTANDO PAUTA:');
    OPEN c_pauta;
    LOOP
        FETCH c_pauta INTO v_reg_pauta;
        EXIT WHEN c_pauta%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('ALUNO: ' || v_reg_pauta.nome_estudante || ' | RESULTADO: ' || v_reg_pauta.resultado);
    END LOOP;
    CLOSE c_pauta;

    -- 4. Smoke Test
    DBMS_OUTPUT.PUT_LINE('TESTANDO RESTANTES VISTAS (SMOKE TEST)...');
    DECLARE v_dummy NUMBER; BEGIN
        SELECT COUNT(*) INTO v_dummy FROM VW_FINANCEIRO_CURSOS;
        DBMS_OUTPUT.PUT_LINE('[OK] VW_FINANCEIRO_CURSOS: ' || v_dummy || ' registos.');
        SELECT COUNT(*) INTO v_dummy FROM VW_ESTATISTICA_VAGAS;
        DBMS_OUTPUT.PUT_LINE('[OK] VW_ESTATISTICA_VAGAS: ' || v_dummy || ' registos.');
    END;

    ROLLBACK;
EXCEPTION WHEN OTHERS THEN
    IF c_assiduidade%ISOPEN THEN CLOSE c_assiduidade; END IF;
    IF c_pauta%ISOPEN THEN CLOSE c_pauta; END IF;
    DBMS_OUTPUT.PUT_LINE('ERRO NOS TESTES DE VISTAS: ' || SQLERRM);
    ROLLBACK;
END;
/
