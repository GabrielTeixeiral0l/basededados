-- =============================================================================
-- SCRIPT DE TESTE DE VISTAS E RELATÓRIOS (CORRIGIDO)
-- =============================================================================
SET SERVEROUTPUT ON;

DECLARE
    v_turma_id NUMBER;
    v_ins_id NUMBER;
    v_mat_id NUMBER;
    v_doc_id NUMBER;
    v_curso_id NUMBER;
    v_estudante_id NUMBER;
    v_count NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Iniciando Teste de Vistas ---');

    -- 1. Preparar dados
    SELECT MIN(id) INTO v_curso_id FROM curso;
    SELECT MIN(id) INTO v_estudante_id FROM estudante;
    
    INSERT INTO unidade_curricular (nome, codigo, horas_teoricas, horas_praticas) 
    VALUES ('Vista Teste', 'VT01', 40, 20) RETURNING id INTO v_turma_id; 
    
    INSERT INTO docente (nome, data_contratacao, nif, cc, email, telemovel)
    VALUES ('Prof Vistas', SYSDATE, '299999999', '123456789ZZ1', 'v@v.com', '910000000') 
    RETURNING id INTO v_doc_id;
    
    INSERT INTO turma (nome, ano_letivo, unidade_curricular_id, max_alunos, docente_id)
    VALUES ('TURMA_VISTAS', '25/26', v_turma_id, 30, v_doc_id) 
    RETURNING id INTO v_turma_id;

    INSERT INTO matricula (curso_id, estudante_id, estado_matricula_id, ano_inscricao, numero_parcelas)
    VALUES (v_curso_id, v_estudante_id, 1, 2025, 10)
    RETURNING id INTO v_mat_id;

    INSERT INTO inscricao (turma_id, matricula_id, data, nota_final)
    VALUES (v_turma_id, v_mat_id, SYSDATE, 15) 
    RETURNING id INTO v_ins_id;

    -- 2. Validar VW_PAUTA_TURMA
    DBMS_OUTPUT.PUT_LINE('--- Verificando VW_PAUTA_TURMA ---');
    -- Corrigido: Nome da coluna é TURMA
    SELECT COUNT(*) INTO v_count FROM VW_PAUTA_TURMA WHERE TURMA = 'TURMA_VISTAS';
    
    IF v_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('[OK] VW_PAUTA_TURMA retornou dados.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FALHA] VW_PAUTA_TURMA está vazia.');
    END IF;

    -- 3. Testar VW_ALERTA_ASSIDUIDADE
    DBMS_OUTPUT.PUT_LINE('--- Gerando faltas para alerta ---');
    FOR i IN 1..10 LOOP
        INSERT INTO aula (data, hora_inicio, hora_fim, sumario, tipo_aula_id, sala_id, turma_id)
        VALUES (SYSDATE-i, TO_DATE('09:00', 'HH24:MI'), TO_DATE('10:00', 'HH24:MI'), 'Aula '||i, 1, 1, v_turma_id);
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('--- Verificando VW_ALERTA_ASSIDUIDADE ---');
    -- Corrigido: Nome da coluna é NOME_TURMA
    SELECT COUNT(*) INTO v_count FROM VW_ALERTA_ASSIDUIDADE WHERE NOME_TURMA = 'TURMA_VISTAS';

    IF v_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('[OK] Alerta de assiduidade gerado.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[FALHA] Alerta de assiduidade não gerado.');
    END IF;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('--- Teste Concluído ---');
END;
/
