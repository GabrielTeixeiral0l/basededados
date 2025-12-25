-- =============================================================================
-- 5. TRIGGERS DE INTEGRIDADE E REGRAS DE NEGÓCIO (CONSOLIDADO)
-- Nota: Uso exclusivo de status='0' e PKG_GESTAO_DADOS.PRC_LOG_ALERTA.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 5.1. Validação de Nota (0-20)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_NOTA
BEFORE INSERT OR UPDATE ON nota
FOR EACH ROW
BEGIN
    IF :NEW.nota < PKG_CONSTANTES.NOTA_MINIMA THEN 
        :NEW.nota := PKG_CONSTANTES.NOTA_MINIMA;
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Nota corrigida para 0.');
    ELSIF :NEW.nota > PKG_CONSTANTES.NOTA_MAXIMA THEN 
        :NEW.nota := PKG_CONSTANTES.NOTA_MAXIMA;
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Nota corrigida para 20.');
    END IF;
END;
/

-- -----------------------------------------------------------------------------
-- 5.2. Conflito de Horário (Sala ou Docente ocupados)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_HORARIO_AULA
BEFORE INSERT OR UPDATE ON aula
FOR EACH ROW
DECLARE
    v_conflito NUMBER;
    v_doc_id NUMBER;
BEGIN
    SELECT docente_id INTO v_doc_id FROM turma WHERE id = :NEW.turma_id;
    SELECT COUNT(*) INTO v_conflito FROM aula a JOIN turma t ON a.turma_id = t.id
    WHERE a.id != NVL(:NEW.id, -1) AND a.data = :NEW.data AND a.status = '1'
      AND ((a.sala_id = :NEW.sala_id) OR (t.docente_id = v_doc_id))
      AND ((:NEW.hora_inicio < a.hora_fim AND :NEW.hora_fim > a.hora_inicio));

    IF v_conflito > 0 THEN 
        :NEW.status := '0';
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Aula invalidada: Conflito de horário (Sala/Docente).');
    END IF;
END;
/

-- -----------------------------------------------------------------------------
-- 5.3. Capacidade da Sala
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_CAPACIDADE_SALA
BEFORE INSERT ON inscricao
FOR EACH ROW
DECLARE
    v_cap NUMBER; v_ins NUMBER;
BEGIN
    SELECT s.capacidade INTO v_cap FROM sala s JOIN aula a ON a.sala_id = s.id 
    WHERE a.turma_id = :NEW.turma_id AND ROWNUM = 1;
    SELECT COUNT(*) INTO v_ins FROM inscricao WHERE turma_id = :NEW.turma_id AND status = '1';
    IF v_ins >= v_cap THEN 
        :NEW.status := '0';
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Inscrição recusada: Turma sem vagas.');
    END IF;
EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
END;
/

-- -----------------------------------------------------------------------------
-- 5.4. Bloqueio por Dívidas
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_DEVEDOR
BEFORE INSERT ON inscricao
FOR EACH ROW
DECLARE v_est_id NUMBER;
BEGIN
    SELECT estudante_id INTO v_est_id FROM matricula WHERE id = :NEW.matricula_id;
    IF FUN_IS_DEVEDOR(v_est_id) = 'S' THEN 
        :NEW.status := '0';
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Inscrição bloqueada: Aluno com dívidas.');
    END IF;
END;
/

-- -----------------------------------------------------------------------------
-- 5.5. Limite ECTS Anual (Configurável por curso em PKG_CONSTANTES)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_LIMITE_ECTS
BEFORE INSERT ON inscricao
FOR EACH ROW
DECLARE
    v_curso_id NUMBER; v_total NUMBER; v_nova NUMBER;
BEGIN
    SELECT curso_id INTO v_curso_id FROM matricula WHERE id = :NEW.matricula_id;
    SELECT NVL(MAX(ects), 0) INTO v_nova FROM uc_curso uc JOIN turma t ON uc.unidade_curricular_id = t.unidade_curricular_id 
    WHERE t.id = :NEW.turma_id AND uc.curso_id = v_curso_id;
    
    SELECT NVL(SUM(uc.ects), 0) INTO v_total FROM inscricao i JOIN turma t ON i.turma_id = t.id 
    JOIN uc_curso uc ON t.unidade_curricular_id = uc.unidade_curricular_id
    WHERE i.matricula_id = :NEW.matricula_id AND uc.curso_id = v_curso_id AND i.status = '1';

    IF (v_total + v_nova) > PKG_CONSTANTES.LIMITE_ECTS_ANUAL(v_curso_id) THEN
        :NEW.status := '0';
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Inscrição bloqueada: Excesso de ECTS.');
    END IF;
