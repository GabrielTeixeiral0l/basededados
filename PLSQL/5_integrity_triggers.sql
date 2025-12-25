-- =============================================================================
-- 5. TRIGGERS DE INTEGRIDADE (SEM RAISE_APPLICATION_ERROR)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 5.1. Validação de Nota
-- RESOLUÇÃO: Ajusta para os limites 0 ou 20.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_NOTA
BEFORE INSERT OR UPDATE ON nota
FOR EACH ROW
DECLARE
    e_nota_invalida EXCEPTION;
BEGIN
    IF :NEW.nota < 0 OR :NEW.nota > 20 THEN
        RAISE e_nota_invalida;
    END IF;
EXCEPTION
    WHEN e_nota_invalida THEN
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Nota ' || :NEW.nota || ' fora do intervalo. A resolver...');
        IF :NEW.nota < 0 THEN :NEW.nota := 0; ELSE :NEW.nota := 20; END IF;
END;
/

-- -----------------------------------------------------------------------------
-- 5.2. Validação de Horário de Aula
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_HORARIO_AULA
BEFORE INSERT OR UPDATE ON aula
FOR EACH ROW
DECLARE
    v_conflito NUMBER;
    v_docente_id NUMBER;
    e_conflito_horario EXCEPTION;
BEGIN
    SELECT docente_id INTO v_docente_id FROM turma WHERE id = :NEW.turma_id;
    SELECT COUNT(*) INTO v_conflito FROM aula a JOIN turma t ON a.turma_id = t.id
    WHERE a.id != NVL(:NEW.id, -1) AND a.data = :NEW.data
      AND ((a.sala_id = :NEW.sala_id) OR (t.docente_id = v_docente_id))
      AND ((:NEW.hora_inicio BETWEEN a.hora_inicio AND a.hora_fim) OR (:NEW.hora_fim BETWEEN a.hora_inicio AND a.hora_fim));

    IF v_conflito > 0 THEN RAISE e_conflito_horario; END IF;
EXCEPTION
    WHEN e_conflito_horario THEN
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Conflito de horário! Aula não deve ser realizada nestas condições.');
        -- Nota: Operação continuará, mas o alerta foi dado.
END;
/

-- -----------------------------------------------------------------------------
-- 5.3. Validação de Data de Entrega
-- RESOLUÇÃO: Ajusta para a data da avaliação.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_DATA_AVALIACAO
BEFORE INSERT OR UPDATE ON avaliacao
FOR EACH ROW
DECLARE
    e_data_invalida EXCEPTION;
BEGIN
    IF :NEW.data_entrega < :NEW.data THEN RAISE e_data_invalida; END IF;
EXCEPTION
    WHEN e_data_invalida THEN
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Data de entrega inválida. A ajustar para data da avaliação.');
        :NEW.data_entrega := :NEW.data;
END;
/

-- -----------------------------------------------------------------------------
-- 5.4. Lotação da Turma
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_TURMA_CAPACIDADE
BEFORE INSERT ON inscricao
FOR EACH ROW
DECLARE
    v_inscritos NUMBER;
    v_capacidade NUMBER;
    e_turma_cheia EXCEPTION;
BEGIN
    SELECT COUNT(*) INTO v_inscritos FROM inscricao WHERE turma_id = :NEW.turma_id AND status = '1';
    SELECT MIN(s.capacidade) INTO v_capacidade FROM aula a JOIN sala s ON a.sala_id = s.id WHERE a.turma_id = :NEW.turma_id;

    IF v_capacidade IS NOT NULL AND v_inscritos >= v_capacidade THEN RAISE e_turma_cheia; END IF;
EXCEPTION
    WHEN e_turma_cheia THEN
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Turma ID ' || :NEW.turma_id || ' cheia. Inscrição realizada sob condição de excesso.');
END;
/

