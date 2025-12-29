-- =============================================================================
-- TESTE DE VISTAS E RELATÓRIOS (ESTRATÉGIA ANTI-MUTAÇÃO)
-- =============================================================================
SET SERVEROUTPUT ON;

DECLARE
    v_sfx    VARCHAR2(10) := TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(1000,9999)));
    v_uc_id  NUMBER; v_tur_id NUMBER; v_mat_id NUMBER; v_ins_id NUMBER;
    v_est_id NUMBER; v_aula_id NUMBER; v_doc_id NUMBER; v_curso_id NUMBER;
    v_sala_id NUMBER; v_ta_id NUMBER;
    
    CURSOR c_assiduidade IS 
        SELECT nome_estudante, perc_faltas FROM VW_ALERTA_ASSIDUIDADE WHERE nome_turma = 'T_VISTA_'||v_sfx;
    v_reg_assiduidade c_assiduidade%ROWTYPE;

    CURSOR c_pauta IS 
        SELECT nome_estudante, resultado FROM VW_PAUTA_TURMA WHERE turma = 'T_VISTA_'||v_sfx;
    v_reg_pauta c_pauta%ROWTYPE;

BEGIN
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO TESTE DE VISTAS (Sufixo: '||v_sfx||') ===');

    -- 1. SETUP DE DADOS
    SELECT id INTO v_doc_id FROM (SELECT id FROM docente WHERE status = '1' ORDER BY id DESC) WHERE ROWNUM = 1;
    SELECT id INTO v_sala_id FROM (SELECT id FROM sala WHERE status = '1' ORDER BY id DESC) WHERE ROWNUM = 1;
    INSERT INTO tipo_aula (nome, status) VALUES ('TA_VISTA_'||v_sfx, '1') RETURNING id INTO v_ta_id;

    -- Criar Curso e UC
    INSERT INTO tipo_curso (nome, valor_propinas) VALUES ('TC_VISTA_'||v_sfx, 1000) RETURNING id INTO v_curso_id;
    INSERT INTO curso (nome, codigo, descricao, duracao, ects, tipo_curso_id) 
    VALUES ('Curso Vistas '||v_sfx, 'CV'||v_sfx, 'Desc', 3, 180, v_curso_id) RETURNING id INTO v_curso_id;

    INSERT INTO unidade_curricular (nome, codigo, horas_teoricas, horas_praticas) 
    VALUES ('UC VISTA '||v_sfx, 'UV'||v_sfx, 10, 10) RETURNING id INTO v_uc_id;

    INSERT INTO uc_curso (curso_id, unidade_curricular_id, semestre, ano, ects, presenca_obrigatoria, percentagem_presenca)
    VALUES (v_curso_id, v_uc_id, 1, 1, 6, '1', 75);

    -- Habilitar Docente para a UC
    INSERT INTO uc_docente (unidade_curricular_id, docente_id, funcao, status)
    VALUES (v_uc_id, v_doc_id, 'Docente', '1');

    -- Criar Turma
    INSERT INTO turma (nome, ano_letivo, unidade_curricular_id, docente_id)
    VALUES ('T_VISTA_'||v_sfx, '25', v_uc_id, v_doc_id) RETURNING id INTO v_tur_id;

    -- Criar Aluno e Matrícula
    INSERT INTO estudante (nome, nif, cc, data_nascimento, email, telemovel) 
    VALUES ('Est Vista '||v_sfx, '2'||LPAD(v_sfx, 8, '0'), LPAD(v_sfx, 8, '0'), TO_DATE('2000-01-01','YYYY-MM-DD'), 'ev'||v_sfx||'@t.pt', '96'||LPAD(v_sfx, 7, '0')) 
    RETURNING id INTO v_est_id;

    INSERT INTO matricula (curso_id, ano_inscricao, estudante_id, estado_matricula, numero_parcelas)
    VALUES (v_curso_id, 2025, v_est_id, 'Ativa', 10) RETURNING id INTO v_mat_id;

    -- INSCRIÇÃO com status '0' para evitar disparar triggers de presença automáticos (Mutating Table)
    INSERT INTO inscricao (turma_id, matricula_id, data, status)
    VALUES (v_tur_id, v_mat_id, SYSDATE, '0') RETURNING id INTO v_ins_id;

    -- Criar Aulas (Inscricao '0' -> Sem geração automática -> Sem erro)
    FOR i IN 1..4 LOOP
        INSERT INTO aula (data, hora_inicio, hora_fim, sala_id, tipo_aula_id, turma_id)
        VALUES (TRUNC(SYSDATE)-i, TRUNC(SYSDATE)+8/24, TRUNC(SYSDATE)+10/24, v_sala_id, v_ta_id, v_tur_id)
        RETURNING id INTO v_aula_id;
        
        -- Inserir presenças manualmente
        IF i <= 2 THEN
            INSERT INTO presenca (inscricao_id, aula_id, presente, status) VALUES (v_ins_id, v_aula_id, '1', '1');
        ELSE
            INSERT INTO presenca (inscricao_id, aula_id, presente, status) VALUES (v_ins_id, v_aula_id, '0', '1');
        END IF;
    END LOOP;

    -- Ativar a inscrição agora que as aulas e presenças estão prontas
    UPDATE inscricao SET status = '1' WHERE id = v_ins_id;

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