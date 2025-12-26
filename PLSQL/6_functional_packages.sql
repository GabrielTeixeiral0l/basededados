-- =============================================================================
-- 6. PACOTES FUNCIONAIS (SECRETARIA E TESOURARIA)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 6.1. PACOTE SECRETARIA
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE PKG_SECRETARIA IS
    PROCEDURE PRC_LANCAR_PAUTA_INICIAL(
        p_turma_id     IN NUMBER, 
        p_avaliacao_id IN NUMBER
    );
    
    PROCEDURE PRC_INSCREVER_UC(
        p_matricula_id IN NUMBER, 
        p_turma_id     IN NUMBER
    );
END PKG_SECRETARIA;
/

CREATE OR REPLACE PACKAGE BODY PKG_SECRETARIA IS
    
    e_aluno_devedor EXCEPTION;
    e_ja_aprovado   EXCEPTION;

    PROCEDURE PRC_LANCAR_PAUTA_INICIAL(
        p_turma_id     IN NUMBER, 
        p_avaliacao_id IN NUMBER
    ) IS
        CURSOR c_alunos IS 
            SELECT id FROM inscricao WHERE turma_id = p_turma_id AND status = '1';
        v_insc_id NUMBER;
    BEGIN
        OPEN c_alunos;
        LOOP
            FETCH c_alunos INTO v_insc_id;
            EXIT WHEN c_alunos%NOTFOUND;
            
            INSERT INTO nota (inscricao_id, avaliacao_id, nota, comentario, status)
            VALUES (v_insc_id, p_avaliacao_id, 0, 'Pauta inicial gerada.', '1');
        END LOOP;
        CLOSE c_alunos;
    END PRC_LANCAR_PAUTA_INICIAL;

    PROCEDURE PRC_INSCREVER_UC(
        p_matricula_id IN NUMBER, 
        p_turma_id     IN NUMBER
    ) IS
        v_uc_id        NUMBER;
        v_aprovado     NUMBER;
        v_estudante_id NUMBER;
    BEGIN
        SELECT estudante_id INTO v_estudante_id FROM matricula WHERE id = p_matricula_id;
        SELECT unidade_curricular_id INTO v_uc_id FROM turma WHERE id = p_turma_id;

        -- 1. Validar Dívidas
        IF FUN_IS_DEVEDOR(v_estudante_id) = 'S' THEN 
            RAISE e_aluno_devedor; 
        END IF;

        -- 2. Validar Aprovação prévia
        SELECT COUNT(*) INTO v_aprovado 
        FROM nota n 
        JOIN inscricao i ON n.inscricao_id = i.id 
        JOIN turma t ON i.turma_id = t.id
        WHERE i.matricula_id = p_matricula_id 
          AND t.unidade_curricular_id = v_uc_id 
          AND n.nota >= PKG_CONSTANTES.NOTA_APROVACAO;

        IF v_aprovado > 0 THEN 
            RAISE e_ja_aprovado; 
        END IF;

        -- 3. Inserir Inscrição
        INSERT INTO inscricao (turma_id, matricula_id, data, status) 
        VALUES (p_turma_id, p_matricula_id, SYSDATE, '1');

    EXCEPTION
        WHEN e_aluno_devedor THEN
            PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Inscrição recusada: Aluno devedor.');
        WHEN e_ja_aprovado THEN
            PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Inscrição recusada: Aluno já aprovado na UC.');
        WHEN OTHERS THEN
            PKG_GESTAO_DADOS.PRC_LOG_ERRO('PKG_SECRETARIA.PRC_INSCREVER_UC');
    END PRC_INSCREVER_UC;

END PKG_SECRETARIA;
/

-- -----------------------------------------------------------------------------
-- 6.2. PACOTE TESOURARIA
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE PKG_TESOURARIA IS
    PROCEDURE PRC_GERAR_PLANO_PAGAMENTO(
        p_matricula_id      IN NUMBER, 
        p_novo_num_parcelas IN NUMBER DEFAULT NULL
    );
    
    PROCEDURE PRC_PROCESSAR_PAGAMENTO(
        p_parcela_id IN NUMBER, 
        p_valor      IN NUMBER
    );
END PKG_TESOURARIA;
/

CREATE OR REPLACE PACKAGE BODY PKG_TESOURARIA IS

    PROCEDURE PRC_GERAR_PLANO_PAGAMENTO(
        p_matricula_id      IN NUMBER, 
        p_novo_num_parcelas IN NUMBER DEFAULT NULL
    ) IS
        v_num_parcelas  NUMBER;
        v_valor_total   NUMBER;
        v_valor_parcela NUMBER;
        v_pagas         NUMBER;
        i               NUMBER := 1;
    BEGIN
        SELECT COUNT(*) INTO v_pagas FROM parcela_propina WHERE matricula_id = p_matricula_id AND estado = 'P';
        
        IF v_pagas > 0 THEN
            PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Erro: Plano já possui pagamentos.');
            RETURN;
        END IF;

        DELETE FROM parcela_propina WHERE matricula_id = p_matricula_id;

        SELECT tc.valor_propinas, NVL(p_novo_num_parcelas, m.numero_parcelas)
        INTO v_valor_total, v_num_parcelas
        FROM matricula m 
        JOIN curso c ON m.curso_id = c.id 
        JOIN tipo_curso tc ON c.tipo_curso_id = tc.id
        WHERE m.id = p_matricula_id;

        v_valor_parcela := v_valor_total / v_num_parcelas;

        LOOP
            EXIT WHEN i > v_num_parcelas;
            
            INSERT INTO parcela_propina (id, valor, data_vencimento, numero, estado, matricula_id, status)
            VALUES (seq_parcela_propina.NEXTVAL, v_valor_parcela, ADD_MONTHS(SYSDATE, i), i, 'N', p_matricula_id, '1');
            
            i := i + 1;
        END LOOP;
    EXCEPTION 
        WHEN OTHERS THEN 
            PKG_GESTAO_DADOS.PRC_LOG_ERRO('PKG_TESOURARIA.PRC_GERAR_PLANO');
    END PRC_GERAR_PLANO_PAGAMENTO;

    PROCEDURE PRC_PROCESSAR_PAGAMENTO(
        p_parcela_id IN NUMBER, 
        p_valor      IN NUMBER
    ) IS
        v_vencimento DATE;
        v_orig       NUMBER;
        v_multa      NUMBER := 0;
    BEGIN
        SELECT data_vencimento, valor INTO v_vencimento, v_orig
        FROM parcela_propina WHERE id = p_parcela_id;

        IF SYSDATE > v_vencimento THEN
            v_multa := v_orig * PKG_CONSTANTES.TAXA_MULTA_ATRASO;
            PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Atraso detetado. Multa de ' || v_multa || ' aplicada.');
        END IF;

        UPDATE parcela_propina 
        SET estado = 'P', 
            data_pagamento = SYSDATE, 
            valor = v_orig + v_multa, 
            updated_at = SYSDATE 
        WHERE id = p_parcela_id;
        
    EXCEPTION 
        WHEN OTHERS THEN 
            PKG_GESTAO_DADOS.PRC_LOG_ERRO('PKG_TESOURARIA.PRC_PROCESSAR_PAGAMENTO');
    END PRC_PROCESSAR_PAGAMENTO;

END PKG_TESOURARIA;
/