END;
/

-- -----------------------------------------------------------------------------
-- 5.6. Agregação de Notas (Cascata Recursiva)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_NOTA_SINALIZA_CALCULO
AFTER INSERT OR UPDATE ON nota FOR EACH ROW
DECLARE v_pai NUMBER;
BEGIN
    PKG_BUFFER_NOTA.ADICIONAR_FINAL(:NEW.inscricao_id);
    SELECT avaliacao_pai_id INTO v_pai FROM avaliacao WHERE id = :NEW.avaliacao_id;
    IF v_pai IS NOT NULL THEN PKG_BUFFER_NOTA.ADICIONAR_PAI(:NEW.inscricao_id, v_pai); END IF;
EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
END;
/

CREATE OR REPLACE TRIGGER TRG_NOTA_EXECUTA_CALCULOS
AFTER INSERT OR UPDATE ON nota
DECLARE v_nota_pai NUMBER; v_pai_do_pai NUMBER; i NUMBER; j NUMBER;
BEGIN
    i := PKG_BUFFER_NOTA.v_lista.FIRST;
    LOOP
        EXIT WHEN i IS NULL;
        SELECT SUM(n.nota * (NVL(a.peso, 0) / 100)) INTO v_nota_pai FROM nota n JOIN avaliacao a ON n.avaliacao_id = a.id
        WHERE n.inscricao_id = PKG_BUFFER_NOTA.v_lista(i).inscricao_id AND a.avaliacao_pai_id = PKG_BUFFER_NOTA.v_lista(i).pai_id AND n.status = '1';
        UPDATE nota SET nota = v_nota_pai, updated_at = SYSDATE WHERE inscricao_id = PKG_BUFFER_NOTA.v_lista(i).inscricao_id AND avaliacao_id = PKG_BUFFER_NOTA.v_lista(i).pai_id;
        IF SQL%ROWCOUNT = 0 THEN INSERT INTO nota (inscricao_id, avaliacao_id, nota, status) VALUES (PKG_BUFFER_NOTA.v_lista(i).inscricao_id, PKG_BUFFER_NOTA.v_lista(i).pai_id, v_nota_pai, '1'); END IF;
        SELECT MAX(avaliacao_pai_id) INTO v_pai_do_pai FROM avaliacao WHERE id = PKG_BUFFER_NOTA.v_lista(i).pai_id;
        IF v_pai_do_pai IS NOT NULL THEN PKG_BUFFER_NOTA.ADICIONAR_PAI(PKG_BUFFER_NOTA.v_lista(i).inscricao_id, v_pai_do_pai); END IF;
        i := PKG_BUFFER_NOTA.v_lista.NEXT(i);
    END LOOP;
    j := PKG_BUFFER_NOTA.v_lista_insc.FIRST;
    LOOP
        EXIT WHEN j IS NULL;
        SELECT SUM(n.nota * (NVL(a.peso, 100) / 100)) INTO v_nota_pai FROM nota n JOIN avaliacao a ON n.avaliacao_id = a.id
        WHERE n.inscricao_id = j AND a.avaliacao_pai_id IS NULL AND n.status = '1';
        UPDATE inscricao SET nota_final = v_nota_pai, updated_at = SYSDATE WHERE id = j;
        j := PKG_BUFFER_NOTA.v_lista_insc.NEXT(j);
    END LOOP;
    PKG_BUFFER_NOTA.LIMPAR;
END;
/

