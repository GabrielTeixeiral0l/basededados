-- =============================================================================
-- 5. TRIGGERS DE INTEGRIDADE E REGRAS DE NEGÓCIO
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 5.1. Validação de Nota (0 a 20)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_NOTA
BEFORE INSERT OR UPDATE ON nota
FOR EACH ROW
BEGIN
    IF :NEW.nota < 0 OR :NEW.nota > 20 THEN
        PKG_ERROS.RAISE_ERROR(PKG_ERROS.ERR_NOTA_INVALIDA_CODE);
    END IF;
END;
/

-- -----------------------------------------------------------------------------
-- 5.2. Validação de Horário de Aula (Sem sobreposição)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_HORARIO_AULA
BEFORE INSERT OR UPDATE ON aula
FOR EACH ROW
DECLARE
    v_conflito NUMBER;
    v_docente_id NUMBER;
BEGIN
    SELECT docente_id INTO v_docente_id FROM turma WHERE id = :NEW.turma_id;

    SELECT COUNT(*)
    INTO v_conflito
    FROM aula a
    JOIN turma t ON a.turma_id = t.id
    WHERE a.id != NVL(:NEW.id, -1)
      AND a.data = :NEW.data
      AND (
          (a.sala_id = :NEW.sala_id) OR (t.docente_id = v_docente_id)
      )
      AND (
          (:NEW.hora_inicio BETWEEN a.hora_inicio AND a.hora_fim) OR
          (:NEW.hora_fim BETWEEN a.hora_inicio AND a.hora_fim) OR
          (a.hora_inicio BETWEEN :NEW.hora_inicio AND :NEW.hora_fim)
      );

    IF v_conflito > 0 THEN
        PKG_ERROS.RAISE_ERROR(PKG_ERROS.ERR_CONFLITO_HORA_CODE);
    END IF;
END;
/

-- -----------------------------------------------------------------------------
-- 5.3. Validação de Data de Entrega
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_DATA_AVALIACAO
BEFORE INSERT OR UPDATE ON avaliacao
FOR EACH ROW
BEGIN
    IF :NEW.data_entrega < :NEW.data THEN
        PKG_ERROS.RAISE_ERROR(PKG_ERROS.ERR_DATA_ENTREGA_CODE);
    END IF;
END;
/

-- -----------------------------------------------------------------------------
-- 5.4. Lotação da Turma vs Capacidade da Sala
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_TURMA_CAPACIDADE
BEFORE INSERT ON inscricao
FOR EACH ROW
DECLARE
    v_inscritos NUMBER;
    v_capacidade NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_inscritos FROM inscricao WHERE turma_id = :NEW.turma_id AND status = '1';
    
    SELECT MIN(s.capacidade)
    INTO v_capacidade
    FROM aula a
    JOIN sala s ON a.sala_id = s.id
    WHERE a.turma_id = :NEW.turma_id;

    IF v_capacidade IS NOT NULL AND v_inscritos >= v_capacidade THEN
        PKG_ERROS.RAISE_ERROR(PKG_ERROS.ERR_TURMA_CHEIA_CODE);
    END IF;
END;
/

-- -----------------------------------------------------------------------------
-- 5.5. Proteção de Estado de Matrícula
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_MATRICULA_ESTADO
BEFORE UPDATE OF estado_matricula_id ON matricula
FOR EACH ROW
BEGIN
    IF :OLD.estado_matricula_id = 3 AND :NEW.estado_matricula_id != 4 THEN
        RAISE_APPLICATION_ERROR(-20007, 'Erro: Uma matrícula concluída não pode ser alterada, exceto para Cancelada.');
    END IF;
END;
/

-- -----------------------------------------------------------------------------
-- 5.6. Validação de Pesos de Avaliação (Compound Trigger)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_PESO_AVALIACAO
FOR INSERT OR UPDATE ON avaliacao
COMPOUND TRIGGER
    v_turma_id NUMBER;
    v_total_peso NUMBER;
    v_novo_peso NUMBER;
    v_id_atual NUMBER;

    BEFORE EACH ROW IS
    BEGIN
        v_turma_id := :NEW.turma_id;
        v_novo_peso := :NEW.peso;
        v_id_atual := :NEW.id;
    END BEFORE EACH ROW;

    AFTER STATEMENT IS
    BEGIN
        IF v_turma_id IS NOT NULL THEN
            SELECT NVL(SUM(peso), 0)
            INTO v_total_peso
            FROM avaliacao
            WHERE turma_id = v_turma_id
              AND id != NVL(v_id_atual, -1)
              AND status = '1';

            IF (v_total_peso + v_novo_peso) > 100 THEN
                RAISE_APPLICATION_ERROR(-20009, 'Erro: A soma dos pesos das avaliações ultrapassa 100%.');
            END IF;
        END IF;
    END AFTER STATEMENT;
END TRG_VAL_PESO_AVALIACAO;
/

-- -----------------------------------------------------------------------------
-- 5.7. Coerência Temporal de Assiduidade
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_DATA_PRESENCA
BEFORE INSERT OR UPDATE ON presenca
FOR EACH ROW
DECLARE
    v_data_aula DATE;
