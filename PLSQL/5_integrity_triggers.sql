-- =============================================================================
-- 5. TRIGGERS DE INTEGRIDADE E REGRA DE NEGÓCIO
-- =============================================================================

-- 5.1. VALIDAÇÃO DE NOTAS (0 a 20)
CREATE OR REPLACE TRIGGER TRG_VAL_NOTA
BEFORE INSERT OR UPDATE ON NOTA
FOR EACH ROW
BEGIN
    IF :NEW.nota < 0 OR :NEW.nota > 20 THEN
        PKG_LOG.ERRO('TRG_VAL_NOTA', 'Nota invalida: ' || :NEW.nota);
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
    v_tipo_perm_grupo  CHAR(1);
    v_tipo_perm_filhos CHAR(1);
BEGIN
    SELECT requer_entrega, permite_grupo, permite_filhos
    INTO v_tipo_req_entrega, v_tipo_perm_grupo, v_tipo_perm_filhos
    FROM tipo_avaliacao
    WHERE id = :NEW.tipo_avaliacao_id;

    -- Validar hierarquia (Sub-avaliação)
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
        EXCEPTION WHEN NO_DATA_FOUND THEN
            NULL; 
        END;
    END IF;
END;
/

-- 5.3. VALIDAÇÃO DE SOBREPOSIÇÃO DE HORÁRIO
CREATE OR REPLACE TRIGGER TRG_VAL_HORARIO_AULA
BEFORE INSERT OR UPDATE ON AULA
FOR EACH ROW
DECLARE
    v_conflito NUMBER;
    v_docente_id NUMBER;
BEGIN
    SELECT docente_id INTO v_docente_id FROM turma WHERE id = :NEW.turma_id;

    SELECT COUNT(*) INTO v_conflito
    FROM aula a
    JOIN turma t ON a.turma_id = t.id
    WHERE t.docente_id = v_docente_id
      AND a.data = :NEW.data
      AND a.id != :NEW.id
      AND (
          (:NEW.hora_inicio BETWEEN a.hora_inicio AND a.hora_fim) OR
          (:NEW.hora_fim BETWEEN a.hora_inicio AND a.hora_fim) OR
          (a.hora_inicio BETWEEN :NEW.hora_inicio AND :NEW.hora_fim)
      );

    IF v_conflito > 0 THEN
        PKG_LOG.ALERTA('Conflito de horario para o docente ' || v_docente_id);
    END IF;
END;
/

-- 5.4. VALIDAÇÃO DE CAPACIDADE DA TURMA
CREATE OR REPLACE TRIGGER TRG_VAL_CAPACIDADE_TURMA
BEFORE INSERT ON INSCRICAO
FOR EACH ROW
DECLARE
    v_inscritos NUMBER;
    v_max       NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_inscritos FROM inscricao WHERE turma_id = :NEW.turma_id AND status = '1';
    
    SELECT max_alunos INTO v_max FROM turma WHERE id = :NEW.turma_id;

    IF v_max IS NOT NULL AND v_inscritos >= v_max THEN
        RAISE_APPLICATION_ERROR(-20004, 'Turma cheia. Capacidade maxima: ' || v_max);
    END IF;
END;
/

-- 5.5. VALIDAÇÃO DE REGRAS DE ESTUDANTE (ECTS Anual)
CREATE OR REPLACE TRIGGER TRG_VAL_ESTUDANTE_REGRAS
BEFORE INSERT ON INSCRICAO
FOR EACH ROW
DECLARE
    v_total_ects NUMBER;
    v_novos_ects NUMBER;
    v_ano_letivo VARCHAR2(10);
BEGIN
    -- Obter ECTS da nova UC e Ano Letivo da Turma
    SELECT uc.ects, t.ano_letivo
    INTO v_novos_ects, v_ano_letivo
    FROM turma t
    JOIN uc_curso uc ON t.unidade_curricular_id = uc.unidade_curricular_id
    JOIN matricula m ON m.id = :NEW.matricula_id
    WHERE t.id = :NEW.turma_id
      AND uc.curso_id = m.curso_id;

    -- Obter Total de ECTS já inscritos no mesmo ano letivo
    SELECT NVL(SUM(uc.ects), 0)
    INTO v_total_ects
    FROM inscricao i
    JOIN turma t ON i.turma_id = t.id
    JOIN uc_curso uc ON t.unidade_curricular_id = uc.unidade_curricular_id
    JOIN matricula m ON i.matricula_id = m.id
    WHERE i.matricula_id = :NEW.matricula_id
      AND t.ano_letivo = v_ano_letivo
      AND i.status = '1'
      AND uc.curso_id = m.curso_id;

    -- Validar Limite (60 ECTS)
    IF (v_total_ects + v_novos_ects) > 60 THEN
        RAISE_APPLICATION_ERROR(-20005, 'Limite de ECTS excedido. Total atual: ' || v_total_ects || ', Tentativa: ' || v_novos_ects);
    END IF;
EXCEPTION 
    WHEN NO_DATA_FOUND THEN NULL;
END;
/

-- 5.6. GERAÇÃO AUTOMÁTICA DE PARCELAS DE PROPINA
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
    PKG_LOG.ERRO('TRG_AUTO_GERAR_PROPINAS', SQLERRM);
END;
/

-- 5.7. VALIDAÇÃO DE ENTREGAS
CREATE OR REPLACE TRIGGER TRG_VAL_ENTREGA_REGRAS
BEFORE INSERT ON ENTREGA
FOR EACH ROW
DECLARE
    v_requer CHAR(1);
BEGIN
    SELECT ta.requer_entrega INTO v_requer
    FROM avaliacao a
    JOIN tipo_avaliacao ta ON a.tipo_avaliacao_id = ta.id
    WHERE a.id = :NEW.avaliacao_id;

    IF v_requer = '0' THEN
        RAISE_APPLICATION_ERROR(-20006, 'Esta avaliacao nao requer entrega de ficheiros.');
    END IF;
END;
/

-- 5.8. REMOÇÃO SEGURA DE TRIGGER OBSOLETO
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER TRG_VAL_PRESENCA_DUPLICADA';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -4080 THEN -- ORA-04080: trigger does not exist
            RAISE;
        END IF;
END;
/

-- 5.9. OUTRAS VALIDAÇÕES (NIF, CC, DOCUMENTOS)
CREATE OR REPLACE TRIGGER TRG_VAL_DOCS_ESTUDANTE
BEFORE INSERT OR UPDATE ON ESTUDANTE
FOR EACH ROW
BEGIN
    IF NOT PKG_VALIDACAO.FUN_VALIDAR_NIF(:NEW.nif) THEN
        PKG_LOG.ALERTA('NIF Invalido inserido para estudante: ' || :NEW.nome);
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_VAL_DOCS_DOCENTE
BEFORE INSERT OR UPDATE ON DOCENTE
FOR EACH ROW
BEGIN
    IF NOT PKG_VALIDACAO.FUN_VALIDAR_NIF(:NEW.nif) THEN
        PKG_LOG.ALERTA('NIF Invalido inserido para docente: ' || :NEW.nome);
    END IF;
END;
/