-- -----------------------------------------------------------------------------
-- 5.7. Média Geral e Conclusão de Curso
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_INSCRICAO_POST_PROCESS
AFTER UPDATE OF nota_final ON inscricao FOR EACH ROW
DECLARE v_media NUMBER; v_ects NUMBER; v_cur_id NUMBER; v_total_obr NUMBER; v_aprov NUMBER;
BEGIN
    SELECT curso_id INTO v_cur_id FROM matricula WHERE id = :NEW.matricula_id;
    SELECT SUM(i.nota_final * uc.ects), SUM(uc.ects) INTO v_media, v_ects FROM inscricao i JOIN turma t ON i.turma_id = t.id JOIN uc_curso uc ON (t.unidade_curricular_id = uc.unidade_curricular_id)
    WHERE i.matricula_id = :NEW.matricula_id AND i.nota_final IS NOT NULL AND i.status = '1' AND uc.curso_id = v_cur_id;
    IF v_ects > 0 THEN UPDATE matricula SET media_geral = (v_media / v_ects), updated_at = SYSDATE WHERE id = :NEW.matricula_id; END IF;
    SELECT COUNT(*) INTO v_total_obr FROM uc_curso WHERE curso_id = v_cur_id;
    SELECT COUNT(*) INTO v_aprov FROM inscricao WHERE matricula_id = :NEW.matricula_id AND nota_final >= PKG_CONSTANTES.NOTA_APROVACAO AND status = '1';
    IF v_aprov >= v_total_obr AND v_total_obr > 0 THEN 
        UPDATE matricula SET estado_matricula_id = PKG_CONSTANTES.EST_MATRICULA_CONCLUIDA WHERE id = :NEW.matricula_id;
    END IF;
END;
/

-- -----------------------------------------------------------------------------
-- 5.8. Automação: Presenças ao criar Aula
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_AUTO_PRESENCA_AULA
AFTER INSERT ON aula FOR EACH ROW
BEGIN
    INSERT INTO presenca (inscricao_id, aula_id, presente, status)
    SELECT id, :NEW.id, '0', '1' FROM inscricao WHERE turma_id = :NEW.turma_id AND status = '1';
END;
/

-- -----------------------------------------------------------------------------
-- 5.9. Automação: Presenças ao inscrever Aluno
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_AUTO_PRESENCA_ALUNO
AFTER INSERT ON inscricao FOR EACH ROW
BEGIN
    INSERT INTO presenca (inscricao_id, aula_id, presente, status)
    SELECT :NEW.id, id, '0', '1' FROM aula WHERE turma_id = :NEW.turma_id AND status = '1';
END;
/

-- -----------------------------------------------------------------------------
-- 5.10. Automação: Gerar Propinas ao Matricular
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_AUTO_GERAR_PROPINAS
AFTER INSERT ON matricula FOR EACH ROW
BEGIN
    PKG_TESOURARIA.PRC_GERAR_PLANO_PAGAMENTO(:NEW.id);
END;
/

-- -----------------------------------------------------------------------------
-- 5.11. Propagação de Peso de Avaliação
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_AVAL_RECALCULA_NOTAS
AFTER UPDATE OF peso ON avaliacao FOR EACH ROW
BEGIN
    UPDATE nota SET updated_at = SYSDATE WHERE avaliacao_id = :NEW.id;
END;
/

-- -----------------------------------------------------------------------------
-- 5.12. Tamanho de Grupo
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_TAMANHO_GRUPO
BEFORE INSERT ON estudante_entrega FOR EACH ROW
DECLARE v_max NUMBER; v_at NUMBER;
BEGIN
    SELECT a.max_alunos INTO v_max FROM entrega e JOIN avaliacao a ON e.avaliacao_id = a.id WHERE e.id = :NEW.entrega_id;
    SELECT COUNT(*) INTO v_at FROM estudante_entrega WHERE entrega_id = :NEW.entrega_id AND status = '1';
    IF v_at >= v_max THEN 
        :NEW.status := '0';
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Grupo completo para a entrega ' || :NEW.entrega_id);
    END IF;
END;
/

-- -----------------------------------------------------------------------------
-- 5.13. Conflito de Horário do Aluno
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VAL_CONFLITO_ALUNO
BEFORE INSERT ON inscricao FOR EACH ROW
DECLARE v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM aula a_nova JOIN aula a_ex ON a_nova.data = a_ex.data
    JOIN inscricao i ON i.turma_id = a_ex.turma_id
    WHERE a_nova.turma_id = :NEW.turma_id AND i.matricula_id = :NEW.matricula_id AND i.status = '1'
      AND (a_nova.hora_inicio < a_ex.hora_fim AND a_nova.hora_fim > a_ex.hora_inicio);
    IF v_count > 0 THEN 
        :NEW.status := '0';
        PKG_GESTAO_DADOS.PRC_LOG_ALERTA('Inscrição inválida: Sobreposição de horários para o aluno.');
    END IF;
END;
/
