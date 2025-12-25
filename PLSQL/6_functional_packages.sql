-- -----------------------------------------------------------------------------
-- 6.1. PACOTE SECRETARIA (COM LOOP E EXIT WHEN)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE PKG_SECRETARIA IS
    PROCEDURE PRC_LANCAR_PAUTA_INICIAL(p_turma_id IN NUMBER, p_avaliacao_id IN NUMBER);
    PROCEDURE PRC_INSCREVER_UC(p_matricula_id IN NUMBER, p_turma_id IN NUMBER);
END PKG_SECRETARIA;
/

CREATE OR REPLACE PACKAGE BODY PKG_SECRETARIA IS
    
    e_aluno_devedor   EXCEPTION;
    e_ja_aprovado     EXCEPTION;

    PROCEDURE PRC_LANCAR_PAUTA_INICIAL(p_turma_id IN NUMBER, p_avaliacao_id IN NUMBER) IS
        -- Cursor explícito
        CURSOR c_alunos IS SELECT id FROM inscricao WHERE turma_id = p_turma_id AND status = '1';
        v_aluno_id inscricao.id%TYPE;
    BEGIN
        OPEN c_alunos;
        LOOP
            FETCH c_alunos INTO v_aluno_id;
            EXIT WHEN c_alunos%NOTFOUND;

            INSERT INTO nota (inscricao_id, avaliacao_id, nota, comentario)
            VALUES (v_aluno_id, p_avaliacao_id, 0, 'Pauta inicial gerada.');
        END LOOP;
        CLOSE c_alunos;

        COMMIT;
    END PRC_LANCAR_PAUTA_INICIAL;

    PROCEDURE PRC_INSCREVER_UC(p_matricula_id IN NUMBER, p_turma_id IN NUMBER) IS
        v_uc_id NUMBER;
        v_aprovado NUMBER;
        v_estudante_id NUMBER;
    BEGIN
        SELECT estudante_id INTO v_estudante_id FROM matricula WHERE id = p_matricula_id;
        SELECT unidade_curricular_id INTO v_uc_id FROM turma WHERE id = p_turma_id;

        -- 1. Verificação de Dívida
        IF FUN_IS_DEVEDOR(v_estudante_id) = 'S' THEN RAISE e_aluno_devedor; END IF;

        -- 2. Verificação de Aprovação
        SELECT COUNT(*) INTO v_aprovado FROM nota n JOIN inscricao i ON n.inscricao_id = i.id JOIN turma t ON i.turma_id = t.id
        WHERE i.matricula_id = p_matricula_id AND t.unidade_curricular_id = v_uc_id AND n.nota >= 9.5;

        IF v_aprovado > 0 THEN RAISE e_ja_aprovado; END IF;

        -- 3. Inscrição
        INSERT INTO inscricao (turma_id, matricula_id, data) VALUES (p_turma_id, p_matricula_id, SYSDATE);
        COMMIT;

    EXCEPTION
        WHEN e_aluno_devedor THEN
            PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Inscrição recusada por motivos financeiros (Aluno: ' || v_estudante_id || ').');
        WHEN e_ja_aprovado THEN
            PKG_GESTAO_DADOS.PRC_LOG_ALERTA('O aluno já tem aprovação na UC ' || v_uc_id || '.');
        WHEN OTHERS THEN
            ROLLBACK;
            PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Erro na inscrição: ' || SQLERRM);
    END PRC_INSCREVER_UC;

END PKG_SECRETARIA;
/

-- -----------------------------------------------------------------------------
-- 6.2. PACOTE TESOURARIA (COM LOOP E EXIT WHEN)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE PKG_TESOURARIA IS
    PROCEDURE PRC_GERAR_PLANO_PAGAMENTO(p_matricula_id IN NUMBER);
    PROCEDURE PRC_PROCESSAR_PAGAMENTO(p_parcela_id IN NUMBER, p_valor IN NUMBER);
END PKG_TESOURARIA;
/

CREATE OR REPLACE PACKAGE BODY PKG_TESOURARIA IS
    PROCEDURE PRC_GERAR_PLANO_PAGAMENTO(p_matricula_id IN NUMBER) IS
        v_num_parcelas NUMBER;
        v_valor_total NUMBER;
        v_valor_parcela NUMBER;
        i NUMBER := 1; -- Inicialização do iterador
    BEGIN
        SELECT m.numero_parcelas, tc.valor_propinas INTO v_num_parcelas, v_valor_total
        FROM matricula m JOIN curso c ON m.curso_id = c.id JOIN tipo_curso tc ON c.tipo_curso_id = tc.id
        WHERE m.id = p_matricula_id;

        v_valor_parcela := v_valor_total / v_num_parcelas;

        -- Loop manual substituindo o FOR
        LOOP
            EXIT WHEN i > v_num_parcelas;

            INSERT INTO parcela_propina (valor, data_vencimento, numero, estado, matricula_id)
            VALUES (v_valor_parcela, ADD_MONTHS(SYSDATE, i), i, 'N', p_matricula_id);

            i := i + 1; -- Incremento manual
        END LOOP;

        COMMIT;
    END PRC_GERAR_PLANO_PAGAMENTO;

    PROCEDURE PRC_PROCESSAR_PAGAMENTO(p_parcela_id IN NUMBER, p_valor IN NUMBER) IS
    BEGIN
        UPDATE parcela_propina SET estado = 'P', data_pagamento = SYSDATE, updated_at = SYSDATE WHERE id = p_parcela_id;
        COMMIT;
    END PRC_PROCESSAR_PAGAMENTO;
END PKG_TESOURARIA;
/