BEGIN
    SELECT data INTO v_data_aula FROM aula WHERE id = :NEW.aula_id;
    IF v_data_aula > SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20010, 'Erro: Não é possível registar presenças em aulas futuras.');
    END IF;
END;
/

-- -----------------------------------------------------------------------------
-- 5.8. Validação de Entidades Ativas (Soft Delete Check)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_STATUS_ATIVO
BEFORE INSERT ON inscricao
FOR EACH ROW
DECLARE
    v_status_turma CHAR(1);
    v_status_matricula CHAR(1);
BEGIN
    SELECT status INTO v_status_turma FROM turma WHERE id = :NEW.turma_id;
    SELECT status INTO v_status_matricula FROM matricula WHERE id = :NEW.matricula_id;

    IF v_status_turma = '0' OR v_status_matricula = '0' THEN
        RAISE_APPLICATION_ERROR(-20011, 'Erro: Inscrição impedida em Turma ou Matrícula inativa.');
    END IF;
END;
/

-- -----------------------------------------------------------------------------
-- 5.9. Limite de ECTS por Ano (Máximo 72 ECTS)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_LIMITE_ECTS
BEFORE INSERT ON inscricao
FOR EACH ROW
DECLARE
    v_matricula_id NUMBER;
    v_ects_atuais NUMBER := 0;
    v_ects_nova_uc NUMBER := 0;
    v_curso_id NUMBER;
    v_uc_id NUMBER;
BEGIN
    v_matricula_id := :NEW.matricula_id;
    SELECT curso_id INTO v_curso_id FROM matricula WHERE id = v_matricula_id;
    SELECT unidade_curricular_id INTO v_uc_id FROM turma WHERE id = :NEW.turma_id;

    BEGIN
        SELECT ects INTO v_ects_nova_uc
        FROM uc_curso
        WHERE curso_id = v_curso_id AND unidade_curricular_id = v_uc_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN v_ects_nova_uc := 0;
    END;

    SELECT NVL(SUM(uc.ects), 0)
    INTO v_ects_atuais
    FROM inscricao i
    JOIN turma t ON i.turma_id = t.id
    JOIN uc_curso uc ON t.unidade_curricular_id = uc.unidade_curricular_id
    WHERE i.matricula_id = v_matricula_id
      AND uc.curso_id = v_curso_id
      AND i.status = '1';

    IF (v_ects_atuais + v_ects_nova_uc) > 72 THEN
        RAISE_APPLICATION_ERROR(-20012, 'Erro: Limite de ECTS anuais excedido (Máx: 72).');
    END IF;
END;
/

-- -----------------------------------------------------------------------------
-- 5.10. Bloqueio de Entrega por Dívidas
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_BLOQUEIO_ENTREGA_DIVIDA
BEFORE INSERT ON estudante_entrega
FOR EACH ROW
DECLARE
    v_estudante_id NUMBER;
    v_matricula_id NUMBER;
BEGIN
    SELECT matricula_id INTO v_matricula_id FROM inscricao WHERE id = :NEW.inscricao_id;
    SELECT estudante_id INTO v_estudante_id FROM matricula WHERE id = v_matricula_id;

    IF FUN_IS_DEVEDOR(v_estudante_id) = 'S' THEN
        PKG_ERROS.RAISE_ERROR(PKG_ERROS.ERR_ALUNO_DIVIDA_CODE);
    END IF;
END;
/

-- -----------------------------------------------------------------------------
-- 5.11. Validação de Plano Curricular (Regra Pedida)
-- Garante que o aluno só se inscreve em turmas de UCs do seu curso.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_PLANO_CURRICULAR
BEFORE INSERT ON inscricao
FOR EACH ROW
DECLARE
    v_curso_id NUMBER;
    v_uc_id NUMBER;
    v_existe NUMBER;
BEGIN
    SELECT curso_id INTO v_curso_id FROM matricula WHERE id = :NEW.matricula_id;
    SELECT unidade_curricular_id INTO v_uc_id FROM turma WHERE id = :NEW.turma_id;

    SELECT COUNT(*) INTO v_existe FROM uc_curso 
    WHERE curso_id = v_curso_id AND unidade_curricular_id = v_uc_id;

    IF v_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20013, 'Erro: Esta Unidade Curricular não pertence ao plano de estudos do curso do aluno.');
    END IF;
END;
/

-- -----------------------------------------------------------------------------
-- 5.12. Validação de Criação de Turma
-- Impede a criação de turmas para UCs que não estão em nenhum curso.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_TURMA_UC_VALIDA
BEFORE INSERT OR UPDATE ON turma
FOR EACH ROW
DECLARE
    v_existe NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_existe FROM uc_curso WHERE unidade_curricular_id = :NEW.unidade_curricular_id;
    IF v_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20014, 'Erro: Não é permitido criar turmas para UCs que não pertençam a pelo menos um curso.');
    END IF;
END;
/
