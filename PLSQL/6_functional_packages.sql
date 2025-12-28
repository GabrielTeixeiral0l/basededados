-- -----------------------------------------------------------------------------
-- 6.2. PACOTE TESOURARIA (COM DEBUG)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE PKG_TESOURARIA IS
    PROCEDURE PRC_GERAR_PLANO_PAGAMENTO(
        p_matricula_id IN NUMBER, 
        p_valor_total IN NUMBER DEFAULT NULL, 
        p_num_parcelas IN NUMBER DEFAULT NULL
    );
    PROCEDURE PRC_PROCESSAR_PAGAMENTO(p_parcela_id IN NUMBER, p_valor IN NUMBER);
END PKG_TESOURARIA;
/

CREATE OR REPLACE PACKAGE BODY PKG_TESOURARIA IS

    PROCEDURE PRC_GERAR_PLANO_PAGAMENTO(
        p_matricula_id IN NUMBER, 
        p_valor_total IN NUMBER DEFAULT NULL, 
        p_num_parcelas IN NUMBER DEFAULT NULL
    ) IS
        v_num_parcelas NUMBER := p_num_parcelas; 
        v_valor_total NUMBER := p_valor_total; 
        v_valor_parcela NUMBER; 
        v_pagas NUMBER; 
        i NUMBER := 1;
    BEGIN
        
        -- Verificar se já existem pagamentos para não sobrescrever plano ativo com histórico
        SELECT COUNT(*) INTO v_pagas FROM parcela_propina WHERE matricula_id = p_matricula_id AND estado = '1';
        IF v_pagas > 0 THEN 
            PKG_LOG.ALERTA('Plano de pagamento não gerado: Já existem parcelas pagas.', 'PARCELA_PROPINA');
            RETURN; 
        END IF;

        DELETE FROM parcela_propina WHERE matricula_id = p_matricula_id;

        -- Se os valores não foram passados (chamada manual), busca na base
        IF v_valor_total IS NULL OR v_num_parcelas IS NULL THEN
            SELECT tc.valor_propinas, m.numero_parcelas 
            INTO v_valor_total, v_num_parcelas
            FROM matricula m 
            JOIN curso c ON m.curso_id = c.id 
            JOIN tipo_curso tc ON c.tipo_curso_id = tc.id 
            WHERE m.id = p_matricula_id;
        END IF;

        DBMS_OUTPUT.PUT_LINE('Valor Total: ' || v_valor_total || ', Parcelas: ' || v_num_parcelas);

        IF NVL(v_num_parcelas, 0) <= 0 THEN 
            DBMS_OUTPUT.PUT_LINE('Número de parcelas inválido.');
            RETURN; 
        END IF;

        v_valor_parcela := v_valor_total / v_num_parcelas;

        LOOP
            EXIT WHEN i > v_num_parcelas;
            INSERT INTO parcela_propina (valor, data_vencimento, numero, estado, matricula_id, status)
            VALUES (v_valor_parcela, ADD_MONTHS(SYSDATE, i), i, '0', p_matricula_id, '1');
            i := i + 1;
        END LOOP;
        
        DBMS_OUTPUT.PUT_LINE('Plano gerado com sucesso: ' || v_num_parcelas || ' parcelas.');
        
    EXCEPTION 
        WHEN OTHERS THEN 
            DBMS_OUTPUT.PUT_LINE('ERRO em PRC_GERAR_PLANO_PAGAMENTO: ' || SQLERRM);
            PKG_LOG.ERRO('PKG_TESOURARIA.PRC_GERAR_PLANO_PAGAMENTO: ' || SQLERRM, 'PARCELA_PROPINA');
            RAISE; -- Re-raise para o trigger falhar e mostrar o erro
    END PRC_GERAR_PLANO_PAGAMENTO;

    PROCEDURE PRC_PROCESSAR_PAGAMENTO(p_parcela_id IN NUMBER, p_valor IN NUMBER) IS
        v_vencimento DATE; v_orig NUMBER; v_multa NUMBER := 0;
    BEGIN
        SELECT data_vencimento, valor INTO v_vencimento, v_orig FROM parcela_propina WHERE id = p_parcela_id;
        IF SYSDATE > v_vencimento THEN
            v_multa := v_orig * PKG_CONSTANTES.TAXA_MULTA_ATRASO;
            PKG_LOG.ALERTA('Multa de ' || v_multa || ' aplicada.', 'PARCELA_PROPINA');
        END IF;
        UPDATE parcela_propina SET estado = '1', data_pagamento = SYSDATE, valor = v_orig + v_multa, updated_at = SYSDATE WHERE id = p_parcela_id;
    EXCEPTION WHEN OTHERS THEN PKG_LOG.ERRO('PKG_TESOURARIA.PRC_PROCESSAR_PAGAMENTO: ' || SQLERRM, 'PARCELA_PROPINA');
    END PRC_PROCESSAR_PAGAMENTO;
END PKG_TESOURARIA;
/