-- -----------------------------------------------------------------------------
-- 5.5. Proteção de Estado de Matrícula
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_MATRICULA_ESTADO
BEFORE UPDATE OF estado_matricula_id ON matricula
FOR EACH ROW
DECLARE
    e_alteracao_proibida EXCEPTION;
BEGIN
    IF :OLD.estado_matricula_id = 3 AND :NEW.estado_matricula_id != 4 THEN RAISE e_alteracao_proibida; END IF;
EXCEPTION
    WHEN e_alteracao_proibida THEN
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Aviso: Alteração de matrícula concluída detetada.');
END;
/

-- -----------------------------------------------------------------------------
-- 5.6. Validação de Pesos de Avaliação
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_PESO_AVALIACAO
FOR INSERT OR UPDATE ON avaliacao
COMPOUND TRIGGER
    v_turma_id NUMBER;
    v_total_peso NUMBER;
    v_novo_peso NUMBER;
    v_id_atual NUMBER;
    e_peso_excedido EXCEPTION;

    BEFORE EACH ROW IS
    BEGIN
        v_turma_id := :NEW.turma_id;
        v_novo_peso := :NEW.peso;
        v_id_atual := :NEW.id;
    END BEFORE EACH ROW;

    AFTER STATEMENT IS
    BEGIN
        IF v_turma_id IS NOT NULL THEN
            SELECT NVL(SUM(peso), 0) INTO v_total_peso FROM avaliacao
            WHERE turma_id = v_turma_id AND id != NVL(v_id_atual, -1) AND status = '1';

            IF (v_total_peso + v_novo_peso) > 100 THEN
                PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Pesos de avaliação para a turma ' || v_turma_id || ' excedem 100%.');
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
    e_presenca_futura EXCEPTION;
BEGIN
    SELECT data INTO v_data_aula FROM aula WHERE id = :NEW.aula_id;
    IF v_data_aula > SYSDATE THEN RAISE e_presenca_futura; END IF;
EXCEPTION
    WHEN e_presenca_futura THEN
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Marcação de presença em aula futura. Verifique os dados.');
END;
/

-- -----------------------------------------------------------------------------
-- 5.8. Bloqueio de Entrega por Dívidas
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_BLOQUEIO_ENTREGA_DIVIDA
BEFORE INSERT ON estudante_entrega
FOR EACH ROW
DECLARE
    v_estudante_id NUMBER;
    v_matricula_id NUMBER;
    e_aluno_devedor EXCEPTION;
BEGIN
    SELECT matricula_id INTO v_matricula_id FROM inscricao WHERE id = :NEW.inscricao_id;
    SELECT estudante_id INTO v_estudante_id FROM matricula WHERE id = v_matricula_id;

    IF FUN_IS_DEVEDOR(v_estudante_id) = 'S' THEN RAISE e_aluno_devedor; END IF;
EXCEPTION
    WHEN e_aluno_devedor THEN
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Estudante ID ' || v_estudante_id || ' submeteu trabalho com propinas em atraso.');
END;
/

-- -----------------------------------------------------------------------------
-- 5.9. Validação de Plano Curricular
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_PLANO_CURRICULAR
BEFORE INSERT ON inscricao
FOR EACH ROW
DECLARE
    v_curso_id NUMBER;
    v_uc_id NUMBER;
    v_existe NUMBER;
    e_plano_invalido EXCEPTION;
BEGIN
    SELECT curso_id INTO v_curso_id FROM matricula WHERE id = :NEW.matricula_id;
    SELECT unidade_curricular_id INTO v_uc_id FROM turma WHERE id = :NEW.turma_id;

    SELECT COUNT(*) INTO v_existe FROM uc_curso 
    WHERE curso_id = v_curso_id AND unidade_curricular_id = v_uc_id;

    IF v_existe = 0 THEN RAISE e_plano_invalido; END IF;
EXCEPTION
    WHEN e_plano_invalido THEN
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Inscrição numa UC fora do plano do curso do aluno.');
END;
/
