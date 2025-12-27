-- =============================================================================
-- 5. TRIGGERS DE INTEGRIDADE E REGRA DE NEGÓCIO (COMPATÍVEL COM DDL V3)
-- =============================================================================

-- 5.1. VALIDAÇÃO DE NOTAS (0 a 20)
CREATE OR REPLACE TRIGGER TRG_VAL_NOTA
BEFORE INSERT OR UPDATE ON NOTA
FOR EACH ROW
BEGIN
    IF :NEW.nota < 0 OR :NEW.nota > 20 THEN
        PKG_LOG.ALERTA('Tentativa de inserir nota invalida: ' || :NEW.nota);
        RAISE_APPLICATION_ERROR(-20001, 'A nota deve estar entre 0 e 20.');
    END IF;
END;
/

-- 5.2. VALIDAÇÃO DE REGRAS DE AVALIAÇÃO
CREATE OR REPLACE TRIGGER TRG_VAL_AVALIACAO_REGRAS
BEFORE INSERT OR UPDATE ON AVALIACAO
FOR EACH ROW
DECLARE
    v_tipo_req_entrega CHAR(1);
    v_tipo_perm_filhos CHAR(1);
BEGIN
    SELECT requer_entrega, permite_filhos
    INTO v_tipo_req_entrega, v_tipo_perm_filhos
    FROM tipo_avaliacao
    WHERE id = :NEW.tipo_avaliacao_id;

    IF :NEW.avaliacao_pai_id IS NOT NULL THEN
        DECLARE
            v_pai_permite_filhos CHAR(1);
        BEGIN
            SELECT t.permite_filhos INTO v_pai_permite_filhos
            FROM avaliacao a
            JOIN tipo_avaliacao t ON a.tipo_avaliacao_id = t.id
            WHERE a.id = :NEW.avaliacao_pai_id;

            IF v_pai_permite_filhos = '0' THEN
                 RAISE_APPLICATION_ERROR(-20002, 'A avaliacao pai nao permite sub-avaliacoes.');
            END IF;
        EXCEPTION WHEN NO_DATA_FOUND THEN NULL; 
        END;
    END IF;
END;
/

-- 5.3. VALIDAÇÃO DE SOBREPOSIÇÃO DE HORÁRIO (SALA_ID conforme V3)
CREATE OR REPLACE TRIGGER TRG_VAL_HORARIO_AULA
BEFORE INSERT OR UPDATE ON AULA
FOR EACH ROW
DECLARE
    v_conflito NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_conflito
    FROM aula a
    WHERE a.sala_id = :NEW.sala_id
      AND a.data = :NEW.data
      AND a.id != NVL(:NEW.id, -1)
      AND (
          (:NEW.hora_inicio BETWEEN a.hora_inicio AND a.hora_fim) OR
          (:NEW.hora_fim BETWEEN a.hora_inicio AND a.hora_fim)
      );

    IF v_conflito > 0 THEN
        PKG_LOG.ALERTA('Conflito de horario na sala ' || :NEW.sala_id);
    END IF;
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- 5.4. VALIDAÇÃO DE REGRAS DE ESTUDANTE (ECTS Anual)
CREATE OR REPLACE TRIGGER TRG_VAL_ESTUDANTE_REGRAS
BEFORE INSERT ON INSCRICAO
FOR EACH ROW
DECLARE
    v_total_ects NUMBER;
    v_novos_ects NUMBER;
    v_ano_letivo VARCHAR2(10);
    v_curso_id   NUMBER;
BEGIN
    SELECT m.curso_id, t.ano_letivo, uc.ects
    INTO v_curso_id, v_ano_letivo, v_novos_ects
    FROM matricula m
    JOIN turma t ON t.id = :NEW.turma_id
    JOIN uc_curso uc ON t.unidade_curricular_id = uc.unidade_curricular_id
    WHERE m.id = :NEW.matricula_id
      AND uc.curso_id = m.curso_id;

    SELECT NVL(SUM(uc.ects), 0)
    INTO v_total_ects
    FROM inscricao i
    JOIN turma t ON i.turma_id = t.id
    JOIN uc_curso uc ON t.unidade_curricular_id = uc.unidade_curricular_id
    WHERE i.matricula_id = :NEW.matricula_id
      AND t.ano_letivo = v_ano_letivo
      AND uc.curso_id = v_curso_id
      AND i.status = '1';

    IF (v_total_ects + v_novos_ects) > 60 THEN
        RAISE_APPLICATION_ERROR(-20005, 'Limite de 60 ECTS anuais excedido.');
    END IF;
EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
END;
/

-- 5.5. GERAÇÃO AUTOMÁTICA DE PARCELAS DE PROPINA
CREATE OR REPLACE TRIGGER TRG_AUTO_GERAR_PROPINAS
AFTER INSERT ON MATRICULA
FOR EACH ROW
DECLARE
    v_valor_total NUMBER;
BEGIN
    SELECT tc.valor_propinas INTO v_valor_total
    FROM curso c
    JOIN tipo_curso tc ON c.tipo_curso_id = tc.id
    WHERE c.id = :NEW.curso_id;

    PKG_TESOURARIA.PRC_GERAR_PLANO_PAGAMENTO(:NEW.id, v_valor_total, :NEW.numero_parcelas);
EXCEPTION WHEN OTHERS THEN
    PKG_LOG.ERRO('Erro ao gerar propinas para matricula ' || :NEW.id || ': ' || SQLERRM);
END;
/

-- 5.6. PROTEÇÃO DA TABELA DE LOGS (IMUTABILIDADE COM RASTO)
CREATE OR REPLACE TRIGGER TRG_PROTEGER_LOG
BEFORE DELETE OR UPDATE ON LOG
FOR EACH ROW
DECLARE
    E_IMUTAVEL EXCEPTION;
    v_operacao VARCHAR2(20);
BEGIN
    IF NOT PKG_LOG.v_modo_manutencao THEN
        v_operacao := CASE WHEN DELETING THEN 'DELETE' ELSE 'UPDATE' END;
        
        -- Registar a tentativa de violação (Autonomous Transaction garante o rasto)
        PKG_LOG.REGISTAR('VIOLACAO_SEGURANCA', 
                         'Tentativa de ' || v_operacao || ' no log id: ' || :OLD.id, 
                         'LOG');
        
        RAISE E_IMUTAVEL;
    END IF;
END;
/
