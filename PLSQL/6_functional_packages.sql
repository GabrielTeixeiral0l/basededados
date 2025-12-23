-- -----------------------------------------------------------------------------
-- 6.1. PACOTE SECRETARIA (Gestão Académica)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE PKG_SECRETARIA IS
    -- Procedimento para lançar pauta inicial (gera registos de nota vazios para a turma)
    PROCEDURE PRC_LANCAR_PAUTA_INICIAL(p_turma_id IN NUMBER, p_avaliacao_id IN NUMBER);

    -- Procedimento para inscrever aluno verificando aprovações prévias
    PROCEDURE PRC_INSCREVER_UC(p_matricula_id IN NUMBER, p_turma_id IN NUMBER);
END PKG_SECRETARIA;
/

CREATE OR REPLACE PACKAGE BODY PKG_SECRETARIA IS
    PROCEDURE PRC_LANCAR_PAUTA_INICIAL(p_turma_id IN NUMBER, p_avaliacao_id IN NUMBER) IS
        CURSOR c_alunos IS 
            SELECT id FROM inscricao WHERE turma_id = p_turma_id AND status = '1';
    BEGIN
        FOR r_aluno IN c_alunos LOOP
            INSERT INTO nota (inscricao_id, avaliacao_id, nota, comentario)
            VALUES (r_aluno.id, p_avaliacao_id, 0, 'Pauta inicial gerada.');
        END LOOP;
        COMMIT;
    END PRC_LANCAR_PAUTA_INICIAL;

    PROCEDURE PRC_INSCREVER_UC(p_matricula_id IN NUMBER, p_turma_id IN NUMBER) IS
        v_uc_id NUMBER;
        v_aprovado NUMBER;
        v_estudante_id NUMBER;
    BEGIN
        -- 1. Obter estudante e UC
        SELECT estudante_id INTO v_estudante_id FROM matricula WHERE id = p_matricula_id;
        SELECT unidade_curricular_id INTO v_uc_id FROM turma WHERE id = p_turma_id;

        -- 2. BLOQUEIO FINANCEIRO: Verificar se o aluno tem dívidas
        IF FUN_IS_DEVEDOR(v_estudante_id) = 'S' THEN
            PKG_ERROS.RAISE_ERROR(PKG_ERROS.ERR_ALUNO_DIVIDA_CODE);
        END IF;

        -- 3. Verificar se o aluno já tem aprovação (Nota >= 9.5)
        SELECT COUNT(*)
        INTO v_aprovado
        FROM nota n
        JOIN inscricao i ON n.inscricao_id = i.id
        JOIN turma t ON i.turma_id = t.id
        WHERE i.matricula_id = p_matricula_id
          AND t.unidade_curricular_id = v_uc_id
          AND n.nota >= 9.5;

        IF v_aprovado > 0 THEN
            RAISE_APPLICATION_ERROR(-20008, 'Inscrição rejeitada: O estudante já obteve aprovação nesta Unidade Curricular.');
        END IF;

        -- 4. Realizar a inscrição
        INSERT INTO inscricao (turma_id, matricula_id, data)
        VALUES (p_turma_id, p_matricula_id, SYSDATE);
        
        COMMIT;
    END PRC_INSCREVER_UC;
END PKG_SECRETARIA;
/

-- -----------------------------------------------------------------------------
-- 6.2. PACOTE TESOURARIA (Gestão Financeira)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE PKG_TESOURARIA IS
    -- Gera plano de pagamento para uma matrícula
    PROCEDURE PRC_GERAR_PLANO_PAGAMENTO(p_matricula_id IN NUMBER);
    
    -- Regista pagamento de uma parcela
    PROCEDURE PRC_PROCESSAR_PAGAMENTO(p_parcela_id IN NUMBER, p_valor IN NUMBER);
END PKG_TESOURARIA;
/

CREATE OR REPLACE PACKAGE BODY PKG_TESOURARIA IS
    PROCEDURE PRC_GERAR_PLANO_PAGAMENTO(p_matricula_id IN NUMBER) IS
        v_num_parcelas NUMBER;
        v_valor_total NUMBER;
        v_valor_parcela NUMBER;
    BEGIN
        -- Obter configurações da matrícula e do curso
        SELECT m.numero_parcelas, tc.valor_propinas
        INTO v_num_parcelas, v_valor_total
        FROM matricula m
        JOIN curso c ON m.curso_id = c.id
        JOIN tipo_curso tc ON c.tipo_curso_id = tc.id
        WHERE m.id = p_matricula_id;

        v_valor_parcela := v_valor_total / v_num_parcelas;

        FOR i IN 1..v_num_parcelas LOOP
            INSERT INTO parcela_propina (valor, data_vencimento, numero, estado, matricula_id)
            VALUES (v_valor_parcela, ADD_MONTHS(SYSDATE, i), i, 'N', p_matricula_id);
        END LOOP;
        COMMIT;
    END PRC_GERAR_PLANO_PAGAMENTO;

    PROCEDURE PRC_PROCESSAR_PAGAMENTO(p_parcela_id IN NUMBER, p_valor IN NUMBER) IS
    BEGIN
        UPDATE parcela_propina
        SET estado = 'P',
            data_pagamento = SYSDATE,
            updated_at = SYSDATE
        WHERE id = p_parcela_id;
        
        COMMIT;
    END PRC_PROCESSAR_PAGAMENTO;
END PKG_TESOURARIA;
/
